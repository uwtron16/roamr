//
//  JoystickView.swift
//  roamr
//
//  Created by Anders Tai on 2025-11-23.
//

import SwiftUI
import Combine

struct JoystickView: View {
    let size: CGFloat
    let onUpdate: (Int, Int, Int) -> Void // (leftMotor, rightMotor, duration)

    @State private var knobPosition: CGPoint = .zero
    @State private var isDragging = false
    @State private var timer: Timer?

    private let knobSize: CGFloat
    private let maxDistance: CGFloat
    private let sendInterval: TimeInterval = 0.05 // 50ms
    private let holdDuration: Int = 100 // 100ms duration for ESP32

    init(size: CGFloat = 250, onUpdate: @escaping (Int, Int, Int) -> Void) {
        self.size = size
        self.knobSize = size * 0.35
        self.maxDistance = (size - knobSize) / 2
        self.onUpdate = onUpdate
    }

    var body: some View {
        ZStack {
            // Base circle
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: size, height: size)

            // Directional indicators
            VStack {
                Image(systemName: "arrowtriangle.up.fill")
                    .foregroundColor(.gray.opacity(0.3))
                Spacer()
                Image(systemName: "arrowtriangle.down.fill")
                    .foregroundColor(.gray.opacity(0.3))
            }
            .frame(height: size * 0.6)

            HStack {
                Image(systemName: "arrowtriangle.left.fill")
                    .foregroundColor(.gray.opacity(0.3))
                Spacer()
                Image(systemName: "arrowtriangle.right.fill")
                    .foregroundColor(.gray.opacity(0.3))
            }
            .frame(width: size * 0.6)

            // Center dot
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 10, height: 10)

            // Knob
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: knobSize, height: knobSize)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                .offset(x: knobPosition.x, y: knobPosition.y)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                startSendingUpdates()
                            }
                            updateKnobPosition(translation: value.translation)
                        }
                        .onEnded { _ in
                            isDragging = false
                            stopSendingUpdates()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                knobPosition = .zero
                            }
                            // Send stop command
                            onUpdate(0, 0, holdDuration)
                        }
                )

            // Debug info overlay
            VStack {
                Spacer()
                let (left, right) = calculateMotorValues()
                Text("L: \(left)% R: \(right)%")
                    .font(.caption)
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .frame(height: size)
        }
        .frame(width: size, height: size)
    }

    private func updateKnobPosition(translation: CGSize) {
        let newPosition = CGPoint(
            x: translation.width,
            y: translation.height
        )

        let distance = sqrt(newPosition.x * newPosition.x + newPosition.y * newPosition.y)

        if distance <= maxDistance {
            knobPosition = newPosition
        } else {
            let angle = atan2(newPosition.y, newPosition.x)
            knobPosition = CGPoint(
                x: cos(angle) * maxDistance,
                y: sin(angle) * maxDistance
            )
        }
    }

    private func calculateMotorValues() -> (left: Int, right: Int) {
        // Normalize position to -100 to 100
        let x = (knobPosition.x / maxDistance) * 100
        let y = -(knobPosition.y / maxDistance) * 100 // Invert Y axis (up is positive)

        // Differential drive: left = y + x, right = y - x
        var left = y + x
        var right = y - x

        // Clamp to -100 to 100
        left = max(-100, min(100, left))
        right = max(-100, min(100, right))

        return (Int(left.rounded()), Int(right.rounded()))
    }

    private func startSendingUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: sendInterval, repeats: true) { _ in
            let (left, right) = calculateMotorValues()
            onUpdate(left, right, holdDuration)
        }
    }

    private func stopSendingUpdates() {
        timer?.invalidate()
        timer = nil
    }
}
