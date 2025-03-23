import * as THREE from "three";

export function lerp(a: number, b: number, t: number): number {
  return (1 - t) * a + t * b;
}

export function rad(degrees: number): number {
  return (degrees * Math.PI) / 180;
}

export function randomSpherePoint(
  pos: THREE.Vector3,
  radius: number,
): THREE.Vector3 {
  var u = Math.random();
  var v = Math.random();
  var theta = 2 * Math.PI * u;
  var phi = Math.acos(2 * v - 1);
  var x = pos.x + radius * Math.sin(phi) * Math.cos(theta);
  var y = pos.y + radius * Math.sin(phi) * Math.sin(theta);
  var z = pos.z + radius * Math.cos(phi);
  return new THREE.Vector3(x, y, z);
}

export class PickHelper {
  raycaster: THREE.Raycaster;
  pickedObject?: THREE.Object3D;

  constructor() {
    this.raycaster = new THREE.Raycaster();
    this.pickedObject = undefined;
    // this.pickedObjectSavedColor = 0;
  }
  pick(
    normalizedPosition: THREE.Vector2,
    scene: THREE.Scene,
    camera: THREE.Camera,
  ) {
    // restore the color if there is a picked object
    if (this.pickedObject) {
      // this.pickedObject.material.emissive.setHex(this.pickedObjectSavedColor);
      this.pickedObject = undefined;
    }

    // cast a ray through the frustum
    this.raycaster.setFromCamera(normalizedPosition, camera);
    // get the list of objects the ray intersected
    const intersectedObjects = this.raycaster.intersectObjects(scene.children);
    return intersectedObjects;
  }
}

//#region oklab interpolation. Generated with AI.
function hexToRgb(hex: number): [number, number, number] {
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
export function interpolateOklab(color1, color2, t) {
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
//#endregion
