import SwiftUI

struct PatchOption: Identifiable {
    let id: String
    let title: String
}

struct PatchOptionRow: View {
    let option: PatchOption
    let isActive: Bool
    let isApplying: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(isActive ? "ACTIVE" : "INACTIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isActive ? .green : .white.opacity(0.4))
                        .tracking(1)
                }
                
                Spacer()
                
                if isApplying {
                    ProgressView()
                        .tint(.blue)
                } else {
                    Text(isActive ? "ON" : "OFF")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(isActive ? .green : .white.opacity(0.5))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isActive ? Color.green.opacity(0.1) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isActive ? Color.green.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isApplying)
    }
}