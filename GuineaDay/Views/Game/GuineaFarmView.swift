import SwiftUI

// MARK: - Data Models

private enum CropStage: String, Codable {
    case empty, seeded, growing, ready
}

private struct FarmPlot: Codable, Identifiable {
    let id: Int
    var stage: CropStage  = .empty
    var cropType: Int     = 0
    var plantedAt: Date?  = nil
    var wateredAt: Date?  = nil   // time of watering (2× speed after this)
    var farmedBy: String? = nil   // which pig planted it (gets leaderboard credit)
}

// MARK: - Constants

private let crops            = ["🥕", "🍓", "🥬", "🍇", "🍎", "🥒"]
private let seedTime: Double = 180   // seconds seed → growing
private let growTime: Double = 360   // seconds growing → ready
private let totalTime: Double = seedTime + growTime
private let gridCols         = 5
private let gridRows         = 6
private let maxDailyWaters   = 5    // per pig

// MARK: - Main View

struct GuineaFarmView: View {
    private let pigNames  = ["hachi","kui","nova","elmo","mel","haru","seven"]
    private let pigLabels = ["Hachi","Kui","Nova","Elmo","Mel","Haru","Seven"]

    @State private var selectedPigs: [String]    = []
    @State private var plots: [FarmPlot]         = (0..<gridCols*gridRows).map { FarmPlot(id: $0) }
    @State private var score: Int                = 0
    @State private var showPicker: Bool          = true
    @State private var now: Date                 = Date()
    @State private var harvestCounts: [String: Int] = [:]
    @State private var wateringPig: String?      = nil     // currently selected pig for watering
    @State private var watersLeft: [String: Int] = [:]     // pig → waters remaining today

    // Persistence
    @AppStorage("gfPlots")      private var plotsData:    Data   = Data()
    @AppStorage("gfScore")      private var savedScore:   Int    = 0
    @AppStorage("gfPigs")       private var savedPigs:    String = ""
    @AppStorage("gfHarvests")   private var harvestData:  Data   = Data()
    @AppStorage("gfWaters")     private var watersData:   Data   = Data()
    @AppStorage("gfWaterDate")  private var waterDateStr: String = ""
    @AppStorage("gfGoalProg")   private var goalProgress: Int    = 0
    @AppStorage("gfGoalDate")   private var goalDateStr:  String = ""
    @AppStorage("gfScoreDate")  private var scoreDateStr: String = ""

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Daily goal: deterministic from day-of-year
    private var dailyGoal: (crop: String, count: Int) {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return (crops[day % crops.count], 3 + (day % 3))
    }
    private var todayStr: String {
        DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
    }
    private var goalIsToday: Bool { goalDateStr == todayStr }
    private var todayGoalProgress: Int { goalIsToday ? goalProgress : 0 }

    var body: some View {
        ZStack {
            Color.wallGray.ignoresSafeArea()
            if showPicker { pickerView } else { farmView }
        }
        .onReceive(clock) { now = $0 }
        .onAppear(perform: loadState)
    }

    // MARK: - Pig Picker

    var pickerView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("🌾 Guinea Farm")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(Color.inkBrown)
                    Text("Pick 3 farmers to tend the land!")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(Color.inkBrown.opacity(0.5))
                }
                .padding(.top, 40)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 16) {
                    ForEach(pigNames.indices, id: \.self) { i in
                        let pig = pigNames[i]
                        let isSelected = selectedPigs.contains(pig)
                        VStack(spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                Image(pig)
                                    .resizable().scaledToFit()
                                    .frame(width: 68, height: 68)
                                    .padding(10)
                                    .background(isSelected ? Color.mintGreen : Color.chiikawaWhite)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.inkBrown, lineWidth: isSelected ? 3 : 1.5)
                                    )
                                if let idx = selectedPigs.firstIndex(of: pig) {
                                    Text("\(idx + 1)")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(Color.blushPink)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                                        .offset(x: 4, y: -4)
                                }
                            }
                            .onTapGesture {
                                if isSelected {
                                    selectedPigs.removeAll { $0 == pig }
                                } else if selectedPigs.count < 3 {
                                    selectedPigs.append(pig)
                                }
                            }
                            Text(pigLabels[pigNames.firstIndex(of: pig) ?? 0])
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Color.inkBrown)
                        }
                    }
                }
                .padding(.horizontal, 16)

                if selectedPigs.count == 3 {
                    Button {
                        savedPigs = selectedPigs.joined(separator: ",")
                        showPicker = false
                    } label: {
                        Text("🌾 Start Farming!")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(Color.inkBrown)
                            .padding(.horizontal, 32).padding(.vertical, 14)
                            .chiikawaCard(color: Color.mintGreen, radius: 24)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(), value: selectedPigs.count)
                }

                Spacer().frame(height: 90)
            }
        }
    }

    // MARK: - Farm View

    var farmView: some View {
        VStack(spacing: 8) {
            // Header
            ZStack {
                Text("🌾 Guinea Farm")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(Color.inkBrown)
                HStack {
                    HStack(spacing: -8) {
                        ForEach(selectedPigs, id: \.self) { pig in
                            pigAvatarButton(pig: pig)
                        }
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Text("⭐️")
                        Text("\(score)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color.inkBrown)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: score)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.usagiYellow)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.inkBrown, lineWidth: 2))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Watering prompt
            if wateringPig != nil {
                Text("💧 Tap any growing plot to water it!")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color.hachiwareBlue)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Color.hachiwareBlue.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Daily goal
            dailyGoalBanner

            // Farm grid
            let cols = Array(repeating: GridItem(.flexible(), spacing: 4), count: gridCols)
            ScrollView {
                LazyVGrid(columns: cols, spacing: 4) {
                    ForEach($plots) { $plot in
                        PlotCellView(
                            plot: $plot,
                            now: now,
                            isWateringMode: wateringPig != nil,
                            onTap: { handleTap(plot: &$plot.wrappedValue) }
                        )
                    }
                }
                .padding(12)
                .background(Color(hex: "A8D87A").opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.inkBrown, lineWidth: 3))
                .shadow(color: Color.inkBrown.opacity(0.15), radius: 5, x: 0, y: 3)

                // Leaderboard
                leaderboardView
                    .padding(.top, 8)

                // Change farmers
                Button { showPicker = true } label: {
                    Label("Change Farmers", systemImage: "person.2.circle")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color.inkBrown)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Color.chiikawaWhite)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.inkBrown, lineWidth: 2))
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)

                Spacer().frame(height: 90)
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Pig Avatar (watering button)

    func pigAvatarButton(pig: String) -> some View {
        let isActive = wateringPig == pig
        let left = watersLeft[pig] ?? maxDailyWaters
        return ZStack(alignment: .bottomTrailing) {
            Image(pig)
                .resizable().scaledToFit()
                .frame(width: 36, height: 36)
                .padding(3)
                .background(isActive ? Color.hachiwareBlue.opacity(0.25) : Color.chiikawaWhite)
                .clipShape(Circle())
                .overlay(Circle().stroke(isActive ? Color.hachiwareBlue : Color.inkBrown,
                                         lineWidth: isActive ? 3 : 2))
                .shadow(color: isActive ? Color.hachiwareBlue.opacity(0.4) : .clear, radius: 5)
            // Water count badge
            Text("💧\(left)")
                .font(.system(size: 8, weight: .black))
                .foregroundColor(.white)
                .padding(.horizontal, 3).padding(.vertical, 1)
                .background(left > 0 ? Color.hachiwareBlue : Color.inkBrown.opacity(0.4))
                .clipShape(Capsule())
                .offset(x: 6, y: 6)
        }
        .onTapGesture {
            if isActive {
                wateringPig = nil
            } else if left > 0 {
                wateringPig = pig
            }
        }
    }

    // MARK: - Daily Goal Banner

    var dailyGoalBanner: some View {
        let goal = dailyGoal
        let prog = min(todayGoalProgress, goal.count)
        let done = prog >= goal.count
        return HStack(spacing: 8) {
            Text("🎯 Today: harvest \(goal.count)× \(goal.crop)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color.inkBrown)
            Spacer()
            Text("\(prog)/\(goal.count)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(done ? Color.mintGreen : Color.inkBrown.opacity(0.6))
            if done { Text("✅").font(.system(size: 13)) }
        }
        .padding(.horizontal, 14).padding(.vertical, 7)
        .background(done ? Color.mintGreen.opacity(0.2) : Color.chiikawaWhite)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.inkBrown.opacity(0.25), lineWidth: 1.5))
        .padding(.horizontal, 12)
    }

    // MARK: - Leaderboard

    var leaderboardView: some View {
        let ranked = selectedPigs
            .map { ($0, harvestCounts[$0] ?? 0) }
            .sorted { $0.1 > $1.1 }
        let medals = ["🥇", "🥈", "🥉"]
        return VStack(alignment: .leading, spacing: 6) {
            Text("👩‍🌾 Farmer Rankings")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(Color.inkBrown)
            HStack(spacing: 10) {
                ForEach(ranked.indices, id: \.self) { i in
                    let (pig, count) = ranked[i]
                    VStack(spacing: 4) {
                        Text(medals[i]).font(.system(size: 18))
                        Image(pig)
                            .resizable().scaledToFit()
                            .frame(width: 32, height: 32)
                            .padding(3)
                            .background(Color.chiikawaWhite)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.inkBrown, lineWidth: 1.5))
                        Text("\(count) 🌾")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color.inkBrown)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(i == 0 ? Color.usagiYellow.opacity(0.3) : Color.chiikawaWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.inkBrown.opacity(0.3), lineWidth: 1.5))
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Stage Logic (with watering 2× boost)

    private func stageOf(_ plot: FarmPlot) -> CropStage {
        guard plot.stage != .empty, let planted = plot.plantedAt else { return .empty }
        let effective: Double
        if let watered = plot.wateredAt, watered > planted {
            let before = min(watered.timeIntervalSince(planted), seedTime)
            let after  = now.timeIntervalSince(watered) * 2.0
            effective = before + after
        } else {
            effective = now.timeIntervalSince(planted)
        }
        if effective >= totalTime { return .ready }
        if effective >= seedTime  { return .growing }
        return .seeded
    }

    // MARK: - Tap Handler

    private func handleTap(plot: inout FarmPlot) {
        let stage = stageOf(plot)

        // Watering mode
        if let pig = wateringPig {
            guard stage == .seeded || stage == .growing else { return }
            plot.wateredAt = Date()
            watersLeft[pig] = max((watersLeft[pig] ?? maxDailyWaters) - 1, 0)
            if (watersLeft[pig] ?? 0) == 0 { wateringPig = nil }
            saveWaters(); savePlots()
            return
        }

        switch stage {
        case .empty:
            plot.stage     = .seeded
            plot.cropType  = Int.random(in: 0..<crops.count)
            plot.plantedAt = Date()
            plot.wateredAt = nil
            plot.farmedBy  = selectedPigs.randomElement()
        case .ready:
            score += 1
            savedScore = score
            // Leaderboard credit
            if let pig = plot.farmedBy {
                harvestCounts[pig] = (harvestCounts[pig] ?? 0) + 1
                saveHarvests()
            }
            // Daily goal
            let goal = dailyGoal
            if crops[plot.cropType % crops.count] == goal.crop {
                if !goalIsToday { goalDateStr = todayStr; goalProgress = 0 }
                goalProgress += 1
            }
            plot = FarmPlot(id: plot.id)
        default: break
        }
        savePlots()
    }

    // MARK: - Persistence

    private func savePlots()   { if let d = try? JSONEncoder().encode(plots)        { plotsData   = d } }
    private func saveHarvests(){ if let d = try? JSONEncoder().encode(harvestCounts){ harvestData  = d } }
    private func saveWaters()  { if let d = try? JSONEncoder().encode(watersLeft)   { watersData  = d } }

    private func loadState() {
        // Reset score each new day
        if scoreDateStr != todayStr {
            scoreDateStr = todayStr
            score = 0
            savedScore = 0
        } else {
            score = savedScore
        }
        let pigs = savedPigs.components(separatedBy: ",").filter { !$0.isEmpty }
        if pigs.count == 3 { selectedPigs = pigs; showPicker = false }

        if let loaded = try? JSONDecoder().decode([FarmPlot].self, from: plotsData),
           loaded.count == gridCols * gridRows { plots = loaded }
        if let loaded = try? JSONDecoder().decode([String: Int].self, from: harvestData) { harvestCounts = loaded }

        // Reset waters each new day
        if waterDateStr != todayStr {
            waterDateStr = todayStr
            watersLeft = [:]
        } else if let loaded = try? JSONDecoder().decode([String: Int].self, from: watersData) {
            watersLeft = loaded
        }
    }
}

// MARK: - Plot Cell

private struct PlotCellView: View {
    @Binding var plot: FarmPlot
    let now: Date
    let isWateringMode: Bool
    let onTap: () -> Void

    private let crops = ["🥕", "🍓", "🥬", "🍇", "🍎", "🥒"]

    var stage: CropStage {
        guard plot.stage != .empty, let planted = plot.plantedAt else { return .empty }
        let eff: Double
        if let w = plot.wateredAt, w > planted {
            eff = min(w.timeIntervalSince(planted), 180) + now.timeIntervalSince(w) * 2.0
        } else {
            eff = now.timeIntervalSince(planted)
        }
        if eff >= 540 { return .ready }
        if eff >= 180 { return .growing }
        return .seeded
    }

    var bgColor: Color {
        switch stage {
        case .empty:   return Color(hex: "8B6914").opacity(0.3)
        case .seeded:  return Color(hex: "5C7A2D").opacity(0.3)
        case .growing: return Color(hex: "4A8C1F").opacity(0.4)
        case .ready:   return Color.mintGreen.opacity(0.5)
        }
    }

    // Crop is always shown — faded when not yet ready
    var cropOpacity: Double {
        switch stage {
        case .empty:   return 0
        case .seeded:  return 0.3
        case .growing: return 0.65
        case .ready:   return 1.0
        }
    }

    var progressFraction: Double {
        guard let planted = plot.plantedAt else { return 0 }
        let eff: Double
        if let w = plot.wateredAt, w > planted {
            eff = min(w.timeIntervalSince(planted), 180) + now.timeIntervalSince(w) * 2.0
        } else {
            eff = now.timeIntervalSince(planted)
        }
        return min(eff / 540.0, 1.0)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(bgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isWateringMode && (stage == .seeded || stage == .growing)
                                    ? Color.hachiwareBlue : Color.inkBrown.opacity(0.3),
                                    lineWidth: isWateringMode ? 2.5 : 1)
                    )

                // Progress bar (bottom strip)
                if stage == .seeded || stage == .growing {
                    VStack {
                        Spacer()
                        GeometryReader { g in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(plot.wateredAt != nil ? Color.hachiwareBlue.opacity(0.7) : Color.mintGreen.opacity(0.7))
                                .frame(width: g.size.width * progressFraction, height: 4)
                        }
                        .frame(height: 4)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 3)
                    }
                }

                // Crop emoji (always visible, opacity changes with stage)
                if stage != .empty {
                    Text(crops[plot.cropType % crops.count])
                        .font(.system(size: stage == .ready ? 24 : 20))
                        .opacity(cropOpacity)
                        .scaleEffect(stage == .ready ? 1.0 : 0.8)
                }

                // Water drop indicator
                if plot.wateredAt != nil && stage != .ready {
                    Text("💧")
                        .font(.system(size: 10))
                        .offset(x: 12, y: -14)
                }

                // Farmer pig badge (bottom-left)
//                if stage != .empty, let pig = plot.farmedBy {
//                    Image(pig)
//                        .resizable().scaledToFit()
//                        .frame(width: 14, height: 14)
//                        .clipShape(Circle())
//                        .overlay(Circle().stroke(Color.inkBrown, lineWidth: 1))
//                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
//                        .padding(3)
//                }
            }
            .frame(height: 58)
        }
        .buttonStyle(.plain)
    }
}
