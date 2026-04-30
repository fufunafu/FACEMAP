"use client";

import { Suspense } from "react";
import { Canvas } from "@react-three/fiber";
import { OrbitControls, useGLTF, Center } from "@react-three/drei";

/**
 * The actual three.js canvas. Split out from mesh-viewer.tsx so the
 * dynamic import in mesh-viewer pulls this whole module (three + drei
 * + the GLB loader) only when needed.
 */
export function MeshCanvas({ src }: { src: string }) {
  return (
    <Canvas camera={{ position: [0, 0, 1.6], fov: 38 }} dpr={[1, 2]}>
      <ambientLight intensity={0.6} />
      <directionalLight position={[2, 2, 3]} intensity={0.8} />
      <directionalLight position={[-2, 0, -1]} intensity={0.25} />
      <Suspense fallback={null}>
        <Center>
          <Mesh src={src} />
        </Center>
      </Suspense>
      <OrbitControls
        enablePan={false}
        minDistance={0.8}
        maxDistance={3}
        autoRotate
        autoRotateSpeed={0.4}
      />
    </Canvas>
  );
}

function Mesh({ src }: { src: string }) {
  const gltf = useGLTF(src);
  return <primitive object={gltf.scene} />;
}
