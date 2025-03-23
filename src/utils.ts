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
