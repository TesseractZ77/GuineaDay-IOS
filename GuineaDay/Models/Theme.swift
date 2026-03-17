import SwiftUI

// MARK: - Hex Color Init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Chiikawa Palette
extension Color {
    /// Chiikawa's pure white body
    static let chiikawaWhite  = Color(hex: "FFFFFF")
    /// Hachiware's signature blue hair
    static let hachiwareBlue  = Color(hex: "6FB3D2")
    /// Usagi's warm yellow body
    static let usagiYellow    = Color(hex: "FFF4C2")
    /// Soft blush cheek pink
    static let blushPink      = Color(hex: "FF99A8")
    /// The thick inkBrown used for ALL outlines and text
    static let inkBrown       = Color(hex: "3D2314")
    /// Background wall (light cool grey-white)
    static let wallGray       = Color(hex: "EEF1F4")
    /// Soft mint — used for tasks / health
    static let mintGreen      = Color(hex: "B8E0D2")
    /// Soft lavender — used for gallery / memories
    static let lavenderPurple = Color(hex: "C9B8E8")
    /// Warm peach — used for game
    static let peachOrange    = Color(hex: "FFD4A8")
}

// MARK: - Chiikawa Card (sticker/badge style)
struct ChiikawaCardStyle: ViewModifier {
    var backgroundColor: Color = .chiikawaWhite
    var cornerRadius: CGFloat  = 20

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.inkBrown, lineWidth: 3))
            .shadow(color: Color.inkBrown.opacity(0.5), radius: 0, x: 2, y: 3)
    }
}

extension View {
    func chiikawaCard(color: Color = .chiikawaWhite, radius: CGFloat = 20) -> some View {
        self.modifier(ChiikawaCardStyle(backgroundColor: color, cornerRadius: radius))
    }
}

// MARK: - Chiikawa Section Header
struct ChiikawaSectionHeader: View {
    let title: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .foregroundColor(.inkBrown)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(color)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.inkBrown, lineWidth: 2))
        .shadow(color: Color.inkBrown.opacity(0.4), radius: 0, x: 1, y: 2)
    }
}

// MARK: - Sparkle / Star Decorator
struct SparkleView: View {
    let size: CGFloat
    let color: Color
    @State private var opacity: Double = 0.4
    @State private var scale: CGFloat = 0.8

    var body: some View {
        Text("✦")
            .font(.system(size: size, weight: .black))
            .foregroundColor(color)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 1.5...3.0))
                    .repeatForever(autoreverses: true)
                ) {
                    opacity = 1.0
                    scale   = 1.2
                }
            }
    }
}
