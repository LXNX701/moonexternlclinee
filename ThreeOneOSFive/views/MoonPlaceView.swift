import SwiftUI

enum MoonPlaceMode: String, CaseIterable, Identifiable {
    case v1f = "V1F"
    case v2fx = "V2FX"
    var id: String { rawValue }
}

struct MoonPlaceView: View {
    @StateObject private var auth = MoonAuthManager.shared
    @State private var selectedMode: MoonPlaceMode?
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.0, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                if let mode = selectedMode {
                    PatchModeView(mode: mode, onBack: { selectedMode = nil })
                } else {
                    modeSelectorView
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(uiImage: UIImage(named: "ExternalIcon") ?? UIImage(systemName: "sparkles")!)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("MOON PLACE")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    if let user = auth.currentUser {
                        Text(user.displayName ?? user.email ?? "User")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                
                Spacer()
                
                Menu {
                    Button("Logout", role: .destructive) {
                        auth.signOut()
                    }
                } label: {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Divider().background(.white.opacity(0.1))
        }
    }
    
    private var modeSelectorView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("SELECT MODE OF CONTROL")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(3)
                    .padding(.top, 40)
                
                VStack(spacing: 16) {
                    ForEach(MoonPlaceMode.allCases) { mode in
                        ModeCard(mode: mode) {
                            selectedMode = mode
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer().frame(height: 40)
            }
        }
    }
}

struct ModeCard: View {
    let mode: MoonPlaceMode
    let action: () -> Void
    @State private var isPressed = false
    
    private var modeColor: Color {
        mode == .v1f ? .blue : .purple
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(mode.rawValue)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("SELECT")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(modeColor.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(modeColor.opacity(0.5), lineWidth: 1.5)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}