import SwiftUI

/// Shown on first app launch (or after re-install).
/// Bilingual so both Chinese and English speakers understand before they choose.
struct RegionSelectionView: View {
    /// Called when the user picks a mode — parent re-routes.
    var onSelected: () -> Void

    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color.wallGray.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // ── Logo / title ──────────────────────────────────
                VStack(spacing: 8) {
                    Image("kui")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .scaleEffect(animateIn ? 1 : 0.6)
                        .opacity(animateIn ? 1 : 0)
                        .shadow(color: Color.inkBrown.opacity(0.3), radius: 0, x: 2, y: 3)

                    Text("Guinea Day")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Color.inkBrown)
                        .opacity(animateIn ? 1 : 0)

                    Text("Select your region  /  请选择地区")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(Color.inkBrown.opacity(0.5))
                        .opacity(animateIn ? 1 : 0)
                }

                Spacer()

                // ── Region cards ──────────────────────────────────
                VStack(spacing: 16) {
                    RegionCard(
                        flag: "🇨🇳",
                        title: "中国大陆",
                        subtitle: "Mainland China",
                        description: "仅本地存储，无需网络\nLocal-only, no internet needed",
                        accentColor: Color.blushPink,
                        delay: 0.15
                    ) {
                        choose(.local)
                    }

                    RegionCard(
                        flag: "🌏",
                        title: "International",
                        subtitle: "国际版",
                        description: "Cloud sync & household sharing\n云端同步，与伙伴共享",
                        accentColor: Color.hachiwareBlue,
                        delay: 0.25
                    ) {
                        choose(.cloud)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // ── Footer note ───────────────────────────────────
                Text("You can change this later in Settings.\n之后可在设置中更改。")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Color.inkBrown.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 32)
                    .opacity(animateIn ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(dampingFraction: 0.7).delay(0.1)) {
                animateIn = true
            }
        }
    }

    private func choose(_ mode: AppMode) {
        withAnimation(.easeInOut(duration: 0.2)) {
            AppMode.set(mode)
            onSelected()
        }
    }
}

// MARK: - Region Card
private struct RegionCard: View {
    let flag:        String
    let title:       String
    let subtitle:    String
    let description: String
    let accentColor: Color
    let delay:       Double
    let action:      () -> Void

    @State private var appeared = false
    @State private var pressed  = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(flag)
                    .font(.system(size: 36))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(Color.inkBrown)
                        Text(subtitle)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(Color.inkBrown.opacity(0.5))
                    }
                    Text(description)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Color.inkBrown.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.inkBrown.opacity(0.3))
            }
            .padding(20)
            .background(Color.chiikawaWhite)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22)
                .stroke(accentColor, lineWidth: 2.5))
            .shadow(color: Color.inkBrown.opacity(0.35), radius: 0, x: 3, y: 4)
            .scaleEffect(pressed ? 0.97 : (appeared ? 1 : 0.9))
            .opacity(appeared ? 1 : 0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeIn(duration: 0.1))  { pressed = true  } }
                .onEnded   { _ in withAnimation(.easeOut(duration: 0.2)) { pressed = false } }
        )
        .onAppear {
            withAnimation(.spring(dampingFraction: 0.7).delay(delay)) {
                appeared = true
            }
        }
    }
}

#Preview {
    RegionSelectionView(onSelected: {})
}
