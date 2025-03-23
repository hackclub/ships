import * as THREE from "three";

const perlin = `
  //	<https://www.shadertoy.com/view/4dS3Wd>
  //	By Morgan McGuire @morgan3d, http://graphicscodex.com
  //
  float hash(float n) { return fract(sin(n) * 1e4); }
  float hash(vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

  float noise(float x) {
	float i = floor(x);
	float f = fract(x);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), u);
  }

  float noise(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);

	// Four corners in 2D of a tile
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	// Simple 2D lerp using smoothstep envelope between the values.
	// return vec3(mix(mix(a, b, smoothstep(0.0, 1.0, f.x)),
	//			mix(c, d, smoothstep(0.0, 1.0, f.x)),
	//			smoothstep(0.0, 1.0, f.y)));

	// Same code, with the clamps in smoothstep and common subexpressions
	// optimized away.
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
  }

  // This one has non-ideal tiling properties that I'm still tuning
  float noise(vec3 x) {
	const vec3 step = vec3(110, 241, 171);

	vec3 i = floor(x);
	vec3 f = fract(x);

	// For performance, compute the base input to a 1D hash from the integer part of the argument and the
	// incremental change to the 1D based on the 3D -> 1D wrapping
      float n = dot(i, step);

	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                     mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
                 mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                     mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
  }

  float fbm(vec3 p) {
      // Parameters for tuning
      const int OCTAVES = 6;
      float lacunarity = 2.0;
      float gain = 0.5;

      // Initial values
      float amplitude = 19.;
      float frequency = 1.0;
      float sum = 0.0;
      float sumAmplitude = 0.0;

      // Sum multiple octaves of noise
      for(int i = 0; i < OCTAVES; i++) {
          // Sample noise at this octave
          float n = noise(p * frequency);

          // Add to sum with current amplitude
          sum += amplitude * n;
          sumAmplitude += amplitude;

          // Increase frequency, decrease amplitude for next octave
          frequency *= lacunarity;
          amplitude *= gain;
      }

      // Normalize
      return sum / sumAmplitude;
  }
  `;

export const vertexShader = `
  ${perlin}

  uniform float planetAmplitude;
  uniform float waterLevel;
  varying vec3 vPosition;
  varying vec3 vNormal;
  varying float vNoise;

  void main() {
      vPosition = position;
      vNormal = normal;
      vNoise = max(waterLevel, fbm(normalize(vPosition)));


      vec3 newPosition = position + normal * (vNoise - 0.5) * planetAmplitude;

      gl_Position = projectionMatrix * modelViewMatrix * vec4(newPosition, 1.0);
  }
`;

export const fragmentShader = `
  ${perlin}

  uniform float waterLevel;
  uniform float time;
  varying vec3 vPosition;
  varying vec3 vNormal;
  varying float vNoise;

  void main() {
      // vec3 p = normalize(vPosition);

      // Use fBm for more detail
      // float noise = fbm(p);

      // Map from [-1,1] to [0,1]
      float r = vNoise;//0.5 + 0.5 * noise;

      vec3 col = r > waterLevel ? vec3(10./255., 236./255., 11./255.) : vec3(11./255., 151./255., 235./255.);

      gl_FragColor = vec4(col, 1.0);
  }
`;

// GPU-based point generation system. I generated this with AI.
export class NoisePointGenerator {
  private renderTarget: THREE.WebGLRenderTarget;
  private camera: THREE.OrthographicCamera;
  private scene: THREE.Scene;
  private pointsMaterial: THREE.ShaderMaterial;
  private pointsMesh: THREE.Mesh;
  private renderer: THREE.WebGLRenderer;
  private resolution = 128; // Texture resolution
  private pixelBuffer: Uint8Array;
  private random: SeededRandom;

  constructor(renderer: THREE.WebGLRenderer) {
    this.renderer = renderer;
    this.pixelBuffer = new Uint8Array(4 * this.resolution * this.resolution);
    this.random = new SeededRandom(12345);

    // Create render target
    this.renderTarget = new THREE.WebGLRenderTarget(
      this.resolution,
      this.resolution,
      {
        format: THREE.RGBAFormat,
        type: THREE.UnsignedByteType,
      },
    );

    // Orthographic camera for rendering to texture
    this.camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);

    // Scene for rendering
    this.scene = new THREE.Scene();

    // Create a shader material that generates points based on the exact same noise function
    this.pointsMaterial = new THREE.ShaderMaterial({
      uniforms: {
        waterLevel: { value: 0.5 },
        planetAmplitude: { value: 0.5 },
      },
      vertexShader: `
        varying vec2 vUv;
        void main() {
          vUv = uv;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        varying vec2 vUv;
        uniform float waterLevel;
        uniform float planetAmplitude;

        ${perlin}

        vec3 spherePoint(vec2 uv) {
          // Convert UV to spherical coordinates
          float phi = uv.x * 2.0 * 3.14159265359;
          float theta = uv.y * 3.14159265359;

          // Convert to Cartesian coordinates on unit sphere
          return vec3(
            sin(theta) * cos(phi),
            sin(theta) * sin(phi),
            cos(theta)
          );
        }

        void main() {
          // Convert UV to point on sphere
          vec3 point = spherePoint(vUv);

          // Calculate noise using the exact same fbm function
          float noiseValue = max(waterLevel, fbm(normalize(point)));

          // Output if this is water (below water level) or not
          float isWater = noiseValue <= waterLevel ? 1.0 : 0.0;

          // Store result (red channel indicates water point)
          gl_FragColor = vec4(isWater, 0.0, 0.0, 1.0);
        }
      `,
    });

    // Create a quad to render our shader
    const geometry = new THREE.PlaneGeometry(2, 2);
    this.pointsMesh = new THREE.Mesh(geometry, this.pointsMaterial);
    this.scene.add(this.pointsMesh);
  }

  setSeed(seed: number): void {
    this.random = new SeededRandom(seed);
  }

  // Generate points on GPU and return water points
  generatePoints(
    waterLevel: number,
    planetAmplitude: number,
    numPoints: number,
  ): THREE.Vector3[] {
    // Update shader uniforms
    this.pointsMaterial.uniforms.waterLevel.value = waterLevel;
    this.pointsMaterial.uniforms.planetAmplitude.value = planetAmplitude;

    // Render to texture
    const currentRenderTarget = this.renderer.getRenderTarget();
    this.renderer.setRenderTarget(this.renderTarget);
    this.renderer.render(this.scene, this.camera);

    // Read pixel data from GPU
    this.renderer.readRenderTargetPixels(
      this.renderTarget,
      0,
      0,
      this.resolution,
      this.resolution,
      this.pixelBuffer,
    );

    // Restore the original render target
    this.renderer.setRenderTarget(currentRenderTarget);

    // Generate points from the texture data
    const points: THREE.Vector3[] = [];
    const waterPoints: THREE.Vector3[] = [];

    // Generate random points and check texture to see if they're in water
    for (let i = 0; i < numPoints; i++) {
      // Generate random spherical coordinates
      const phi = this.random.next() * Math.PI * 2;
      const theta = Math.acos(2 * this.random.next() - 1);

      // Convert to 3D point on unit sphere
      const point = new THREE.Vector3(
        Math.sin(theta) * Math.cos(phi),
        Math.sin(theta) * Math.sin(phi),
        Math.cos(theta),
      );

      // Convert to UV coordinates
      const u = phi / (Math.PI * 2);
      const v = theta / Math.PI;

      // Sample texture at this point
      const x = Math.floor(u * this.resolution);
      const y = Math.floor(v * this.resolution);
      const index = (y * this.resolution + x) * 4;

      // If red channel > 0, this is a water point
      if (this.pixelBuffer[index] > 0) {
        waterPoints.push(point);
      }

      if (waterPoints.length >= numPoints / 10) break; // Limit to roughly 10% of points
    }

    return waterPoints;
  }
}

class SeededRandom {
  private seed: number;

  constructor(seed: number = 12345) {
    this.seed = seed >>> 0;
  }

  // Get next random value (0 to 1)
  next(): number {
    this.seed = (this.seed + 0x6d2b79f5) | 0;
    let t = Math.imul(this.seed ^ (this.seed >>> 15), 1 | this.seed);
    t = Math.imul(t ^ (t >>> 7), 61 | t) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }
}
