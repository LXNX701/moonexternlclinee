import SwiftUI

struct PatchModeView: View {
    let mode: MoonPlaceMode
    let onBack: () -> Void
    
    @EnvironmentObject private var patchStore: PatchProjectStore
    @State private var activePatches: Set<String> = []
    @State private var applyingPatch: String?
    
    private var patchOptions: [PatchOption] {
        switch mode {
        case .v1f:
            return [
                PatchOption(id: "v1f-head-sn", title: "CABEZA SN"),
                PatchOption(id: "v1f-neck-sn", title: "CUELLO SN"),
                PatchOption(id: "v1f-drag-sn", title: "DRAG SN"),
                PatchOption(id: "v1f-chest-sn", title: "PECHO SN"),
                PatchOption(id: "v1f-head", title: "CABEZA V1"),
                PatchOption(id: "v1f-neck", title: "CUELLO V1"),
                PatchOption(id: "v1f-drag", title: "DRAG V1"),
                PatchOption(id: "v1f-chest", title: "PECHO V1")
            ]
        case .v2fx:
            return [
                PatchOption(id: "v2fx-head-sn", title: "CABEZA SN"),
                PatchOption(id: "v2fx-neck-sn", title: "CUELLO SN"),
                PatchOption(id: "v2fx-drag-sn", title: "DRAG SN"),
                PatchOption(id: "v2fx-chest-sn", title: "PECHO SN"),
                PatchOption(id: "v2fx-head", title: "CABEZA V2"),
                PatchOption(id: "v2fx-neck", title: "CUELLO V2"),
                PatchOption(id: "v2fx-drag", title: "DRAG V2"),
                PatchOption(id: "v2fx-chest", title: "PECHO V2")
            ]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("BACK")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.blue)
                }
                
                Spacer()
                
                Text(mode.rawValue)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Color.clear.frame(width: 60, height: 1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider().background(.white.opacity(0.1))
            
            ScrollView {
                VStack(spacing: 12) {
                    Text("MOON PLACE SELECTOR")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(2)
                        .padding(.top, 24)
                    
                    LazyVStack(spacing: 10) {
                        ForEach(patchOptions) { option in
                            PatchOptionRow(
                                option: option,
                                isActive: activePatches.contains(option.id),
                                isApplying: applyingPatch == option.id,
                                onToggle: { togglePatch(option) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 40)
                }
            }
        }
    }
    
    private func togglePatch(_ option: PatchOption) {
        if applyingPatch == option.id { return }
        
        if activePatches.contains(option.id) {
            restorePatch(option)
        } else {
            applyPatch(option)
        }
    }
    
    private func applyPatch(_ option: PatchOption) {
        applyingPatch = option.id
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                activePatches.insert(option.id)
                applyingPatch = nil
            }
        }
    }
    
    private func restorePatch(_ option: PatchOption) {
        applyingPatch = option.id
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            await MainActor.run {
                activePatches.remove(option.id)
                applyingPatch = nil
            }
        }
    }
}