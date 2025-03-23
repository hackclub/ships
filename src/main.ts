import "./style.css";
import * as THREE from "three";
import * as Utils from "./utils";

document.addEventListener("DOMContentLoaded", buildScene);

let scrollPos = 0;
window.addEventListener("wheel", (e) => {
  scrollPos += e.deltaY / 250;
  scrollPos = Math.max(0, Math.min(1, scrollPos));
  console.log(scrollPos);
});

function buildScene() {
  const canvas = document.querySelector("#app > canvas")!;

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000,
  );

  const renderer = new THREE.WebGLRenderer({
    canvas,
    alpha: true,
    // antialias: true,
  });
  renderer.setClearColor(0x000, 0);
  renderer.setSize(window.innerWidth, window.innerHeight);

  const geometry = new THREE.IcosahedronGeometry(1, 10);
  const material = new THREE.MeshNormalMaterial();
  const sphere = new THREE.Mesh(geometry, material);

  const planet = new THREE.Group();
  planet.add(sphere);
  // planet.rotation.z = Utils.rad(23.5);
  scene.add(planet);

  camera.position.z = 2;

  const poss = [];
  for (let i = 0; i < 10_000; i++) {
    const p = Utils.randomSpherePoint(new THREE.Vector3(), 1);
    poss.push(...p.toArray());
  }
  const posss = new Float32Array(poss);
  console.log("generated points");

  var dotGeometry = new THREE.BufferGeometry();
  dotGeometry.setAttribute("position", new THREE.BufferAttribute(posss, 3));
  var dotMaterial = new THREE.PointsMaterial({
    size: 10,
    sizeAttenuation: false,
    color: new THREE.Color(0xff0000),
  });
  var dot = new THREE.Points(dotGeometry, dotMaterial);
  dot.userData.ignore = true;
  planet.add(dot);

  function getCanvasRelativePosition(event) {
    const rect = canvas.getBoundingClientRect();
    return {
      x: ((event.clientX - rect.left) * canvas.width) / rect.width,
      y: ((event.clientY - rect.top) * canvas.height) / rect.height,
    };
  }

  const pickPosition = new THREE.Vector2();
  clearPickPosition();

  function setPickPosition(event) {
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

  const sa = new THREE.SphereGeometry(0.05);
  const sm = new THREE.MeshNormalMaterial();
  const s = new THREE.Mesh(sa, sm);
  s.userData.ignore = true;
  scene.add(s);

  let selectedPosition;
  let quaternion = new THREE.Quaternion();

  function render(time: number) {
    time *= 0.001;

    planet.rotation.y += 0.001;

    if (selectedPosition) {
      const cp = new THREE.Vector3(0, 0, 2).lerp(selectedPosition, scrollPos);
      camera.position.copy(cp);
    }

    const objects = pickHelper
      .pick(pickPosition, scene, camera, time)
      .filter((o) => o.object.userData.ignore !== true);
    const p = objects?.[0]?.point || new THREE.Vector3();
    s.position.set(p.x, p.y, p.z);

    if (scrollPos <= 0.2 && p.x !== 0) {
      selectedPosition = p;

      // Calculate angle tangent to planet at point p
      // Step 1: Draw line between point and planet origin
      const upDir = planet.position.clone().sub(p).normalize();
      console.log(p.normalize());
      // camera.rotation.setFromVector3(
      //   new THREE.Vector3(0, 0, 0).lerp(upDir, scrollPos),
      // );
    }

    renderer.render(scene, camera);
  }
  renderer.setAnimationLoop(render);
}

function alignCameraWithPlanetSurface(camera, planet) {
  // Get direction from planet center to camera (this becomes our "up" vector)
  const upDirection = camera.position.clone().sub(planet.position).normalize();

  // Set camera's up vector to point away from planet center
  camera.up.copy(upDirection);

  // Find a tangent direction (perpendicular to up vector)
  const worldUp = new THREE.Vector3(0, 1, 0);
  let tangentDirection;

  // Avoid parallel vectors issue
  if (Math.abs(upDirection.dot(worldUp)) > 0.9) {
    tangentDirection = new THREE.Vector3()
      .crossVectors(upDirection, new THREE.Vector3(1, 0, 0))
      .normalize();
  } else {
    tangentDirection = new THREE.Vector3()
      .crossVectors(upDirection, worldUp)
      .normalize();
  }

  // Calculate forward direction (perpendicular to both up and tangent)
  const forwardDirection = new THREE.Vector3()
    .crossVectors(tangentDirection, upDirection)
    .normalize();

  // Create target point slightly ahead of camera
  const targetPoint = camera.position.clone().add(forwardDirection);

  // Orient the camera to look at this point
  camera.lookAt(targetPoint);
}
