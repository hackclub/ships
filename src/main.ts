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

let clicked = false;
window.addEventListener("mousedown", () => (clicked = true));
window.addEventListener("mouseup", () => (clicked = false));

function buildScene() {
  const canvas = document.querySelector("#app > canvas")!;

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

  let selectedPosition;

  const lookTarget = new THREE.Object3D();
  camera.add(lookTarget);

  function render(time: number) {
    time *= 0.001;

    // planet.rotation.y += 0.001;

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
        .pick(pickPosition, scene, camera, time)
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
        up2.multiplyScalar(0.05).add(normal2.multiplyScalar(0.2)),
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
