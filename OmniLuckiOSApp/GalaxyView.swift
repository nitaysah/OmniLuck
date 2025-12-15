import SwiftUI

struct GalaxyView: View {
    let accentPurple: Color
    let accentGold: Color
    
    @State private var rotation: Double = 0
    @State private var cloudScale: CGFloat = 1.0
    @State private var aiOpacity: Double = 0.3
    
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 3)
            
            ZStack {
                // 1. Celestial Cloud Background (Replaces Stars)
                // 1. Celestial Cloud Background (REMOVED)
                /*
                Image("celestial_cloud")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(cloudScale)
                    .opacity(0.3)
                    .colorInvert()
                    .blendMode(.multiply)
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                            cloudScale = 1.2
                        }
                    }
                */
                
                // 2. Outer Galaxy Glow
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
                
                // 3. Galaxy Spiral Arms (Existing)
                ZStack {
                    ForEach(0..<4, id: \.self) { arm in
                        GalaxySpiralArm(armIndex: arm, accentPurple: accentPurple, accentGold: accentGold)
                            .frame(width: 300, height: 300)
                            .rotationEffect(.degrees(Double(arm * 90)))
                    }
                }
                .position(center)
                .rotationEffect(.degrees(rotation))
                
                // 4. Galaxy Core
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
                
                // 5. AI Neural Overlay (New)
                Image("ai_neural_overlay")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .position(x: geo.size.width/2, y: geo.size.height/2)
                    .opacity(aiOpacity)
                    .blendMode(.screen)
                    .allowsHitTesting(false)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                            aiOpacity = 0.5
                        }
                    }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
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
