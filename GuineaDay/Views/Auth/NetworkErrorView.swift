import SwiftUI

/// Shown when Firebase is unreachable (common for users in mainland China).
struct NetworkErrorView: View {
    @EnvironmentObject var lang: LanguageManager
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.wallGray.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.usagiYellow)
                        .frame(width: 100, height: 100)
                        .overlay(Circle().stroke(Color.inkBrown, lineWidth: 3))
                        .shadow(color: Color.inkBrown.opacity(0.4), radius: 0, x: 3, y: 4)
                    Text("🌐")
                        .font(.system(size: 48))
                }

                // Title & body
                VStack(spacing: 8) {
                    Text(lang.networkErrorTitle)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.inkBrown)

                    Text(lang.networkErrorBody)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.inkBrown.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                Spacer()

                // Retry button
                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .bold))
                        Text(lang.retry)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.inkBrown)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .chiikawaCard(color: .usagiYellow, radius: 20)
                .padding(.horizontal, 32)
                .padding(.bottom, 12)
                
                // Switch to Local Mode escape hatch
                Button {
                    AppSession.shared.teardownCloudServices()
                    AppMode.set(.local)
                } label: {
                    Text(lang.skipNetwork)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.inkBrown.opacity(0.6))
                        .underline()
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .fontDesign(.rounded)
    }
}

#Preview {
    NetworkErrorView(onRetry: {})
}
