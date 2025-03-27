import "./style.css";
import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import Stats from "three/addons/libs/stats.module.js";
//@ts-expect-error It wants three.meshline types
import { MeshLine, MeshLineMaterial, MeshLineRaycast } from "three.meshline";
import * as Utils from "./utils";
import {
  fragmentShader,
  vertexShader,
  NoisePointGenerator,
  vertexIdentityShader,
  fragmentAtmosphereShader,
  fragmentDetailedShipShadowShader,
} from "./gpu";
import localforage from "localforage";
import anime from "animejs/lib/anime.es.js";

const canvasSelector = "#app > canvas";
const loadingProgressDisplay = document.querySelector(
  "#app > #cover > #loading-progress",
) as HTMLParagraphElement;

const loadingLine = document.getElementById("line")!;
loadingLine.setAttribute("stroke-dasharray", "1800");
loadingLine.style.strokeDashoffset = "1800px";

let initialised = false;

document.addEventListener("DOMContentLoaded", () => {
  if (document.querySelector(canvasSelector)) {
    buildScene();
  }
});

let zoomingInToShipStartTime: DOMHighResTimeStamp | null = null;
let scrollPos = 0;
window.addEventListener("wheel", (e) => {
  if (zoomingInToShipStartTime) return;

  scrollPos += e.deltaY / 1_000;
  scrollPos = Math.max(0, Math.min(1, scrollPos));
});

let clicked = false;
window.addEventListener("mousedown", () => (clicked = true));
window.addEventListener("mouseup", () => (clicked = false));

async function loadShips() {
  loadingProgressDisplay.textContent = "Loading ships";

  const cachedShips: string | null = await localforage.getItem("ships");
  if (cachedShips) {
    loadingLine.style.strokeDashoffset = "0px";
    return JSON.parse(cachedShips);
  }

  const url = "http://localhost:8080/"; // "https://api.ships.hackclub.com/"
  const response = await fetch(url);
  if (!response?.body) return;

  const contentLength = response.headers.get("x-length");
  const total = parseInt(contentLength || "1");
  const values: number[] = [];
  const reader = response.body.getReader();
  let loadedBytes = 0;

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    // It may not look like it but this is what peak performance looks like (no, really).
    for (let i = 0; i < value.length; i++) {
      values.push(value[i]);
    }

    loadedBytes += value.byteLength;
    loadingLine.style.strokeDashoffset = `${(1 - loadedBytes / total) * 1800}px`;
  }

  const utf8decoder = new TextDecoder("utf-8");
  const decodedText = utf8decoder.decode(new Uint8Array(values));

  await localforage.setItem("ships", decodedText);

  return JSON.parse(decodedText);
}

async function buildScene() {
  const canvas = document.querySelector(canvasSelector) as HTMLCanvasElement;

  const shipsData = await loadShips();
  loadingProgressDisplay.textContent = "Worldbuilding";

  const stats = new Stats();
  document.body.appendChild(stats.dom);

  const shipCount = shipsData.length;
  let ships: THREE.InstancedMesh;
  let detailedShip: THREE.Mesh;

  const planetAmplitude = () => 1.5;
  const waterLevel = () => 0.65;

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
    antialias: true,
  });
  renderer.setPixelRatio(window.devicePixelRatio || 1);
  renderer.setClearColor(0xffffff, 0);
  renderer.setSize(window.innerWidth, window.innerHeight);

  const geometry = new THREE.IcosahedronGeometry(1, 50);
  // const material = new THREE.MeshBasicMaterial({ color:  });
  const material = new THREE.ShaderMaterial({
    // wireframe: true,
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

  const atmosphereGeometry = geometry.clone();
  atmosphereGeometry.scale(1.055, 1.055, 1.055);
  const atmosphereMaterial = new THREE.ShaderMaterial({
    side: THREE.BackSide,
    transparent: true,
    uniforms: {
      resolution: { value: new THREE.Vector2() },
      scrollPos: { value: scrollPos },
      uCameraPos: { value: camera.position },
      uCameraRot: { value: camera.rotation },
    },
    vertexShader: vertexIdentityShader,
    fragmentShader: fragmentAtmosphereShader,
  });
  const atmosphere = new THREE.Mesh(atmosphereGeometry, atmosphereMaterial);
  scene.add(atmosphere);

  scene.add(planet);

  const gltfLoader = new GLTFLoader();

  let shipGeometry: THREE.BufferGeometry;
  const zoomedOutShipScale = 0.01;

  const shipMaterial = new THREE.MeshPhongMaterial({ color: 0xffffff });
  const detailedShipShadowMaterial = new THREE.ShaderMaterial({
    transparent: true,
    uniforms: {
      scrollPos: { value: scrollPos },
    },
    vertexShader: vertexIdentityShader,
    fragmentShader: fragmentDetailedShipShadowShader,
  });

  gltfLoader.load("/ship_lod_high.gltf", (gltf) => {
    shipGeometry = (gltf.scene.children[0] as THREE.Mesh).geometry;
    shipGeometry.scale(
      zoomedOutShipScale,
      zoomedOutShipScale,
      zoomedOutShipScale,
    );

    const detailedShipShadowGeometry = new THREE.CircleGeometry(0.02);
    const detailedShipShadow = new THREE.Mesh(
      detailedShipShadowGeometry,
      detailedShipShadowMaterial,
    );
    detailedShipShadow.rotateX(Utils.rad(-90));

    detailedShip = new THREE.Mesh(shipGeometry, shipMaterial);
    detailedShip.add(detailedShipShadow);

    planet.add(detailedShip);
  });

  gltfLoader.load(
    "/ship_lod0.gltf",
    (gltf) => {
      shipGeometry = (gltf.scene.children[0] as THREE.Mesh).geometry;
      shipGeometry.scale(
        zoomedOutShipScale,
        zoomedOutShipScale,
        zoomedOutShipScale,
      );

      ships = new THREE.InstancedMesh(shipGeometry, shipMaterial, shipCount);
      ships.instanceMatrix.setUsage(THREE.StaticDrawUsage); // https://www.khronos.org/opengl/wiki/Buffer_Object#Buffer_Object_Usage

      // const sunLight = new THREE.DirectionalLight(0xffe499, 5);
      // sunLight.castShadow = true;
      // sunLight.shadow.camera.near = 0.1;
      // sunLight.shadow.camera.far = 5;
      // sunLight.shadow.camera.right = 2;
      // sunLight.shadow.camera.left = -2;
      // sunLight.shadow.camera.top = 1;
      // sunLight.shadow.camera.bottom = -2;
      // sunLight.shadow.mapSize.width = 2048;
      // sunLight.shadow.mapSize.height = 2048;
      // sunLight.shadow.bias = -0.001;
      // sunLight.position.set(0.5, 3, 0.5);
      // scene.add(sunLight);

      const sun = new THREE.DirectionalLight(0xffffcc, 2);
      sun.position.set(10, -5, 10);
      sun.lookAt(planet.position);
      scene.add(sun);
      scene.add(new THREE.AmbientLight(0xffffff, 0.5));

      const noiseGenerator = new NoisePointGenerator(renderer);
      let dummyShipTransform = new THREE.Object3D();

      const genShips = () => {
        if (ships) planet.remove(ships);
        const waterPoints = noiseGenerator.generatePoints(
          waterLevel(),
          planetAmplitude(),
          shipCount,
        );

        // function hashStringToColor(str: string): number {
        //   let hash = 0x811c9dc5; // FNV offset basis

        //   for (let i = 0; i < str.length; i++) {
        //     hash ^= str.charCodeAt(i);
        //     hash = Math.imul(hash, 0x01000193); // FNV prime
        //   }

        //   // Ensure positive and in range 0x000000-0xffffff
        //   return Math.abs(hash) % 0x1000000;
        // }

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
          dummyShipTransform.rotateY(Math.random() * 2 * Math.PI);

          dummyShipTransform.updateMatrix();
          ships.setMatrixAt(i, dummyShipTransform.matrix);

          // ships.setColorAt(
          //   i,
          //   new THREE.Color(hashStringToColor(shipsData[i].ysws)),
          // );
        }
        planet.add(ships);
      };
      genShips();
    },
    // called while loading is progressing
    function (xhr) {
      console.log((xhr.loaded / xhr.total) * 100 + "% loaded");
    },
    // called when loading has errors
    function (error) {
      console.log("An error happened", error);
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

  //#region Stars
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
  //#endregion

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
  // scene.add(s);
  // scene.add(s2);

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
  // scene.add(lineMesh);

  function easeInOutCubic(x: number): number {
    return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2;
  }

  let selectedPosition: THREE.Vector3;
  let selectedShipIndex: number | null;
  function render(time: number) {
    renderer.setClearColor(
      Utils.interpolateOklab(0x000022, 0x3d6db7, scrollPos),
      1,
    );

    atmosphere.scale.setScalar(Utils.lerp(1, 0.99, scrollPos));

    planet.rotation.y += scrollPos === 0 ? 0.001 : 0;

    if (scrollPos <= 0) {
      const objects = pickHelper.pick(pickPosition, scene, camera);

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
        if (nearestShip?.position) {
          if (clicked) {
            zoomingInToShipStartTime = performance.now();
          }

          selectedShipIndex = nearestShip.index;

          const si = shipsData[nearestShip.index];

          let url = si.code_url;
          try {
            url = new URL(url).pathname;
          } catch (e) {}

          document.getElementById("details")!.innerHTML = `
<span style="font-size: 1.2em; font-weight: bold;">${si.ysws}</span>
<br />
<span>${url}</span>
<br />
<img src=${si.screenshot_url} />
<br />
<span>${si.country ? `From ${si.country}.` : ""}${si.hours ? ` Took ${si.hours} hours.` : ""}<span>
`;
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

          selectedShipIndex = null;
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
        up2.multiplyScalar(0.0035).add(normal2.multiplyScalar(0.008)),
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

    if (shipGeometry && detailedShip) {
      const dummy = new THREE.Object3D();
      const lerpedShipGeometryScale = Utils.lerp(1, 0.2, scrollPos);

      for (let i = 0; i < ships.count; i++) {
        ships.getMatrixAt(i, dummy.matrix);
        dummy.matrix.decompose(dummy.position, dummy.quaternion, dummy.scale);

        /* Oh my god the > 0.5 might be my most genius move ever.
         * If you omit it you can see all the models change LOD upon hover.
         * Only changing it as you're zooming in means that it's probably
         * out of view while the camera is zooming into it.
         * Even if it's visible for the duration of the zoom, you can't discern
         * the LOD switch because of the camera movement.
         * IT'S SO SMOOTH WTF 😭
         */
        dummy.scale.setScalar(lerpedShipGeometryScale);
        if (selectedShipIndex === i && scrollPos > 0.5) {
          detailedShip.position.copy(dummy.position);
          detailedShip.rotation.copy(dummy.rotation);
          detailedShip.scale.copy(dummy.scale);

          dummy.scale.setScalar(0.000000001);
        }
        dummy.updateMatrix();
        ships.setMatrixAt(i, dummy.matrix);
      }

      ships.instanceMatrix.needsUpdate = true;
    }

    const zoomEaseTime = 1_500;
    if (zoomingInToShipStartTime) {
      if (performance.now() - zoomingInToShipStartTime > zoomEaseTime) {
        zoomingInToShipStartTime = null;
      } else {
        scrollPos = easeInOutCubic(
          (performance.now() - zoomingInToShipStartTime) / zoomEaseTime,
        );
      }
    }

    // if (scrollPos <= 0 && clicked) {
    //   // Calculate angle tangent to planet at point p
    //   // Step 1: Draw line between point and planet origin
    //   console.log(p.normalize());
    //   camera.rotation.setFromVector3(
    //     new THREE.Vector3(0, 0, 0).lerp(upDir, scrollPos),
    //   );
    // }

    dot.material.opacity = Utils.lerp(0.5, 0, scrollPos);

    material.uniforms.time.value = time;
    material.uniforms.waterLevel.value = waterLevel();
    material.uniforms.planetAmplitude.value = planetAmplitude();
    atmosphereMaterial.uniforms.uCameraPos.value.copy(camera.position);
    material.uniforms.scrollPos.value =
      atmosphereMaterial.uniforms.scrollPos.value =
      detailedShipShadowMaterial.uniforms.scrollPos.value =
        scrollPos;

    renderer.render(scene, camera);

    if (!initialised) {
      initialised = true;
      anime({
        targets: "#app > #cover",
        opacity: 0,
        easing: "easeInOutSine",
        duration: 1_000,
        delay: 500,
        direction: "forward",
      });
    }

    stats.update();
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
