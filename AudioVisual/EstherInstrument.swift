//
//  EstherInstrument.swift
//  AudioVisual
//
//  Created by iya student on 4/20/26.
//
import SwiftUI
import RealityKit
import RealityKitContent

struct EstherInstrument: View {
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @State private var isImmersive = false
 
    var body: some View {
        VStack(spacing: 20) {
            Text("Ring Spawner")
                .font(.extraLargeTitle)
                .fontWeight(.bold)
 
            Text("Spawn glowing orbs in a ring around you")
                .font(.title2)
                .foregroundStyle(.secondary)
 
            Button(isImmersive ? "Exit Ring" : "Spawn Ring") {
                Task {
                    if isImmersive {
                        await dismissImmersiveSpace()
                        isImmersive = false
                    } else {
                        await openImmersiveSpace(id: "RingSpace")
                        isImmersive = true
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
        }
        .padding(40)
    }
}
 
// MARK: - Immersive View
 
struct RingImmersiveView: View {
    var body: some View {
        RealityView { content in
            content.add(makeRing())
        }
    }
 
    func makeRing() -> Entity {
        let root = Entity()
 
        let numberOfSpheres = 8
        let ringRadius: Float = 2.0      // meters from user
        let ringHeight: Float = 1.6      // eye level
        let sphereRadius: Float = 0.08
 
        let colors: [UIColor] = [
            .systemBlue, .systemPurple, .systemPink,
            .systemOrange, .systemYellow, .systemGreen,
            .systemCyan, .systemIndigo
        ]
 
        for i in 0..<numberOfSpheres {
            let angle = (Float(i) / Float(numberOfSpheres)) * 2 * Float.pi
 
            let x = ringRadius * sin(angle)
            let z = -ringRadius * cos(angle)  // negative so ring is centered around user
            let y = ringHeight
 
            let sphere = makeSphere(radius: sphereRadius, color: colors[i % colors.count])
            sphere.position = SIMD3<Float>(x, y, z)
            root.addChild(sphere)
        }
 
        return root
    }
 
    func makeSphere(radius: Float, color: UIColor) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: radius)
 
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: color.withAlphaComponent(0.9))
        material.emissiveColor = .init(color: color)
        material.emissiveIntensity = 2.5
        material.metallic = .init(floatLiteral: 0.0)
        material.roughness = .init(floatLiteral: 0.05)
 
        return ModelEntity(mesh: mesh, materials: [material])
    }
}


#Preview(windowStyle: .plain) {
    EstherInstrument()
}

		
