//
//  ConfettiPiece.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-29.
//


import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let velocityX: CGFloat
    let velocityY: CGFloat
}

struct ConfettiView: View {
    @Binding var isShowing: Bool
    
    @State private var pieces: [ConfettiPiece] = []
    @State private var timer: Timer?
    
    private let colors: [Color] = [
        .pink, .blue, .yellow, .green, .orange, .purple, .mint, .cyan
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 1.5)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(x: piece.x, y: piece.y)
                }
            }
            .onChange(of: isShowing) { _, newValue in
                if newValue {
                    startConfetti(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func startConfetti(in size: CGSize) {
        pieces = []
        
        // Create initial burst of confetti
        for _ in 0..<50 {
            let piece = ConfettiPiece(
                x: size.width / 2 + CGFloat.random(in: -50...50),
                y: size.height / 2,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                velocityX: CGFloat.random(in: -8...8),
                velocityY: CGFloat.random(in: -15...(-5))
            )
            pieces.append(piece)
        }
        
        // Animate pieces falling
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updatePieces(in: size)
        }
        
        // Stop after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            timer?.invalidate()
            timer = nil
            pieces = []
            isShowing = false
        }
    }
    
    private func updatePieces(in size: CGSize) {
        for i in pieces.indices {
            pieces[i].x += pieces[i].velocityX
            pieces[i].y += pieces[i].velocityY + 2 // gravity
        }
        
        // Remove pieces that fell off screen
        pieces.removeAll { $0.y > size.height + 50 }
    }
}

// View modifier for easy use
struct ConfettiModifier: ViewModifier {
    @ObservedObject var manager = ConfettiManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            ConfettiView(isShowing: $manager.isShowing)
        }
    }
}

extension View {
    func confetti() -> some View {
        modifier(ConfettiModifier())
    }
}
