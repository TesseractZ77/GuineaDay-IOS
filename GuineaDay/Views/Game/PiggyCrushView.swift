import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Models

private struct GridPos: Hashable {
    let row, col: Int
}

private struct PigTile: Identifiable {
    let id = UUID()
    var pig: String
}

// MARK: - Constants

private let pigTypes   = ["hachi", "kui", "nova", "elmo", "mel", "haru","seven"]  // 7 pig types
private let gridRows   = 11
private let gridCols   = 7
private let totalMoves = 30

// MARK: - Main View

struct PiggyCrushView: View {
    @Binding var selectedTab: AppTab

    @State private var grid: [[PigTile]] = []
    @State private var selected: GridPos? = nil
    @State private var matchedPos: Set<GridPos> = []
    @State private var score = 0
    @State private var movesLeft = totalMoves
    @State private var isAnimating = false
    @State private var gameOver = false
    @State private var combo = 0          // chain reaction counter
    @State private var lastComboScore = 0 // shown in combo flash
    @AppStorage("pcBestScore") private var bestScore: Int = 0
    @EnvironmentObject var firestore: FirestoreService
    @State private var householdScores: [String: Int] = [:]   // uid → score
    @State private var scoresListener: ListenerRegistration?



    // Cell size fills screen minus padding
    private var cellSize: CGFloat {
        (UIScreen.main.bounds.width - 48) / CGFloat(gridCols)
    }

    var body: some View {
        ZStack {
            Color.wallGray.ignoresSafeArea()

            if gameOver {
                gameOverOverlay
            } else if grid.isEmpty {
                ProgressView()
                    .tint(Color.inkBrown)
            } else {
                VStack(spacing: 8) {
                    headerView
                    hintText
                    if combo > 1 {
                        Text("🔥 Combo ×\(combo)! +\(lastComboScore)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(Color.blushPink)
                            .transition(.scale.combined(with: .opacity))
                    }
                    gridView
                    let householdBest = householdScores.values.max() ?? bestScore
                    Text("🏆 Best: \(householdBest)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color.inkBrown.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 16)

                    Spacer()
                }
            }
        }
        .onAppear {
            initGrid()
            // Start listening to household scores
            scoresListener = firestore.listenToScores { scores in
                householdScores = scores
            }
            // Push your current best score on appear
            if bestScore > 0, let uid = Auth.auth().currentUser?.uid {
                Task { try? await firestore.saveScore(playerUid: uid, game: "piggyCrush", score: bestScore) }
            }
        }
        .onDisappear {
            scoresListener?.remove()
        }
        .animation(.spring(response: 0.25), value: combo)
    }


    // MARK: - Header

    var headerView: some View {
        ZStack {
            Text("🐹 Piggy Crush")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(Color.inkBrown)
            HStack {
                // Score capsule
                HStack(spacing: 4) {
                    Text("⭐️")
                    Text("\(score)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color.inkBrown)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: score)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.usagiYellow)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.inkBrown, lineWidth: 2))

                Spacer()

                // Moves capsule
                HStack(spacing: 4) {
                    Text("👾")
                    Text("\(movesLeft)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(movesLeft <= 5 ? Color.blushPink : Color.inkBrown)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: movesLeft)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(movesLeft <= 5 ? Color.blushPink.opacity(0.15) : Color.chiikawaWhite)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(movesLeft <= 5 ? Color.blushPink : Color.inkBrown, lineWidth: 2))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    var hintText: some View {
        Text(selected == nil
             ? "Tap a piggy to select  🐾"
             : "Tap an adjacent piggy to swap!")
            .font(.system(size: 11, design: .rounded))
            .foregroundColor(Color.inkBrown.opacity(0.45))
    }

    // MARK: - Grid

    var gridView: some View {
        VStack(spacing: 3) {
            ForEach(0..<gridRows, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<gridCols, id: \.self) { col in
                        tileCell(row: row, col: col)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(hex: "C8E6A0").opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.inkBrown, lineWidth: 3))
        .shadow(color: Color.inkBrown.opacity(0.18), radius: 6, x: 0, y: 3)
        .padding(.horizontal, 12)
    }

    func tileCell(row: Int, col: Int) -> some View {
        let tile     = grid[row][col]
        let pos      = GridPos(row: row, col: col)
        let isSel    = selected == pos
        let isMatch  = matchedPos.contains(pos)

        return Button { handleTap(pos: pos) } label: {
            Image(tile.pig)
                .resizable()
                .scaledToFit()
                .frame(width: cellSize - 8, height: cellSize - 8)
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSel
                              ? Color.usagiYellow.opacity(0.75)
                              : Color.chiikawaWhite.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSel ? Color.inkBrown : Color.inkBrown.opacity(0.15),
                                lineWidth: isSel ? 2.5 : 1)
                )
                .scaleEffect(isSel ? 1.15 : (isMatch ? 1.3 : 1.0))
                .opacity(isMatch ? 0.0 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.55), value: isSel)
                .animation(.easeOut(duration: 0.2), value: isMatch)
        }
        .buttonStyle(.plain)
        .disabled(isAnimating)
    }

    // MARK: - Game Over Overlay

    var gameOverOverlay: some View {
        VStack(spacing: 24) {
            Text("🐹 Time's Up!")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(Color.inkBrown)
            VStack(spacing: 6) {
                Text("Final Score")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color.inkBrown.opacity(0.5))
                Text("⭐️ \(score)")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(Color.inkBrown)
            }
            .padding(.vertical, 16).padding(.horizontal, 36)
            .background(Color.usagiYellow.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.inkBrown, lineWidth: 2))

            // Two action buttons: Retry + Home
            HStack(spacing: 24) {
                // Retry
                Button {
                    let finalScore = score
                    if finalScore > bestScore {
                        bestScore = finalScore
                        if let uid = Auth.auth().currentUser?.uid {
                            Task { try? await firestore.saveScore(playerUid: uid, game: "piggyCrush", score: finalScore) }
                        }
                    }
                    score = 0; movesLeft = totalMoves; combo = 0
                    gameOver = false; matchedPos = []; selected = nil
                    initGrid()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 26, weight: .black))
                        Text("Retry")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(Color.inkBrown)
                    .frame(width: 80, height: 70)
                    .chiikawaCard(color: Color.mintGreen, radius: 20)
                }
                .buttonStyle(.plain)

                // Home
                Button {
                    let finalScore = score
                    if finalScore > bestScore {
                        bestScore = finalScore
                        if let uid = Auth.auth().currentUser?.uid {
                            Task { try? await firestore.saveScore(playerUid: uid, game: "piggyCrush", score: finalScore) }
                        }
                    }
                    score = 0; movesLeft = totalMoves; combo = 0
                    gameOver = false; matchedPos = []; selected = nil
                    initGrid()
                    selectedTab = .home
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 26, weight: .black))
                        Text("Home")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(Color.inkBrown)
                    .frame(width: 80, height: 70)
                    .chiikawaCard(color: Color.usagiYellow, radius: 20)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(32)
        .background(Color.chiikawaWhite)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.inkBrown, lineWidth: 3))
        .shadow(color: Color.inkBrown.opacity(0.25), radius: 10, x: 0, y: 5)
        .padding(24)
    }

    // MARK: - Game Logic

    /// Build a starting grid with no pre-existing matches.
    func initGrid() {
        var g: [[PigTile]] = []
        for r in 0..<gridRows {
            var row: [PigTile] = []
            for c in 0..<gridCols {
                var pig: String
                repeat {
                    pig = pigTypes.randomElement()!
                } while (c >= 2 && row[c-1].pig == pig && row[c-2].pig == pig)
                           || (r >= 2 && g[r-1][c].pig == pig && g[r-2][c].pig == pig)
                row.append(PigTile(pig: pig))
            }
            g.append(row)
        }
        grid = g
    }

    private func handleTap(pos: GridPos) {
        guard !isAnimating else { return }

        if let sel = selected {
            guard sel != pos else { selected = nil; return }

            let adjacent = (abs(sel.row - pos.row) == 1 && sel.col == pos.col)
                        || (abs(sel.col - pos.col) == 1 && sel.row == pos.row)

            if adjacent {
                selected = nil
                attemptSwap(from: sel, to: pos)
            } else {
                selected = pos   // re-select a different tile
            }
        } else {
            selected = pos
        }
    }

    private func attemptSwap(from: GridPos, to: GridPos) {
        isAnimating = true
        combo = 0

        // Swap
        let tmp = grid[from.row][from.col]
        grid[from.row][from.col] = grid[to.row][to.col]
        grid[to.row][to.col] = tmp

        let matches = findMatches()
        if matches.isEmpty {
            // Invalid — reverse after a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                let t2 = grid[from.row][from.col]
                grid[from.row][from.col] = grid[to.row][to.col]
                grid[to.row][to.col] = t2
                isAnimating = false
            }
        } else {
            movesLeft -= 1
            processMatches(matches, chainDepth: 1)
        }
    }

    private func findMatches() -> Set<GridPos> {
        var matched: Set<GridPos> = []

        // Horizontal
        for r in 0..<gridRows {
            var c = 0
            while c < gridCols - 2 {
                let pig = grid[r][c].pig
                if grid[r][c+1].pig == pig && grid[r][c+2].pig == pig {
                    var end = c + 2
                    while end + 1 < gridCols && grid[r][end+1].pig == pig { end += 1 }
                    for i in c...end { matched.insert(GridPos(row: r, col: i)) }
                    c = end + 1
                } else { c += 1 }
            }
        }

        // Vertical
        for c in 0..<gridCols {
            var r = 0
            while r < gridRows - 2 {
                let pig = grid[r][c].pig
                if grid[r+1][c].pig == pig && grid[r+2][c].pig == pig {
                    var end = r + 2
                    while end + 1 < gridRows && grid[end+1][c].pig == pig { end += 1 }
                    for i in r...end { matched.insert(GridPos(row: i, col: c)) }
                    r = end + 1
                } else { r += 1 }
            }
        }

        return matched
    }

    private func processMatches(_ matches: Set<GridPos>, chainDepth: Int) {
        combo = chainDepth
        let pts = matches.count * 10 * chainDepth   // bonus for combo chains
        lastComboScore = pts
        matchedPos = matches
        score += pts

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            matchedPos = []
            withAnimation(.easeIn(duration: 0.18)) {
                dropTiles(removing: matches)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let next = findMatches()
                if next.isEmpty {
                    isAnimating = false
                    combo = 0
                    if movesLeft <= 0 { gameOver = true }
                } else {
                    processMatches(next, chainDepth: chainDepth + 1)
                }
            }
        }
    }

    /// Remove matched tiles and gravity-drop remaining tiles down; fill top with new tiles.
    private func dropTiles(removing matched: Set<GridPos>) {
        for c in 0..<gridCols {
            var remaining: [PigTile] = []
            for r in 0..<gridRows {
                if !matched.contains(GridPos(row: r, col: c)) {
                    remaining.append(grid[r][c])
                }
            }
            let newCount = gridRows - remaining.count
            let newTiles = (0..<newCount).map { _ in PigTile(pig: pigTypes.randomElement()!) }
            let col = newTiles + remaining   // new tiles fill from top
            for r in 0..<gridRows { grid[r][c] = col[r] }
        }
    }
}
#Preview { PiggyCrushView(selectedTab: .constant(.game)) }
