import SwiftUI

struct GameHubView: View {
    enum Screen { case hub, flyingPiggy, maze }
    @State private var screen: Screen = .hub

    var body: some View {
        switch screen {
        case .hub:        hubView
        case .flyingPiggy:
            GameContainerView()

        case .maze:        MazeGameView()
        }
    }

    // MARK: - Hub
    var hubView: some View {
        ZStack {
            Color.wallGray.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    VStack(spacing: 6) {
                        Text("🎮 Game Room")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(Color.inkBrown)
                        Text("Pick a game to play!")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(Color.inkBrown.opacity(0.5))
                    }
                    .padding(.top, 40)

                    // Flying Piggy card
                    gameCard(
                        emoji: "🐹",
                        title: "Flying Piggy",
                        description: "Drag your pig onto food to feed it!\nScore points and keep going.",
                        color: Color.peachOrange
                    ) {
                        screen = .flyingPiggy
                    }

                    // Guinea Maze card
                    gameCard(
                        emoji: "🌀",
                        title: "Guinea Maze",
                        description: "Swipe through a randomly generated\nmaze to reach the 🍓!",
                        color: Color.mintGreen
                    ) {
                        screen = .maze
                    }

                    Spacer().frame(height: 90)
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Card
    func gameCard(emoji: String, title: String, description: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 50))
                    .frame(width: 70, height: 70)
                    .background(Color.chiikawaWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.inkBrown, lineWidth: 2))

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(Color.inkBrown)
                    Text(description)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color.inkBrown.opacity(0.65))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Color.inkBrown.opacity(0.5))
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .chiikawaCard(color: color, radius: 24)
        }
        .buttonStyle(.plain)
    }
}
