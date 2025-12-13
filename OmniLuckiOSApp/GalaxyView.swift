import SwiftUI

struct GalaxyView: View {
    let accentPurple: Color
    let accentGold: Color
    
    @State private var rotation: Double = 0
    
    // Pre-generate fixed star positions
    private let starData: [(angle: Double, radius: CGFloat, size: CGFloat, isGold: Bool)] = {
        var stars: [(Double, CGFloat, CGFloat, Bool)] = []
        for i in 0..<30 {
            let angle = Double(i) * (360.0 / 30.0)
            let radius = CGFloat(20 + (i * 4) % 100)
            let size = CGFloat(1 + (i % 4))
            let isGold = i % 3 == 0
            stars.append((angle, radius, size, isGold))
        }
        return stars
    }()
    
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 3)
            
            ZStack {
                // Outer Galaxy Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentPurple.opacity(0.3), accentPurple.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .position(center)
                    .blur(radius: 30)
                
                // Galaxy Spiral Arms
                ZStack {
                    ForEach(0..<4, id: \.self) { arm in
                        GalaxySpiralArm(armIndex: arm, accentPurple: accentPurple, accentGold: accentGold)
                            .frame(width: 300, height: 300)
                            .rotationEffect(.degrees(Double(arm * 90)))
                    }
                }
                .position(center)
                .rotationEffect(.degrees(rotation))
                
                // Stars
                ZStack {
                    ForEach(0..<starData.count, id: \.self) { i in
                        let star = starData[i]
                        Circle()
                            .fill(star.isGold ? accentGold.opacity(0.6) : accentPurple.opacity(0.5))
                            .frame(width: star.size, height: star.size)
                            .offset(
                                x: cos(star.angle * .pi / 180) * star.radius,
                                y: sin(star.angle * .pi / 180) * star.radius
                            )
                    }
                }
                .position(center)
                .rotationEffect(.degrees(rotation * 0.5))
                
                // Core
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentGold.opacity(0.8), accentPurple.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 5,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .position(center)
                    .blur(radius: 8)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

struct GalaxySpiralArm: View {
    let armIndex: Int
    let accentPurple: Color
    let accentGold: Color
    
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            
            for i in 0..<20 {
                let t = Double(i) / 20.0
                let angle = t * 2.5 * .pi
                let radius = t * 120
                
                let x = center.x + CGFloat(cos(angle)) * CGFloat(radius)
                let y = center.y + CGFloat(sin(angle)) * CGFloat(radius)
                
                let dotSize = CGFloat(4 - t * 3)
                let opacity = 0.6 - t * 0.4
                
                let rect = CGRect(x: x - dotSize/2, y: y - dotSize/2, width: dotSize, height: dotSize)
                
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(armIndex % 2 == 0 ? accentPurple.opacity(opacity) : accentGold.opacity(opacity * 0.7))
                )
            }
        }
    }
}
