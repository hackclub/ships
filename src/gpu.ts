import * as THREE from "three";

const water = `
  // "Wind Waker Ocean" by @Polyflare (29/1/15)
  // License: Creative Commons Attribution 4.0 International
  // Modified for flat texture mapping on a sphere

  //-----------------------------------------------------------------------------
  // User settings

  // 0 = Do not distort the water texture
  // 1 = Apply lateral distortion to the water texture
#define DISTORT_WATER 1

  // 0 = Antialias the water texture
  // 1 = Do not antialias the water texture
#define FAST_CIRCLES 1

  //-----------------------------------------------------------------------------

#define WATER_COL vec3(0.0, 0.4453, 0.7305)
#define WATER2_COL vec3(0.0, 0.4180, 0.6758)
#define FOAM_COL vec3(0.8125, 0.9609, 0.9648)

#define M_2PI 6.283185307
#define M_6PI 18.84955592

  float circ(vec2 pos, vec2 c, float s) {
      c = abs(pos - c);
      c = min(c, 1.0 - c);
#if FAST_CIRCLES
      return dot(c, c) < s ? -1.0 : 0.0;
#else
      return smoothstep(0.0, 0.002, sqrt(s) - sqrt(dot(c, c))) * -1.0;
#endif
  }

  // Foam pattern for the water constructed out of a series of circles
  float waterlayer(vec2 uv)
  {
      uv = mod(uv, 1.0); // Clamp to [0..1]
      float ret = 1.0;
      ret += circ(uv, vec2(0.37378, 0.277169), 0.0268181);
      ret += circ(uv, vec2(0.0317477, 0.540372), 0.0193742);
      ret += circ(uv, vec2(0.430044, 0.882218), 0.0232337);
      ret += circ(uv, vec2(0.641033, 0.695106), 0.0117864);
      ret += circ(uv, vec2(0.0146398, 0.0791346), 0.0299458);
      ret += circ(uv, vec2(0.43871, 0.394445), 0.0289087);
      ret += circ(uv, vec2(0.909446, 0.878141), 0.028466);
      ret += circ(uv, vec2(0.310149, 0.686637), 0.0128496);
      ret += circ(uv, vec2(0.928617, 0.195986), 0.0152041);
      ret += circ(uv, vec2(0.0438506, 0.868153), 0.0268601);
      ret += circ(uv, vec2(0.308619, 0.194937), 0.00806102);
      ret += circ(uv, vec2(0.349922, 0.449714), 0.00928667);
      ret += circ(uv, vec2(0.0449556, 0.953415), 0.023126);
      ret += circ(uv, vec2(0.117761, 0.503309), 0.0151272);
      ret += circ(uv, vec2(0.563517, 0.244991), 0.0292322);
      ret += circ(uv, vec2(0.566936, 0.954457), 0.00981141);
      ret += circ(uv, vec2(0.0489944, 0.200931), 0.0178746);
      ret += circ(uv, vec2(0.569297, 0.624893), 0.0132408);
      ret += circ(uv, vec2(0.298347, 0.710972), 0.0114426);
      ret += circ(uv, vec2(0.878141, 0.771279), 0.00322719);
      ret += circ(uv, vec2(0.150995, 0.376221), 0.00216157);
      ret += circ(uv, vec2(0.119673, 0.541984), 0.0124621);
      ret += circ(uv, vec2(0.629598, 0.295629), 0.0198736);
      ret += circ(uv, vec2(0.334357, 0.266278), 0.0187145);
      ret += circ(uv, vec2(0.918044, 0.968163), 0.0182928);
      ret += circ(uv, vec2(0.965445, 0.505026), 0.006348);
      ret += circ(uv, vec2(0.514847, 0.865444), 0.00623523);
      ret += circ(uv, vec2(0.710575, 0.0415131), 0.00322689);
      ret += circ(uv, vec2(0.71403, 0.576945), 0.0215641);
      ret += circ(uv, vec2(0.748873, 0.413325), 0.0110795);
      ret += circ(uv, vec2(0.0623365, 0.896713), 0.0236203);
      ret += circ(uv, vec2(0.980482, 0.473849), 0.00573439);
      ret += circ(uv, vec2(0.647463, 0.654349), 0.0188713);
      ret += circ(uv, vec2(0.651406, 0.981297), 0.00710875);
      ret += circ(uv, vec2(0.428928, 0.382426), 0.0298806);
      ret += circ(uv, vec2(0.811545, 0.62568), 0.00265539);
      ret += circ(uv, vec2(0.400787, 0.74162), 0.00486609);
      ret += circ(uv, vec2(0.331283, 0.418536), 0.00598028);
      ret += circ(uv, vec2(0.894762, 0.0657997), 0.00760375);
      ret += circ(uv, vec2(0.525104, 0.572233), 0.0141796);
      ret += circ(uv, vec2(0.431526, 0.911372), 0.0213234);
      ret += circ(uv, vec2(0.658212, 0.910553), 0.000741023);
      ret += circ(uv, vec2(0.514523, 0.243263), 0.0270685);
      ret += circ(uv, vec2(0.0249494, 0.252872), 0.00876653);
      ret += circ(uv, vec2(0.502214, 0.47269), 0.0234534);
      ret += circ(uv, vec2(0.693271, 0.431469), 0.0246533);
      ret += circ(uv, vec2(0.415, 0.884418), 0.0271696);
      ret += circ(uv, vec2(0.149073, 0.41204), 0.00497198);
      ret += circ(uv, vec2(0.533816, 0.897634), 0.00650833);
      ret += circ(uv, vec2(0.0409132, 0.83406), 0.0191398);
      ret += circ(uv, vec2(0.638585, 0.646019), 0.0206129);
      ret += circ(uv, vec2(0.660342, 0.966541), 0.0053511);
      ret += circ(uv, vec2(0.513783, 0.142233), 0.00471653);
      ret += circ(uv, vec2(0.124305, 0.644263), 0.00116724);
      ret += circ(uv, vec2(0.99871, 0.583864), 0.0107329);
      ret += circ(uv, vec2(0.894879, 0.233289), 0.00667092);
      ret += circ(uv, vec2(0.246286, 0.682766), 0.00411623);
      ret += circ(uv, vec2(0.0761895, 0.16327), 0.0145935);
      ret += circ(uv, vec2(0.949386, 0.802936), 0.0100873);
      ret += circ(uv, vec2(0.480122, 0.196554), 0.0110185);
      ret += circ(uv, vec2(0.896854, 0.803707), 0.013969);
      ret += circ(uv, vec2(0.292865, 0.762973), 0.00566413);
      ret += circ(uv, vec2(0.0995585, 0.117457), 0.00869407);
      ret += circ(uv, vec2(0.377713, 0.00335442), 0.0063147);
      ret += circ(uv, vec2(0.506365, 0.531118), 0.0144016);
      ret += circ(uv, vec2(0.408806, 0.894771), 0.0243923);
      ret += circ(uv, vec2(0.143579, 0.85138), 0.00418529);
      ret += circ(uv, vec2(0.0902811, 0.181775), 0.0108896);
      ret += circ(uv, vec2(0.780695, 0.394644), 0.00475475);
      ret += circ(uv, vec2(0.298036, 0.625531), 0.00325285);
      ret += circ(uv, vec2(0.218423, 0.714537), 0.00157212);
      ret += circ(uv, vec2(0.658836, 0.159556), 0.00225897);
      ret += circ(uv, vec2(0.987324, 0.146545), 0.0288391);
      ret += circ(uv, vec2(0.222646, 0.251694), 0.00092276);
      ret += circ(uv, vec2(0.159826, 0.528063), 0.00605293);
      return max(ret, 0.0);
  }

  // Procedural texture generation for the water
  vec3 water(vec2 uv)
  {
      uv *= vec2(200); // Scale factor - adjust this for pattern density on sphere

#if DISTORT_WATER
      // Texture distortion
      float d1 = mod(uv.x + uv.y, M_2PI);
      float d2 = mod((uv.x + uv.y + 0.25) * 1.3, M_6PI);
      d1 = time / 200. * 0.07 + d1;
      d2 = time / 200. * 0.5 + d2;
      vec2 dist = vec2(
          sin(d1) * 0.15 + sin(d2) * 0.05,
          cos(d1) * 0.15 + cos(d2) * 0.05
      );
#else
      const vec2 dist = vec2(0.0);
#endif

      vec3 ret = mix(WATER_COL, WATER2_COL, waterlayer(uv + dist.xy));
      ret = mix(ret, FOAM_COL, waterlayer(vec2(1.0) - uv - dist.yx));
      return ret;
  }
  `;

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

      vec3 newPosition = position + normal * (vNoise - .65) * planetAmplitude;

      gl_Position = projectionMatrix * modelViewMatrix * vec4(newPosition, 1.0);
  }
`;

export const fragmentShader = `
  uniform float waterLevel;
  uniform float time;
  uniform float scrollPos;
  varying vec3 vPosition;
  varying vec3 vNormal;
  varying float vNoise;

${perlin}
${water}

  void main() {
      vec3 p = normalize(vPosition);

      // Use fBm for more detail
      // float noise = fbm(p);

      vec2 uv = vec2(
        0.5 + atan(vPosition.z, vPosition.x) / (2.0 * 3.14159265359),
        0.5 + asin(vPosition.y) / 3.14159265359
      );

      // Map from [-1,1] to [0,1]
      float r = vNoise;//0.5 + 0.5 * noise;

      vec3 basicWaterCol = vec3(11./255., 151./255.,  235./255.) + (fbm(p * 1.1) - 0.5);
      vec3 waterCol = mix(basicWaterCol, water(uv), scrollPos);
      vec3 col = r <= waterLevel ? waterCol :
                 r <=waterLevel + 0.001 ? waterCol * 1.5 :
                 r <=0.67 ? vec3(10./255., 236./255., 11./255.) + (fbm(p * 7.) - 0.5) :
                 r <=0.72 ? vec3(105./255., 52./255., 34./255.)  + (fbm(p * 2.) - 0.5) :
                 r <= 0.76 ? vec3(135./255., 135./255., 135./255.)  + (fbm(p * 4.) - 0.5):
                 vec3(1., 1., 1.);

      gl_FragColor = vec4(col, 1.0);
  }
`;

export const vertexIdentityShader = `
  varying vec3 vPosition;
  varying vec3 vNormals;

  void main() {
      // Transform position to world space
      vPosition = (modelMatrix * vec4(position, 1.0)).xyz;

      // Transform normals to world space with proper normal matrix
      vNormals = normalize(normalMatrix * normal);

      // Standard position transformation
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
  `;
export const fragmentAtmosphereShader = `
  varying vec3 vPosition;
  varying vec3 vNormals;
  uniform vec3 uCameraPos;
  uniform float scrollPos;

  void main() {
    vec3 baseColor = vec3(mix(0.325, 0.761, scrollPos), mix(0.541, 0.863, scrollPos), mix(0.776, 0.922, scrollPos));
    // vec3 baseColor = vec3(0.325, 0.541, 0.776);

    // gl_FragColor = vec4(baseColor, 1.);

    // float fadeThreshold = mix(0.00000001, .2, scrollPos);
    // float alphaFallOff = mix(2., 1.6, scrollPos);
    // if (vPosition.z > fadeThreshold) {
    //   gl_FragColor.a = 1.0 + (fadeThreshold - vPosition.z ) * alphaFallOff;
    // }

    vec3 viewDir = normalize(uCameraPos - vPosition);
    vec3 normal = normalize(vNormals);
    // float d = pow(dot(normal, viewDir), 2.);
    // float d = pow(1. - max(dot(normal, viewDir), 0.), 5.);

    // vec3 c = vec3(1., 0., 0.); //normal * 0.5 + 0.5;
    // gl_FragColor = vec4(c, d);



    vec3 toCenter = normalize(-vPosition); // Direction from surface to planet center

      // Calculate atmosphere based on angle between view dir and ray from center through point
      float viewAngle = 1. - dot(viewDir, toCenter) * 3.5;

      // Remap for consistent atmosphere (stronger at limb/horizon, weaker at center)
      float atmosphere = 1.0 - (viewAngle * 0.5 + 0.5);
      atmosphere = pow(atmosphere, 3.5); // Adjust power to control falloff

      float distToCamera = length(uCameraPos - vPosition);

      // Apply distance-based cutoff (adjust these values to fit your scale)
      float planetRadius = length(vPosition); // Assuming sphere is at origin
      float minDistance = planetRadius * 0.17; // Adjust this factor as needed
      float fadeRange = planetRadius * 0.3;   // Distance over which to fade

      // Fade out atmosphere when too close to surface
      if (distToCamera < minDistance + fadeRange) {
        atmosphere *= max(0.0, (distToCamera - minDistance) / fadeRange);
      }

      gl_FragColor = vec4(baseColor, atmosphere * 15.0);
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
