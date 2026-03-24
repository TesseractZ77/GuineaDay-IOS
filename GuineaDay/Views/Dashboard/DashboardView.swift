import SwiftUI
import SwiftData
import PhotosUI

struct DashboardView: View {
    @AppStorage("selectedMascot") private var selectedMascot: String = "kui"
    @AppStorage("customMascotFilename") private var customMascotFilename: String = ""
        @State private var showMascotPicker = false
    @State private var customMascotItem: PhotosPickerItem?
    @Environment(\.modelContext) private var modelContext
    @StateObject private var session = AppSession.shared
    @State private var codeCopied = false
    @Query private var tasks: [TaskItem]
    @Query private var pigs: [GuineaPig]
    @Query private var photos: [Photo]

    private let weatherService = WeatherService.shared

    private var pendingCount: Int { tasks.filter { !$0.isCompleted }.count }
    private var doneCount:    Int { tasks.filter {  $0.isCompleted }.count }

    // Sparkle positions (fixed so they don't re-randomize on every render)
    private let sparkles: [(x: CGFloat, y: CGFloat, size: CGFloat, color: Color)] = [
        (0.08, 0.10, 14, .blushPink),
        (0.90, 0.08, 10, .hachiwareBlue),
        (0.15, 0.55, 12, .usagiYellow),
        (0.82, 0.45, 16, .mintGreen),
        (0.50, 0.05, 10, .lavenderPurple),
        (0.72, 0.80, 12, .blushPink),
        (0.25, 0.85, 10, .hachiwareBlue),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.wallGray.ignoresSafeArea()

                // Decorative sparkles — behind everything
                GeometryReader { geo in
                    ForEach(sparkles.indices, id: \.self) { i in
                        let s = sparkles[i]
                        SparkleView(size: s.size, color: s.color)
                            .position(x: s.x * geo.size.width, y: s.y * geo.size.height)
                    }
                }
                .allowsHitTesting(false)

                ScrollView {
                    VStack(spacing: 20) {

                        // ── Top banner: date + weather ──
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
//                                Text("Today")
//                                    .font(.caption)
//                                    .foregroundStyle(Color.inkBrown.opacity(0.6))
                                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.inkBrown)
                            }
                            Spacer()
                            if let weather = weatherService.currentWeatherData {
                                HStack(spacing: 6) {
                                    Text(weather.condition).font(.title3)
                                    Text("\(Int(weather.currentTempC))°C")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.inkBrown)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .chiikawaCard(color: Color.hachiwareBlue, radius: 20)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)

                        // ── Mascot welcome card ──
                        ZStack {
                            // Pastel gradient background
                            LinearGradient(
                                colors: [Color.usagiYellow, Color.blushPink.opacity(0.4)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )

                            HStack(spacing: 16) {
                                // Guinea pig mascot
//                                Image("kui")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: 90, height: 90)
//                                    .shadow(color: Color.inkBrown.opacity(0.3), radius: 0, x: 2, y: 3)
                                // Show custom image if selected, otherwise named asset
                                Group {
                                    if selectedMascot == "custom",
                                       let img = ImageStorageService.shared.loadImage(filename: customMascotFilename) {
                                        Image(uiImage: img)
                                            .resizable().scaledToFill()
                                            .frame(width: 90, height: 90)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                    } else {
                                        Image(selectedMascot)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 90, height: 90)
                                    }
                                }
                                .shadow(color: Color.inkBrown.opacity(0.3), radius: 0, x: 2, y: 3)
                                    .onTapGesture { showMascotPicker = true }
                                    .overlay(alignment: .bottomTrailing) {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(Color.inkBrown)
                                            .background(Color.usagiYellow)
                                            .clipShape(Circle())
                                            .offset(x: 4, y: 4)
                                    }


                                VStack(alignment: .leading, spacing: 6) {
                                    Text("GuineaDay ✦")
                                        .font(.system(size: 26, weight: .black, design: .rounded))
                                        .foregroundStyle(Color.inkBrown)
                                    Text("Welcome back!\nYour piggies miss you~ 🥕")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.inkBrown.opacity(0.8))
                                        .lineSpacing(3)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 24)
                        }
                        .frame(maxWidth: .infinity)
                        .chiikawaCard(color: .clear, radius: 28)
                        .padding(.horizontal)

                        // ── Stats row ──
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            DashStatCard(icon: "pawprint.fill",  value: "\(pigs.count)",    label: "Piggies",  color: .blushPink)
                            DashStatCard(icon: "checkmark.circle.fill", value: "\(pendingCount)", label: "To-Do", color: .usagiYellow)
                            DashStatCard(icon: "photo.stack.fill", value: "\(photos.count)", label: "Memories", color: .lavenderPurple)
                        }
                        .padding(.horizontal)


                        // ── Quick tips ──
                        VStack(alignment: .leading, spacing: 12) {
                            ChiikawaSectionHeader(title: "Piggy Tips", color: .mintGreen, icon: "lightbulb.fill")
                            VStack(spacing: 10) {
                                TipRow(emoji: "🥕", tip: "Guinea pigs need fresh veggies daily!")
                                TipRow(emoji: "💧", tip: "Fresh water every day — no exceptions.")
                                TipRow(emoji: "🥰", tip: "At least 1 hour of floor time keeps them happy.")
                                TipRow(emoji: "❤️", tip: "Guinea pigs are social — they love company!")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .chiikawaCard(color: .chiikawaWhite, radius: 24)
                        .padding(.horizontal)
                        
                        // ── Invite code card ──
                        if let code = session.inviteCode {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Household Code")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(.inkBrown.opacity(0.6))
                                    Text(code)
                                        .font(.system(size: 22, weight: .black, design: .monospaced))
                                        .foregroundColor(.inkBrown)
                                        .tracking(4)
                                }
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = code
                                    withAnimation { codeCopied = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { codeCopied = false }
                                    }
                                } label: {
                                    Image(systemName: codeCopied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(codeCopied ? .mintGreen : .inkBrown)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .chiikawaCard(color: .lavenderPurple.opacity(0.4), radius: 18)
                            .padding(.horizontal)
                        }


                        // Bottom padding for floating tab bar
                        Spacer().frame(height: 90)
                    }
                }
            }
            .sheet(isPresented: $showMascotPicker) {
                VStack(spacing: 20) {
                    Text("Choose Your Mascot")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color.inkBrown)
                        .padding(.top, 90)

                    let pigNames  = ["hachi", "kui", "nova", "elmo", "mel", "haru", "seven"]
                    let pigLabels = ["Hachi", "Kui", "Nova", "Elmo", "Mel", "Haru", "Seven"]

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 16) {
                        // Built-in mascots
                        ForEach(pigNames.indices, id: \.self) { i in
                            VStack(spacing: 6) {
                                Image(pigNames[i])
                                    .resizable().scaledToFit()
                                    .frame(width: 70, height: 70)
                                    .padding(8)
                                    .background(selectedMascot == pigNames[i] ? Color.usagiYellow : Color.wallGray)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.inkBrown, lineWidth: selectedMascot == pigNames[i] ? 3 : 1.5))
                                    .onTapGesture {
                                        selectedMascot = pigNames[i]
                                        showMascotPicker = false
                                    }
                                Text(pigLabels[i])
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(Color.inkBrown)
                            }
                        }

                        // Custom photo upload option
                        VStack(spacing: 6) {
                            PhotosPicker(selection: $customMascotItem, matching: .images) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedMascot == "custom" ? Color.usagiYellow : Color.wallGray)
                                        .frame(width: 70, height: 70)
                                        .overlay(RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.inkBrown, lineWidth: selectedMascot == "custom" ? 3 : 1.5))
                                    if selectedMascot == "custom",
                                       let img = ImageStorageService.shared.loadImage(filename: customMascotFilename) {
                                        Image(uiImage: img)
                                            .resizable().scaledToFill()
                                            .frame(width: 70, height: 70)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.inkBrown.opacity(0.7))
                                    }
                                }
                            }
                            .onChange(of: customMascotItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let img = UIImage(data: data),
                                       let saved = ImageStorageService.shared.saveImage(img, name: "custom_mascot.jpg") {
                                        customMascotFilename = saved
                                        selectedMascot = "custom"
                                        showMascotPicker = false
                                    }
                                }
                            }
                            Text("Your Own")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(Color.inkBrown)
                        }
                    }
                    .padding()
                    Spacer()
                }
                .presentationDetents([.medium])
            }

            .navigationBarHidden(true)
        }
    }
}

struct DashStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color.inkBrown)
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Color.inkBrown)
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.inkBrown.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .chiikawaCard(color: color, radius: 20)
    }
}

struct TipRow: View {
    let emoji: String
    let tip: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(emoji).font(.body)
            Text(tip)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(Color.inkBrown)
            Spacer()
        }
    }
}

// Keep old StatCard for compatibility if referenced elsewhere
struct StatCard: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 8) {
            Text(value).font(.system(size: 36, weight: .bold, design: .rounded)).foregroundStyle(Color.inkBrown)
            Text(title).font(.subheadline).foregroundStyle(Color.inkBrown.opacity(0.8))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20)
        .chiikawaCard(color: Color.usagiYellow, radius: 25)
    }
}

#Preview { DashboardView() }
