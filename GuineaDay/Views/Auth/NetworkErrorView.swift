import SwiftUI

/// Shown when Firebase is unreachable (common for users in mainland China).
/// Displayed in both English and Simplified Chinese.
struct NetworkErrorView: View {
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

                // Title & body — English
                VStack(spacing: 8) {
                    Text("Unable to Connect")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.inkBrown)

                    Text("GuineaDay requires access to international network services (Firebase). If you're in mainland China, please use a VPN and try again.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.inkBrown.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Divider
                Rectangle()
                    .fill(Color.inkBrown.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 32)

                // Title & body — Chinese
                VStack(spacing: 8) {
                    Text("无法连接")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.inkBrown)

                    Text("GuineaDay 需要访问国际网络服务（Firebase）。如果您在中国大陆，请使用 VPN 后重试。")
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
                        Text("Retry  /  重试")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.inkBrown)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .chiikawaCard(color: .usagiYellow, radius: 20)
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
            }
            .padding(.horizontal, 24)
        }
        .fontDesign(.rounded)
    }
}

#Preview {
    NetworkErrorView(onRetry: {})
}
