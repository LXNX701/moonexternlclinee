import SwiftUI

struct MoonWelcomeView: View {
    @Binding var isPresented: Bool
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var particles: [MoonParticle] = []
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.0, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(uiImage: loadAppLogo())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: .blue.opacity(0.5), radius: 20)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                VStack(spacing: 8) {
                    Text("WELCOME BACK")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.blue)
                        .tracking(4)
                        .opacity(logoOpacity)
                    
                    Text("MOON PLACE")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.white, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .opacity(titleOpacity)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                } label: {
                    Text("CONTINUE")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 40)
                .opacity(titleOpacity)
                
                Spacer().frame(height: 50)
            }
        }
        .onAppear {
            generateParticles()
            startAnimation()
        }
    }
    
    private func loadAppLogo() -> UIImage {
        UIImage(named: "ExternalIcon") ?? UIImage(systemName: "sparkles") ?? UIImage()
    }
    
    private func generateParticles() {
        particles = (0..<20).map { _ in
            MoonParticle(
                position: CGPoint(x: CGFloat.random(in: 0...400), y: CGFloat.random(in: 0...800)),
                size: CGFloat.random(in: 2...5),
                color: [Color.blue, Color.purple, Color.white].randomElement()!.opacity(0.6),
                opacity: Double.random(in: 0.3...0.7)
            )
        }
    }
    
    private func startAnimation() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
            titleOpacity = 1.0
        }
    }
}

struct MoonParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    let color: Color
    let opacity: Double
}