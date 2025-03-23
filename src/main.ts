import "./style.css";
import * as THREE from "three";
import * as Utils from "./utils";

function hexToRgb(hex) {
  const r = ((hex >> 16) & 255) / 255;
  const g = ((hex >> 8) & 255) / 255;
  const b = (hex & 255) / 255;
  return [r, g, b];
}

// Convert sRGB to linear RGB
function sRgbToLinear(c) {
  return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

// Convert linear RGB to OKLab
function linearRgbToOklab(r, g, b) {
  // Linear RGB to XYZ
  const l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b;
  const m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b;
  const s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b;

  // XYZ to OKLab
  const l_ = Math.cbrt(l);
  const m_ = Math.cbrt(m);
  const s_ = Math.cbrt(s);

  return [
    0.2104542553 * l_ + 0.793617785 * m_ - 0.0040720468 * s_,
    1.9779984951 * l_ - 2.428592205 * m_ + 0.4505937099 * s_,
    0.0259040371 * l_ + 0.7827717662 * m_ - 0.808675766 * s_,
  ];
}

// Convert OKLab to linear RGB
function oklabToLinearRgb(L, a, b) {
  const l_ = L + 0.3963377774 * a + 0.2158037573 * b;
  const m_ = L - 0.1055613458 * a - 0.0638541728 * b;
  const s_ = L - 0.0894841775 * a - 1.291485548 * b;

  const l = l_ * l_ * l_;
  const m = m_ * m_ * m_;
  const s = s_ * s_ * s_;

  return [
    +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s,
  ];
}

// Convert linear RGB to sRGB
function linearToSrgb(c) {
  return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
}

// Convert RGB to hex
function rgbToHex(r, g, b) {
  r = Math.max(0, Math.min(1, r));
  g = Math.max(0, Math.min(1, g));
  b = Math.max(0, Math.min(1, b));

  const ri = Math.round(r * 255);
  const gi = Math.round(g * 255);
  const bi = Math.round(b * 255);

  return (ri << 16) | (gi << 8) | bi;
}

// Main interpolation function
function interpolateOklab(color1, color2, t) {
  // Convert hex to OKLab
  const [r1, g1, b1] = hexToRgb(color1);
  const [r2, g2, b2] = hexToRgb(color2);

  const oklab1 = linearRgbToOklab(
    sRgbToLinear(r1),
    sRgbToLinear(g1),
    sRgbToLinear(b1),
  );

  const oklab2 = linearRgbToOklab(
    sRgbToLinear(r2),
    sRgbToLinear(g2),
    sRgbToLinear(b2),
  );

  // Interpolate in OKLab space
  const L = oklab1[0] * (1 - t) + oklab2[0] * t;
  const a = oklab1[1] * (1 - t) + oklab2[1] * t;
  const b = oklab1[2] * (1 - t) + oklab2[2] * t;

  // Convert back to RGB
  const [lr, lg, lb] = oklabToLinearRgb(L, a, b);
  const r = linearToSrgb(lr);
  const g = linearToSrgb(lg);
  const b_srgb = linearToSrgb(lb);

  return rgbToHex(r, g, b_srgb);
}

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

const vertexShader = `
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

const fragmentShader = `
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

document.addEventListener("DOMContentLoaded", buildScene);

let scrollPos = 0;
window.addEventListener("wheel", (e) => {
  scrollPos += e.deltaY / 1_000;
  scrollPos = Math.max(0, Math.min(1, scrollPos));
  console.log(scrollPos);
});

// let clicked = false;
// window.addEventListener("mousedown", () => (clicked = true));
// window.addEventListener("mouseup", () => (clicked = false));

function buildScene() {
  const canvas = document.querySelector("#app > canvas") as HTMLCanvasElement;
  const planetAmplitudeElement = document.getElementById(
    "planetAmplitude",
  ) as HTMLInputElement;
  const waterLevelElement = document.getElementById(
    "waterLevel",
  ) as HTMLInputElement;
  const planetAmplitude = () => Number(planetAmplitudeElement.value) / 100;
  const waterLevel = () => Number(waterLevelElement.value) / 100;

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.001,
    1000,
  );

  const renderer = new THREE.WebGLRenderer({
    canvas,
    alpha: true,
    // antialias: true,
  });
  renderer.setClearColor(0xffffff, 0);
  renderer.setSize(window.innerWidth, window.innerHeight);

  const geometry = new THREE.IcosahedronGeometry(1, 10);
  // const material = new THREE.MeshBasicMaterial({ color:  });
  const material = new THREE.ShaderMaterial({
    uniforms: {
      time: { value: 1.0 },
      resolution: { value: new THREE.Vector2() },
      waterLevel: { value: 0.5 },
      planetAmplitude: { value: 0.5 },
    },
    vertexShader,
    fragmentShader,
  });
  const sphere = new THREE.Mesh(geometry, material);

  const planet = new THREE.Group();
  planet.add(sphere);
  planet.rotation.z = Utils.rad(23.5);
  scene.add(planet);
  // planet.add(camera);

  camera.position.z = 2;

  const poss = [];
  for (let i = 0; i < 10_000; i++) {
    const p = Utils.randomSpherePoint(new THREE.Vector3(), 1).multiplyScalar(
      1000,
    );
    poss.push(...p.toArray());
  }
  const posss = new Float32Array(poss);
  console.log("generated points");

  var dotGeometry = new THREE.BufferGeometry();
  dotGeometry.setAttribute("position", new THREE.BufferAttribute(posss, 3));
  var dotMaterial = new THREE.PointsMaterial({
    size: 2,
    sizeAttenuation: false,
    color: new THREE.Color(0xffffff),
    opacity: 0.5,
    transparent: true,
  });
  var dot = new THREE.Points(dotGeometry, dotMaterial);
  dot.userData.ignore = true;
  scene.add(dot);

  function getCanvasRelativePosition(event: MouseEvent) {
    const rect = canvas.getBoundingClientRect();
    return {
      x: ((event.clientX - rect.left) * canvas.width) / rect.width,
      y: ((event.clientY - rect.top) * canvas.height) / rect.height,
    };
  }

  const pickPosition = new THREE.Vector2();
  clearPickPosition();

  function setPickPosition(event: MouseEvent) {
    const pos = getCanvasRelativePosition(event);
    pickPosition.x = (pos.x / canvas.width) * 2 - 1;
    pickPosition.y = (pos.y / canvas.height) * -2 + 1; // note we flip Y
  }

  function clearPickPosition() {
    // unlike the mouse which always has a position
    // if the user stops touching the screen we want
    // to stop picking. For now we just pick a value
    // unlikely to pick something
    pickPosition.x = -100000;
    pickPosition.y = -100000;
  }

  window.addEventListener("mousemove", setPickPosition);
  window.addEventListener("mouseout", clearPickPosition);
  window.addEventListener("mouseleave", clearPickPosition);

  const pickHelper = new Utils.PickHelper();

  const sa = new THREE.PlaneGeometry(0.2, 0.2);
  const sm = new THREE.MeshBasicMaterial({
    color: 0x0000ff,
    opacity: 0.5,
    transparent: true,
  });
  const s = new THREE.Mesh(sa, sm);
  const s2 = new THREE.Mesh(
    sa,
    new THREE.MeshBasicMaterial({
      color: 0x00ff00,
      opacity: 0.5,
      transparent: true,
    }),
  );
  s.userData.ignore = true;
  s2.userData.ignore = true;
  scene.add(s);
  scene.add(s2);

  let selectedPosition: THREE.Vector3;

  const lookTarget = new THREE.Object3D();
  camera.add(lookTarget);

  function render(time: number) {
    time *= 0.00000001;

    renderer.setClearColor(interpolateOklab(0x000022, 0x87ceeb, scrollPos), 1);
    dot.material.opacity = Utils.lerp(0.5, 0, scrollPos);

    material.uniforms.time.value = time;
    material.uniforms.waterLevel.value = waterLevel();
    material.uniforms.planetAmplitude.value = planetAmplitude();

    planet.rotation.y += scrollPos === 0 ? 0.001 : 0;

    if (selectedPosition) {
      const cp = new THREE.Vector3(0, 0, 2).lerp(s2.position, scrollPos);
      camera.position.copy(cp);

      lookTarget.lookAt(selectedPosition);

      camera.quaternion.slerpQuaternions(
        new THREE.Quaternion(),
        s2.quaternion,
        scrollPos,
      );
    }

    if (scrollPos <= 0) {
      const objects = pickHelper
        .pick(pickPosition, scene, camera)
        .filter((o) => o.object.userData.ignore !== true);
      const p = objects?.[0]?.point || new THREE.Vector3();
      s.position.set(p.x, p.y, p.z);
      s2.position.set(p.x, p.y, p.z);

      // Create quaternion
      const normal = p.clone().normalize();
      const up = new THREE.Vector3(0, 1, 0);

      // Create rotation matrix from orthogonal vectors
      const right = new THREE.Vector3().crossVectors(up, normal).normalize();
      const adjustedUp = new THREE.Vector3()
        .crossVectors(normal, right)
        .normalize();

      const rotMatrix = new THREE.Matrix4().makeBasis(
        right,
        adjustedUp,
        normal,
      );

      // Set quaternion from rotation matrix
      s.quaternion.setFromRotationMatrix(rotMatrix);

      // Then, a q that is perp to the tangent and the angle bisecting s and camera.pos
      const toCamera = new THREE.Vector3()
        .subVectors(camera.position, p)
        .normalize();

      // Project toCamera onto the tangent plane of the surface
      const projectedToCamera = new THREE.Vector3()
        .copy(toCamera)
        .sub(normal.clone().multiplyScalar(toCamera.dot(normal)))
        .normalize();

      // This will be s2's normal (pointing toward camera but in tangent plane)
      const normal2 = projectedToCamera;

      // s2's up direction is the normal of s (perpendicular to s's surface)
      const up2 = normal.clone();

      // Complete the basis with right2
      const right2 = new THREE.Vector3().crossVectors(up2, normal2).normalize();

      // Construct the rotation matrix and set the quaternion
      const rotMatrix2 = new THREE.Matrix4().makeBasis(right2, up2, normal2);
      s2.quaternion.setFromRotationMatrix(rotMatrix2);

      s2.position.add(
        up2
          .multiplyScalar(planetAmplitude() / 5)
          .add(normal2.multiplyScalar(0.2)),
      );

      selectedPosition = p;
    }

    // if (scrollPos <= 0 && clicked) {
    //   // Calculate angle tangent to planet at point p
    //   // Step 1: Draw line between point and planet origin
    //   // console.log(p.normalize());
    //   // camera.rotation.setFromVector3(
    //   //   new THREE.Vector3(0, 0, 0).lerp(upDir, scrollPos),
    //   // );
    // }

    renderer.render(scene, camera);
  }
  renderer.setAnimationLoop(render);
}
