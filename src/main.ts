import "./style.css";
import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import Stats from "three/addons/libs/stats.module.js";
import { MeshLine, MeshLineMaterial, MeshLineRaycast } from "three.meshline";
import * as Utils from "./utils";
import { fragmentShader, vertexShader, NoisePointGenerator } from "./gpu";

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
  const stats = new Stats();
  document.body.appendChild(stats.dom);

  const shipCount = 10_000;
  let ships: THREE.InstancedMesh;

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

  const geometry = new THREE.IcosahedronGeometry(1, 50);
  // const material = new THREE.MeshBasicMaterial({ color:  });
  const material = new THREE.ShaderMaterial({
    uniforms: {
      time: { value: 1.0 },
      resolution: { value: new THREE.Vector2() },
      waterLevel: { value: 0.5 },
      planetAmplitude: { value: 0.5 },
      scrollPos: { value: scrollPos },
    },
    vertexShader,
    fragmentShader,
  });
  const sphere = new THREE.Mesh(geometry, material);
  sphere.userData.isPlanet = true;

  const planet = new THREE.Group();
  planet.add(sphere);
  planet.rotation.z = Utils.rad(23.5);
  camera.position.z = 2;
  scene.add(planet);

  const gltfLoader = new GLTFLoader();

  gltfLoader.load(
    "public/ship_lod0.gltf",
    (gltf) => {
      const shipGeometry = (gltf.scene.children[0] as THREE.Mesh).geometry;
      const shipScale = 0.01;
      shipGeometry.scale(shipScale, shipScale, shipScale);
      // shipGeometry.rotateX(Utils.rad(90));
      const shipMaterial = new THREE.MeshNormalMaterial();
      ships = new THREE.InstancedMesh(shipGeometry, shipMaterial, shipCount);
      ships.instanceMatrix.setUsage(THREE.DynamicDrawUsage);

      const noiseGenerator = new NoisePointGenerator(renderer);
      let dummyShipTransform = new THREE.Object3D();

      const genShips = () => {
        if (ships) planet.remove(ships);
        const waterPoints = noiseGenerator.generatePoints(
          waterLevel(),
          planetAmplitude(),
          shipCount,
        );

        for (let i = 0; i < waterPoints.length; i++) {
          const x = waterPoints[i].x;
          const y = waterPoints[i].y;
          const z = waterPoints[i].z;
          dummyShipTransform.position.set(x, y, z);

          // Create quaternion
          const normal = new THREE.Vector3(x, y, z).normalize();
          const up = new THREE.Vector3(0, 1, 0);

          // Create rotation matrix from orthogonal vectors
          const right = new THREE.Vector3()
            .crossVectors(up, normal)
            .normalize();
          const adjustedUp = new THREE.Vector3()
            .crossVectors(normal, right)
            .normalize();

          const rotMatrix = new THREE.Matrix4().makeBasis(
            right,
            adjustedUp,
            normal,
          );

          // Set quaternion from rotation matrix
          dummyShipTransform.quaternion.setFromRotationMatrix(rotMatrix);
          dummyShipTransform.rotateX(Utils.rad(90));

          dummyShipTransform.updateMatrix();
          ships.setMatrixAt(i, dummyShipTransform.matrix);
        }
        planet.add(ships);
      };
      genShips();
      waterLevelElement.oninput = genShips;

      //#region Ships
      // let ships: any;
      // // In your buildScene function:
      //

      // const genShips = () => {
      //   if (ships) planet.remove(ships);

      //   // Use the GPU to generate points
      //   const waterPoints = noiseGenerator.generatePoints(
      //     waterLevel(),
      //     planetAmplitude(),
      //     100000,
      //   );
      //   console.log({ waterPoints });

      //   // Convert to buffer geometry
      //   const shipPositions = new Float32Array(waterPoints.length * 3);
      //   for (let i = 0; i < waterPoints.length; i++) {
      //     shipPositions[i * 3] = waterPoints[i].x;
      //     shipPositions[i * 3 + 1] = waterPoints[i].y;
      //     shipPositions[i * 3 + 2] = waterPoints[i].z;
      //   }

      //   var shipsGeometry = new THREE.BufferGeometry();
      //   shipsGeometry.setAttribute(
      //     "position",
      //     new THREE.BufferAttribute(shipPositions, 3),
      //   );
      //   var shipsMaterial = new THREE.PointsMaterial({
      //     size: 10,
      //     sizeAttenuation: false,
      //     color: new THREE.Color(0xff0000),
      //   });
      //   ships = new THREE.Points(shipsGeometry, shipsMaterial);
      //   ships.userData.ignore = true;
      //   planet.add(ships);
      // };
      // genShips();
      //
      //#endregion
    },
    // called while loading is progressing
    function (xhr) {
      console.log((xhr.loaded / xhr.total) * 100 + "% loaded");
    },
    // called when loading has errors
    function (error) {
      console.log("An error happened");
    },
  );

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

  // const sa = new THREE.PlaneGeometry(0.05, 0.05);
  const sa = new THREE.PlaneGeometry(0.1, 0.1);
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

  const lineMat = new MeshLineMaterial({
    useMap: false,
    color: new THREE.Color(0xff0000),
    opacity: 1,
    resolution: new THREE.Vector2(window.innerWidth, window.innerHeight), // Required by MeshLineMaterial
    sizeAttenuation: false,
    lineWidth: 10,
  });
  const line = new MeshLine();
  const lineGeo = new THREE.BufferGeometry().setFromPoints([
    new THREE.Vector3(0, 0, 0),
    new THREE.Vector3(0, 0, 0), // Start with same points to hide line initially
  ]);
  line.setGeometry(lineGeo);
  const lineMesh = new THREE.Mesh(line.geometry, lineMat);
  lineMesh.frustumCulled = false; // Prevents the line from disappearing when out of view
  scene.add(lineMesh);

  let lastTime: number;
  let selectedPosition: THREE.Vector3;
  function render(time: number) {
    // time *= 0.00000001;

    renderer.setClearColor(
      Utils.interpolateOklab(0x000022, 0x87ceeb, scrollPos),
      1,
    );
    dot.material.opacity = Utils.lerp(0.5, 0, scrollPos);

    material.uniforms.time.value = time;
    material.uniforms.waterLevel.value = waterLevel();
    material.uniforms.planetAmplitude.value = planetAmplitude();
    material.uniforms.scrollPos.value = scrollPos;

    // planet.rotation.y += scrollPos === 0 ? 0.005 : 0;

    if (scrollPos <= 0) {
      const objects = pickHelper.pick(pickPosition, scene, camera);

      console.log({ objects });
      const object = objects.find((o) => o.object.userData.isPlanet);
      const p = object?.point || new THREE.Vector3();
      s.position.copy(p);
      s2.position.copy(p);

      if (ships) {
        const nearestShip = findNearestShip(
          planet.clone().worldToLocal(p.clone()),
          ships,
          shipCount,
        );
        console.log({ nearestShip });
        if (nearestShip.position && nearestShip.distance < 0.1) {
          s.material.color = new THREE.Color(0xff0000);

          s.position.copy(planet.localToWorld(nearestShip.position.clone()));
          s2.position.copy(planet.localToWorld(nearestShip.position.clone()));

          // Ship position is already in planet space, so use directly
          lineGeo.setFromPoints([
            new THREE.Vector3(0, 0, 1.5),
            planet.clone().localToWorld(nearestShip.position.clone()),
          ]);

          // 2. Update the MeshLine with the new geometry
          line.setGeometry(lineGeo);

          // 3. Make sure the mesh has the updated geometry
          lineMesh.geometry = line.geometry;

          // Make the line visible
          lineMesh.visible = true;
        } else {
          s.material.color = new THREE.Color(0x0000ff);
          // Hide the line when not needed
          lineMesh.visible = false;
        }
      }

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
        up2.multiplyScalar(0.015).add(normal2.multiplyScalar(0.1)),
      );

      selectedPosition = p;
    }

    if (selectedPosition) {
      const cp = new THREE.Vector3(0, 0, 2).lerp(s2.position, scrollPos);
      camera.position.copy(cp);

      camera.quaternion.slerpQuaternions(
        new THREE.Quaternion(),
        s2.quaternion,
        scrollPos,
      );
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
    stats.update();
    lastTime = time;
  }
  renderer.setAnimationLoop(render);
}

function findNearestShip(
  pickedPosition: THREE.Vector3,
  ships: any,
  shipCount: number,
) {
  let minDistance = Infinity;
  let nearestShipIndex = -1;
  const shipPosition = new THREE.Vector3();
  const dummyMatrix = new THREE.Matrix4();

  // Loop through all ship instances
  for (let i = 0; i < shipCount; i++) {
    // Get the position of this ship instance from its matrix
    ships.getMatrixAt(i, dummyMatrix);
    shipPosition.setFromMatrixPosition(dummyMatrix);

    // Calculate distance to picked position
    const distance = pickedPosition.distanceTo(shipPosition);

    // Update if this is the closest ship so far
    if (distance < minDistance) {
      minDistance = distance;
      nearestShipIndex = i;
    }
  }

  return {
    index: nearestShipIndex,
    distance: minDistance,
    position:
      nearestShipIndex >= 0
        ? (() => {
            const pos = new THREE.Vector3();
            ships.getMatrixAt(nearestShipIndex, dummyMatrix);
            pos.setFromMatrixPosition(dummyMatrix);
            return pos;
          })()
        : null,
  };
}
