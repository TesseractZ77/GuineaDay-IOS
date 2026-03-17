import SwiftUI

// MARK: - Maze Cell
private struct MCell {
    var top    = true
    var right  = true
    var bottom = true
    var left   = true
    var visited = false
}

// MARK: - Recursive Backtracking Maze Generator
private func buildMaze(rows: Int, cols: Int) -> [[MCell]] {
    var g = Array(repeating: Array(repeating: MCell(), count: cols), count: rows)

    func dfs(_ r: Int, _ c: Int) {
        g[r][c].visited = true
        for (dr, dc) in [(0,1),(1,0),(0,-1),(-1,0)].shuffled() {
            let nr = r+dr, nc = c+dc
            guard nr >= 0, nr < rows, nc >= 0, nc < cols, !g[nr][nc].visited else { continue }
            if dc ==  1 { g[r][c].right  = false; g[nr][nc].left   = false }
            if dc == -1 { g[r][c].left   = false; g[nr][nc].right  = false }
            if dr ==  1 { g[r][c].bottom = false; g[nr][nc].top    = false }
            if dr == -1 { g[r][c].top    = false; g[nr][nc].bottom = false }
            dfs(nr, nc)
        }
    }

    dfs(0, 0)
    return g
}

// MARK: - Maze Game View
struct MazeGameView: View {
    private let rows = 11, cols = 7
    private let pigImageNames  = ["hachi","kui","nova","elmo","mel","haru","seven"]
    private let pigDisplayNames = ["Hachi","Kui","Nova","Elmo","Mel","Haru","Seven"]

    @State private var selectedPig: String? = nil
    @State private var maze: [[MCell]] = []
    @State private var playerRow = 0
    @State private var playerCol = 0
    @State private var moveCount = 0
    @State private var showWin   = false
    @State private var pigScale: CGFloat = 1.0  // shrink on wall hit

    var body: some View {
        ZStack {
            Color.wallGray.ignoresSafeArea()
            if selectedPig == nil {
                pickerView
            } else {
                GeometryReader { geo in gameView(geo: geo) }
            }
        }
    }

    // MARK: - Pig Picker
    var pickerView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Back button
                // Nav-style header — replaces both the HStack back button AND the title VStack
                HStack {

                    Spacer()

                    VStack(spacing: 2) {
                        Text("🌀 Guinea Maze")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(Color.inkBrown)
                        Text("Pick your adventurer!")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(Color.inkBrown.opacity(0.5))
                    }

                    Spacer()

                    // Mirror spacer so title stays centered
                    Color.clear.frame(width: 36, height: 36)
                }
                //.padding(.horizontal, 16)
                .padding(.top, 20)


                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 16) {
                    ForEach(pigImageNames.indices, id: \.self) { i in
                        VStack(spacing: 6) {
                            Image(pigImageNames[i])
                                .resizable().scaledToFit()
                                .frame(width: 68, height: 68)
                                .padding(10)
                                .chiikawaCard(color: Color.mintGreen, radius: 18)
                                .onTapGesture { startGame(pigImageNames[i]) }
                            Text(pigDisplayNames[i])
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Color.inkBrown)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer().frame(height: 90) // tab bar clearance
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Game View
    func gameView(geo: GeometryProxy) -> some View {
        let cw = geo.size.width - 32
        let cs = floor(cw / CGFloat(cols))
        let ch = cs * CGFloat(rows)

        return VStack(spacing: 8) {
            // Header
            HStack(spacing: 10) {
                if let pig = selectedPig {
                    Image(pig)
                        .resizable().scaledToFit()
                        .frame(width: 34, height: 34)
                        .padding(4)
                        .chiikawaCard(color: Color.usagiYellow, radius: 10)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("🌀 Guinea Maze")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(Color.inkBrown)
//                    Text("\(moveCount) step\(moveCount == 1 ? "" : "s")")
//                        .font(.system(size: 11, design: .rounded))
//                        .foregroundColor(Color.inkBrown.opacity(0.5))
                }
                Spacer()
                // New maze
                Button { startGame(selectedPig!) } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.inkBrown)
                        .frame(width: 34, height: 34)
                        .background(Color.usagiYellow)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.inkBrown, lineWidth: 2))
                        .shadow(color: Color.inkBrown.opacity(0.3), radius: 0, x: 1, y: 2)
                }
                .buttonStyle(.plain)
                // Change pig / back
                Button { selectedPig = nil } label: {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color.blushPink)
                        .overlay(Circle().stroke(Color.inkBrown, lineWidth: 2))
                        .shadow(color: Color.inkBrown.opacity(0.3), radius: 0, x: 1, y: 2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Text("👆 Swipe to navigate to the 🍓")
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(Color.inkBrown.opacity(0.4))

            // Maze canvas
            ZStack {
                // Walls drawn via Canvas
                Canvas { ctx, size in drawMaze(ctx, size) }

                // Exit strawberry
                Text("🍓")
                    .font(.system(size: cs * 0.65))
                    .position(x: CGFloat(cols-1)*cs + cs/2,
                              y: CGFloat(rows-1)*cs + cs/2)
                    .frame(width: cw, height: ch, alignment: .topLeading)

                // Player pig
                if let pig = selectedPig {
                    Image(pig)
                        .resizable().scaledToFit()
                        .frame(width: cs * 0.9, height: cs * 0.9)
                        .scaleEffect(pigScale)
                        .position(x: CGFloat(playerCol)*cs + cs/2,
                                  y: CGFloat(playerRow)*cs + cs/2)
                        .frame(width: cw, height: ch, alignment: .topLeading)
                        .animation(.spring(response: 0.18, dampingFraction: 0.65), value: playerRow)
                        .animation(.spring(response: 0.18, dampingFraction: 0.65), value: playerCol)
                }

                // Win overlay
                if showWin { winOverlay }
            }
            .frame(width: cw, height: ch)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.inkBrown, lineWidth: 3))
            .shadow(color: Color.inkBrown.opacity(0.45), radius: 0, x: 3, y: 4)
            .background(Color.chiikawaWhite.clipShape(RoundedRectangle(cornerRadius: 20)))
            .gesture(DragGesture(minimumDistance: 18).onEnded(handleSwipe))
            // Step counter below maze
            HStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .foregroundColor(Color.inkBrown)
                Text("\(moveCount) step\(moveCount == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color.inkBrown)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .chiikawaCard(color: Color.usagiYellow, radius: 16)
            .padding(.top,12)


            Spacer()
                .frame(height: 90) // tab bar clearance
        }
    }

    // MARK: - Win Overlay
    var winOverlay: some View {
        ZStack {
            Color.inkBrown.opacity(0.5)
            VStack(spacing: 14) {
                Text("🎉").font(.system(size: 54))
                Text("You made it!")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("Finished in \(moveCount) steps")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                HStack(spacing: 12) {
                    Button("New Maze") { startGame(selectedPig!) }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.inkBrown)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Color.usagiYellow)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.inkBrown, lineWidth: 2))
                    Button("Change Pig") { selectedPig = nil }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.inkBrown)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Color.blushPink)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.inkBrown, lineWidth: 2))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .transition(.opacity)
    }

    // MARK: - Canvas Drawing
    func drawMaze(_ ctx: GraphicsContext, _ size: CGSize) {
        guard !maze.isEmpty else { return }
        let cw = size.width / CGFloat(cols)
        let ch = size.height / CGFloat(rows)
        let ink = GraphicsContext.Shading.color(Color.inkBrown)

        // Checkerboard floor
        for r in 0..<rows {
            for c in 0..<cols {
                let bg = (r + c) % 2 == 0 ? Color.chiikawaWhite : Color.wallGray.opacity(0.6)
                //let bg = (r + c) % 2 == 0 ? Color.mintGreen.opacity(0.2) : Color.blushPink.opacity(0.15)

                //let bg = (r + c) % 2 == 0 ? Color.usagiYellow.opacity(0.3) : Color.hachiwareBlue.opacity(0.15)

                var p = Path()
                p.addRect(CGRect(x: CGFloat(c)*cw, y: CGFloat(r)*ch, width: cw, height: ch))
                ctx.fill(p, with: .color(bg))
            }
        }

        // Highlight exit cell
        var exitP = Path()
        exitP.addRoundedRect(
            in: CGRect(x: CGFloat(cols-1)*cw+2, y: CGFloat(rows-1)*ch+2, width: cw-4, height: ch-4),
            cornerSize: CGSize(width: 6, height: 6))
        ctx.fill(exitP, with: .color(Color.mintGreen.opacity(0.35)))

        // Draw walls
        for r in 0..<rows {
            for c in 0..<cols {
                let x = CGFloat(c)*cw, y = CGFloat(r)*ch
                let cell = maze[r][c]
                var p = Path()
                if cell.top    { p.move(to: .init(x: x,    y: y));    p.addLine(to: .init(x: x+cw, y: y)) }
                if cell.right  { p.move(to: .init(x: x+cw, y: y));    p.addLine(to: .init(x: x+cw, y: y+ch)) }
                if cell.bottom { p.move(to: .init(x: x,    y: y+ch)); p.addLine(to: .init(x: x+cw, y: y+ch)) }
                if cell.left   { p.move(to: .init(x: x,    y: y));    p.addLine(to: .init(x: x,    y: y+ch)) }
                ctx.stroke(p, with: ink, lineWidth: 2.5)
            }
        }
    }

    // MARK: - Swipe
    func handleSwipe(_ val: DragGesture.Value) {
        guard !showWin, !maze.isEmpty else { return }
        let h = val.translation.height, w = val.translation.width
        let (dr, dc): (Int, Int) = abs(h) > abs(w)
            ? (h < 0 ? (-1,0) : (1,0))
            : (w < 0 ? (0,-1) : (0,1))
        let nr = playerRow + dr, nc = playerCol + dc
        guard nr >= 0, nr < rows, nc >= 0, nc < cols else { return }

        let cell = maze[playerRow][playerCol]
        let blocked = (dr == -1 && cell.top)    || (dr == 1 && cell.bottom)
                   || (dc == -1 && cell.left)   || (dc == 1 && cell.right)

        if blocked {
            // Bounce animation on wall hit
            withAnimation(.easeOut(duration: 0.1)) { pigScale = 0.75 }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4).delay(0.1)) { pigScale = 1.0 }
        } else {
            playerRow = nr
            playerCol = nc
            moveCount += 1
            if nr == rows-1 && nc == cols-1 {
                withAnimation(.easeIn(duration: 0.3)) { showWin = true }
            }
        }
    }

    // MARK: - Setup
    func startGame(_ pig: String) {
        maze = buildMaze(rows: rows, cols: cols)
        playerRow = 0; playerCol = 0; moveCount = 0; showWin = false
        selectedPig = pig
    }
}
