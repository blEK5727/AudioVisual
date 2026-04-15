//
//  ContentView.swift
//  AudioVisual
//
//  Created by iya student on 4/15/26.
//

import SwiftUI
import RealityKit
import RealityKitContent

// MARK: - Shape Types

enum ShapeType: String, CaseIterable, Identifiable {
    case sphere   = "Sphere"
    case cube     = "Cube"
    case cone     = "Cone"
    case cylinder = "Cylinder"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .sphere:   return "circle.fill"
        case .cube:     return "cube.fill"
        case .cone:     return "triangle.fill"
        case .cylinder: return "cylinder.fill"
        }
    }

    var color: Color {
        switch self {
        case .sphere:   return .cyan
        case .cube:     return .orange
        case .cone:     return .pink
        case .cylinder: return .mint
        }
    }

    func makeMesh() -> MeshResource {
        switch self {
        case .sphere:
            return .generateSphere(radius: 0.08)
        case .cube:
            return .generateBox(size: 0.14, cornerRadius: 0.01)
        case .cone:
            return .generateCone(height: 0.16, radius: 0.08)
        case .cylinder:
            return .generateCylinder(height: 0.16, radius: 0.07)
        }
    }
}

// MARK: - Spawned Shape Entity

struct SpawnedShape: Identifiable {
    let id = UUID()
    let type: ShapeType
    var position: SIMD3<Float>
}

// MARK: - Main View

struct ContentView: View {

    @State private var selectedIndex: Int = 0
    @State private var tappedIndex: Int? = nil
    @State private var dragOffset: CGFloat = 0
    @State private var spawnedShapes: [SpawnedShape] = []

    private let shapes = ShapeType.allCases
    private let cardWidth: CGFloat = 120
    private let cardSpacing: CGFloat = 20

    var body: some View {
        ZStack(alignment: .bottom) {

            spawnedShapesView
                .frame(maxWidth: .infinity)
                .padding(.bottom, 300)

            pickerPanel
        }
        .frame(width: 700, height: 550)
    }

    // MARK: Spawned Shapes (RealityView)

    @ViewBuilder
    var spawnedShapesView: some View {
        RealityView { content in
        } update: { content in
            content.entities.removeAll()

            for (i, shape) in spawnedShapes.enumerated() {
                let entity = ModelEntity(
                    mesh: shape.type.makeMesh(),
                    materials: [SimpleMaterial(
                        color: UIColor(shape.type.color),
                        isMetallic: true
                    )]
                )

                let xOffset = Float(i) * 0.22 - Float(spawnedShapes.count - 1) * 0.11
                entity.position = SIMD3<Float>(xOffset, 0.05, 0)

                let light = PointLight()
                light.light.intensity = 2000
                light.light.color = UIColor(shape.type.color)
                light.position = SIMD3<Float>(xOffset, 0.25, 0.2)
                content.add(light)
                content.add(entity)
            }
        }
        .frame(height: 260)
        .background(.clear)
    }

    // MARK: Picker Panel

    var pickerPanel: some View {
        VStack(spacing: 16) {
            Text("Choose a Shape")
                .font(.headline)
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                let totalCards = shapes.count
                let centreOffset = (geo.size.width - cardWidth) / 2

                ZStack {
                    ForEach(Array(shapes.enumerated()), id: \.element.id) { index, shape in
                        shapeCard(shape: shape, index: index, selectedIndex: selectedIndex, tappedIndex: tappedIndex)
                            .offset(x: centreOffset
                                    + CGFloat(index) * (cardWidth + cardSpacing)
                                    - CGFloat(selectedIndex) * (cardWidth + cardSpacing)
                                    + dragOffset)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedIndex = index
                                }
                                tappedIndex = index
                                spawnSelectedShape()
                            }
                    }
                }
                .frame(width: geo.size.width, height: 150, alignment: .leading)
                .clipped()
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = (cardWidth + cardSpacing) / 3
                            let delta = -value.translation.width
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                if delta > threshold {
                                    selectedIndex = min(selectedIndex + 1, totalCards - 1)
                                } else if delta < -threshold {
                                    selectedIndex = max(selectedIndex - 1, 0)
                                }
                                dragOffset = 0
                            }
                        }
                )
            }
            .frame(height: 130)

            if !spawnedShapes.isEmpty {
                Button(role: .destructive) {
                    withAnimation { spawnedShapes.removeAll() }
                } label: {
                    Label("Clear All", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 40)
        .padding(.bottom, 24)
    }

    // MARK: Shape Card

    @ViewBuilder
    func shapeCard(shape: ShapeType, index: Int, selectedIndex: Int, tappedIndex: Int?) -> some View {
        let isSelected = index == tappedIndex
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(shape.color.opacity(0.15))
                    .frame(width: 70, height: 70)

                Image(systemName: shape.symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundStyle(shape.color)
            }

            Text(shape.rawValue)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? shape.color : .secondary)
        }
        .frame(width: cardWidth, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? shape.color.opacity(0) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? shape.color : Color.secondary.opacity(0),
                                lineWidth: isSelected ? 2 : 1)
                )
        )
        .scaleEffect(isSelected ? 1.0 : 0.88)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: tappedIndex)
    }

    // MARK: Helpers

    private func spawnSelectedShape() {
        let shape = shapes[selectedIndex]
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            spawnedShapes.append(SpawnedShape(type: shape, position: .zero))
        }
    }
}

// MARK: - Preview

#Preview(windowStyle: .plain) {
    ContentView()
}
