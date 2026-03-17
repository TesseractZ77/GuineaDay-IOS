import SwiftUI

// MARK: - Game State (Observable class — safe for background updates)

@Observable
final class FlyingPigGameState {

    struct Pig: Identifiable {
        let id: Int
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        let imageName: String  // Asset catalog name
        let name: String
    }

    struct Food: Identifiable {
        let id: Int
        let emoji: String
        let name: String
        var x: CGFloat
        var y: CGFloat
    }

    static let pigImageNames = ["hachi", "kui", "nova", "elmo", "mel", "haru", "seven"]
    static let pigNames  = ["Hachi","Kui","Nova","Elmo","Mel","Haru","Seven"]
    static let foodDefs: [(emoji: String, name: String)] = [
        ("🥕","Carrot"),("🥬","Lettuce"),("🍎","Apple"),
        ("🍓","Strawberry"),("🥒","Cucumber"),("🍇","Grapes"),("🍉","Watermelon")
    ]

    var pigs: [Pig] = []
    var foods: [Food] = []
    var selectedPigId: Int? = nil
    var score: Int = 0
    var toastInfo: (pigName: String, foodEmoji: String, foodName: String)? = nil
    var showToast: Bool = false

    let pigSize: CGFloat = 70
    let foodSize: CGFloat = 50
    let feedThreshold: CGFloat = 65

    var containerSize: CGSize = .zero
    private var lastTick: Date? = nil

    func setup(in size: CGSize) {
        guard size.width > 10, size.height > 10 else { return } // skip truly zero sizes
        containerSize = size
        lastTick = nil
        score = 0
        toastInfo = nil
        showToast = false
        selectedPigId = nil

        let pad: CGFloat = 80
        let maxX = max(0, size.width  - pad * 2 - pigSize)
        let maxY = max(0, size.height - pad * 2 - pigSize)
        let foodMaxX = max(0, size.width  - 120)
        let foodMaxY = max(0, size.height - 120)

        pigs = (0..<7).map { i in
            Pig(
                id: i,
                x: pad + CGFloat.random(in: 0...maxX),
                y: pad + CGFloat.random(in: 0...maxY),
                vx: randomVelocity(),
                vy: randomVelocity(),
                imageName: FlyingPigGameState.pigImageNames[i],
                name: FlyingPigGameState.pigNames[i]
            )
        }

        foods = FlyingPigGameState.foodDefs.enumerated().map { i, f in
            Food(
                id: i, emoji: f.emoji, name: f.name,
                x: 40 + CGFloat.random(in: 0...foodMaxX),
                y: 40 + CGFloat.random(in: 0...foodMaxY)
            )
        }
    }

    func tick(now: Date) {
        guard containerSize.width > 0 else { return }
        let size = containerSize

        pigs = pigs.map { pig in
            guard pig.id != selectedPigId else { return pig }
            var p = pig
            p.x += p.vx; p.y += p.vy

            // Bounce
            if p.x < 0 || p.x > size.width - pigSize  { p.vx = -p.vx * 0.9; p.x = p.x.clamped(0, size.width - pigSize) }
            if p.y < 0 || p.y > size.height - pigSize  { p.vy = -p.vy * 0.9; p.y = p.y.clamped(0, size.height - pigSize) }

            // Random nudge
            p.vx += CGFloat.random(in: -0.15...0.15)
            p.vy += CGFloat.random(in: -0.15...0.15)

            // Clamp speed
            let spd = sqrt(p.vx*p.vx + p.vy*p.vy)
            let max: CGFloat = 3.5
            if spd > max { p.vx = p.vx/spd*max; p.vy = p.vy/spd*max }
            return p
        }
    }

    func grab(at point: CGPoint) {
        for pig in pigs {
            if point.x >= pig.x && point.x <= pig.x + pigSize &&
               point.y >= pig.y && point.y <= pig.y + pigSize {
                selectedPigId = pig.id
                return
            }
        }
    }

    func drag(pigId: Int, to point: CGPoint) {
        guard let idx = pigs.firstIndex(where: { $0.id == pigId }) else { return }
        pigs[idx].x = point.x - pigSize/2
        pigs[idx].y = point.y - pigSize/2
        pigs[idx].vx = 0; pigs[idx].vy = 0
    }

    func release() {
        guard let id = selectedPigId,
              let pig = pigs.first(where: { $0.id == id }) else {
            selectedPigId = nil; return
        }
        for i in foods.indices {
            let food = foods[i]
            let dx = (pig.x + pigSize/2) - (food.x + foodSize/2)
            let dy = (pig.y + pigSize/2) - (food.y + foodSize/2)
            if sqrt(dx*dx + dy*dy) < feedThreshold {
                // Score!
                score += 1
                toastInfo = (pigName: pig.name, foodEmoji: food.emoji, foodName: food.name)
                showToast = true
                // Respawn this food at a new random position
                let w = containerSize.width, h = containerSize.height
                foods[i].x = 40 + CGFloat.random(in: 0...max(0, w - 120))
                foods[i].y = 40 + CGFloat.random(in: 0...max(0, h - 120))
                // Give pig a bounce
                if let idx = pigs.firstIndex(where: { $0.id == id }) {
                    pigs[idx].vx = randomVelocity()
                    pigs[idx].vy = randomVelocity()
                }
                selectedPigId = nil
                return
            }
        }
        if let idx = pigs.firstIndex(where: { $0.id == id }) {
            pigs[idx].vx = randomVelocity()
            pigs[idx].vy = randomVelocity()
        }
        selectedPigId = nil
    }

    private func randomVelocity() -> CGFloat {
        var v = CGFloat.random(in: -2.5...2.5)
        if abs(v) < 0.5 { v = v < 0 ? -1.5 : 1.5 }
        return v
    }
}

extension CGFloat {
    func clamped(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat { Swift.max(lo, Swift.min(hi, self)) }
}

// MARK: - Main View

struct GameContainerView: View {
    @State private var game = FlyingPigGameState()
    @State private var useCameraControls = false
    @State private var handCursor: CGPoint? = nil
    @State private var isHandGrabbing = false
    @State private var lastGrabState = false


    var body: some View {
        NavigationStack {
            ZStack {
                Color.wallGray.ignoresSafeArea()
                VStack(spacing: 0) {
                    headerBar
                    instructionText
                    gameCanvas
                        .padding(.horizontal, 16)
                        .padding(.bottom, 70)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: Header

    var headerBar: some View {
        
        HStack(spacing: 10) {

            Text("🐹 Flying Piggy")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkBrown)
                .lineLimit(1)
            Spacer()
            // Score badge
            HStack(spacing: 4) {
                Text("🫘")
                Text("\(game.score)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkBrown)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: game.score)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.usagiYellow)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.inkBrown, lineWidth: 2))

//            HStack(spacing: 1) {
//                Text("🖐️")
//                    .font(.system(size: 16))
//                Toggle("", isOn: $useCameraControls)
//                    .labelsHidden()
//                    .tint(Color.hachiwareBlue)
//                    .scaleEffect(0.8)
//            }

            }
        
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
    

    var instructionText: some View {
        Text(useCameraControls
             ? "✊ Grab a piggy, open hand to drop on food!"
             : "👆 Drag a piggy onto food to feed it!")
            .font(.caption)
            .foregroundStyle(Color.inkBrown.opacity(0.7))
            .padding(.bottom, 8)
    }

    // MARK: Game Canvas

    var gameCanvas: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0/60.0)) { timeline in
                ZStack {
                    gameBackground
                    foodLayer
                    pigLayer
                    if useCameraControls, let cursor = handCursor {
                        Text(isHandGrabbing ? "✊" : "🖐️")
                            .font(.system(size: 36))
                            .position(cursor)
                            .allowsHitTesting(false)
                    }
                    // +1 toast
                    if game.showToast, let toast = game.toastInfo {
                        toastView(toast: toast)
                    }
                }
                .onChange(of: timeline.date) { _, now in
                    game.tick(now: now)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.inkBrown, lineWidth: 3))
            .shadow(color: Color.inkBrown.opacity(0.4), radius: 0, x: 3, y: 5)
            .onAppear { game.setup(in: geo.size) }
            .onChange(of: geo.size) { _, s in
                // Re-run setup if pigs were never created (onAppear fired with size=0)
                if game.pigs.isEmpty {
                    game.setup(in: s)
                } else {
                    game.containerSize = s
                }
            }
            .overlay {
                if useCameraControls {
                    HandPoseCameraView { pos, isGrabbing in
                        let pt = CGPoint(x: pos.x * geo.size.width, y: (1 - pos.y) * geo.size.height)
                        handCursor = pt
                        isHandGrabbing = isGrabbing
                        handleHand(at: pt, isGrabbing: isGrabbing)
                    }
                    .opacity(0)
                    .allowsHitTesting(false)
                }
            }
        }
    }

    var gameBackground: some View {
        LinearGradient(
            colors: [Color.hachiwareBlue.opacity(0.25), Color.usagiYellow.opacity(0.15)],
            startPoint: .top, endPoint: .bottom
        )
    }

    var foodLayer: some View {
        ForEach(game.foods) { food in
            Text(food.emoji)
                .font(.system(size: 42))
                .shadow(radius: 3)
                .position(x: food.x + game.foodSize/2, y: food.y + game.foodSize/2)
        }
    }

    var pigLayer: some View {
        ForEach(game.pigs) { pig in
            let isSelected = game.selectedPigId == pig.id
            ZStack {
                Image(pig.imageName)
                    .resizable()
                    .scaledToFit()
                    .shadow(color: Color.inkBrown.opacity(0.4), radius: 4, x: 2, y: 3)
                    .scaleEffect(pig.vx < 0
                        ? CGSize(width: -1, height: 1)
                        : CGSize(width: 1, height: 1))
                if isSelected {
                    Text(pig.name)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.inkBrown)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.chiikawaWhite)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.inkBrown, lineWidth: 1))
                        .offset(y: -42)
                }
            }
            .frame(width: game.pigSize, height: game.pigSize)
            .scaleEffect(isSelected ? 1.15 : 1.0)
            .position(x: pig.x + game.pigSize/2, y: pig.y + game.pigSize/2)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        guard !useCameraControls else { return }
                        if game.selectedPigId == nil { game.grab(at: val.startLocation) }
                        if game.selectedPigId == pig.id { game.drag(pigId: pig.id, to: val.location) }
                    }
                    .onEnded { _ in
                        guard !useCameraControls else { return }
                        game.release()
                    }
            )
            .animation(.spring(response: 0.2), value: isSelected)
        }
    }

    @ViewBuilder
    func toastView(toast: (pigName: String, foodEmoji: String, foodName: String)) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Text("\(toast.foodEmoji) +1")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("\(toast.pigName) loves \(toast.foodName)!")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .foregroundColor(Color.inkBrown)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.usagiYellow)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.inkBrown, lineWidth: 2))
            .shadow(color: Color.inkBrown.opacity(0.3), radius: 0, x: 2, y: 3)
            .padding(.bottom, 40)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation { game.showToast = false }
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: Hand Tracking

    func handleHand(at point: CGPoint, isGrabbing: Bool) {
        if isGrabbing && !lastGrabState { game.grab(at: point) }
        if isGrabbing, let id = game.selectedPigId { game.drag(pigId: id, to: point) }
        if !isGrabbing && lastGrabState && game.selectedPigId != nil { game.release() }
        lastGrabState = isGrabbing
    }
}

// Preview intentionally removed — AVFoundation camera access crashes the Preview sandbox.
