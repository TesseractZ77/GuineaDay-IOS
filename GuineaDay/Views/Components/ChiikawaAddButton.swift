import SwiftUI
import PhotosUI

// MARK: - Animated Add Button (regular action)
/// A 34×34 circular + button matching the Duties toolbar style.
/// Flashes dark on tap to confirm the interaction.
struct ChiikawaAddButton: View {
    let color:  Color
    let action: () -> Void

    @State private var isFlashing = false

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.12)) { isFlashing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(.easeInOut(duration: 0.12)) { isFlashing = false }
            }
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(isFlashing ? Color.inkBrown : color)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().stroke(Color.inkBrown, lineWidth: 2))
                    .shadow(color: Color.inkBrown.opacity(0.4), radius: 0, x: 1, y: 2)
                    .scaleEffect(isFlashing ? 0.88 : 1.0)
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(isFlashing ? color : Color.inkBrown)
            }
            .animation(.easeInOut(duration: 0.12), value: isFlashing)
        }
    }
}

// MARK: - Animated PhotosPicker Add Button (Gallery)
/// Wraps a PhotosPicker with the same animated style.
struct ChiikawaPhotoPickerButton: View {
    let color: Color
    @Binding var selectedItems: [PhotosPickerItem]

    @State private var isFlashing = false

    var body: some View {
        PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
            ZStack {
                Circle()
                    .fill(isFlashing ? Color.inkBrown : color)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().stroke(Color.inkBrown, lineWidth: 2))
                    .shadow(color: Color.inkBrown.opacity(0.4), radius: 0, x: 1, y: 2)
                    .scaleEffect(isFlashing ? 0.88 : 1.0)
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(isFlashing ? color : Color.inkBrown)
            }
            .animation(.easeInOut(duration: 0.12), value: isFlashing)
        }
        // Detect tap to trigger the flash without blocking the PhotosPicker gesture
        .simultaneousGesture(TapGesture().onEnded {
            withAnimation(.easeInOut(duration: 0.12)) { isFlashing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(.easeInOut(duration: 0.12)) { isFlashing = false }
            }
        })
    }
}
