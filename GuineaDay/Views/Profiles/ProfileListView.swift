import SwiftUI
import SwiftData

struct ProfileListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GuineaPig.name) private var guineaPigs: [GuineaPig]

    @State private var showingAddPig = false
    @State private var selectedPig: GuineaPig?

    let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.wallGray.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header banner
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("My Piggies 🐾")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundStyle(Color.inkBrown)
                                Text("\(guineaPigs.count) fuzzy friend\(guineaPigs.count == 1 ? "" : "s")")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(Color.inkBrown.opacity(0.6))
                            }
                            Spacer()
                            // Add button
                            Button(action: { showingAddPig = true }) {
                                ZStack {
                                    Circle().fill(Color.blushPink).frame(width: 44, height: 44)
                                        .overlay(Circle().stroke(Color.inkBrown, lineWidth: 2.5))
                                        .shadow(color: Color.inkBrown.opacity(0.4), radius: 0, x: 2, y: 3)
                                    Image(systemName: "plus").font(.system(size: 18, weight: .black)).foregroundColor(.inkBrown)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)

                        if guineaPigs.isEmpty {
                            // Empty state
                            VStack(spacing: 16) {
                                Text("🐾").font(.system(size: 60))
                                Text("No piggies yet!")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.inkBrown)
                                Text("Tap + to add your first guinea pig")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(Color.inkBrown.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 60)
                            .chiikawaCard(color: .chiikawaWhite, radius: 28)
                            .padding(.horizontal)
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(guineaPigs) { pig in
                                    PigCard(pig: pig)
                                        .onTapGesture { selectedPig = pig }
                                        .contextMenu {
                                            Button(role: .destructive) { deletePig(pig) }
                                                label: { Label("Delete", systemImage: "trash") }
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer().frame(height: 90)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddPig) { ProfileEditView() }
            .sheet(item: $selectedPig) { pig in ProfileEditView(guineaPig: pig) }
        }
    }

    private func deletePig(_ pig: GuineaPig) {
        if let img = pig.profileImageAssetName { ImageStorageService.shared.deleteImage(filename: img) }
        modelContext.delete(pig)
    }
}

// MARK: - Pig Card
struct PigCard: View {
    func ageString(from birthday: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month], from: birthday, to: Date())
        let years  = components.year  ?? 0
        let months = components.month ?? 0

        if years == 0 && months == 0 { return "< 1 month old" }
        if years == 0 { return "\(months) month\(months == 1 ? "" : "s") old" }
        if months == 0 { return "\(years) yr\(years == 1 ? "" : "s") old" }
        return "\(years) yr\(years == 1 ? "" : "s") \(months) mo old"
    }

    let pig: GuineaPig

    var body: some View {
        VStack(spacing: 0) {
            // Blush pink header band
            ZStack {
                Color.blushPink
                if let urlStr = pig.profileImageAssetName {
                    if urlStr.hasPrefix("http"), let url = URL(string: urlStr) {
                        // New: Firebase Storage URL
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                                    .frame(height: 110).clipped()
                                    .overlay(Color.blushPink.opacity(0.15))
                            default:
                                Text("🐾").font(.system(size: 50))
                            }
                        }
                    } else if let img = ImageStorageService.shared.loadImage(filename: urlStr) {
                        // Old: local filename fallback
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(height: 110).clipped()
                            .overlay(Color.blushPink.opacity(0.15))
                    } else {
                        Text("🐾").font(.system(size: 50))
                    }
                } else {
                    Text("🐾").font(.system(size: 50))
                }
            }
            .frame(height: 110)


            // Name area
            VStack(spacing: 3) {
                Text(pig.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkBrown)
                Text(pig.breed)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Color.inkBrown.opacity(0.55))
                Text(ageString(from: pig.birthDate))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Color.hachiwareBlue)

            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.chiikawaWhite)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.inkBrown, lineWidth: 3))
        .shadow(color: Color.inkBrown.opacity(0.45), radius: 0, x: 3, y: 4)
    }
}

#Preview {
    ProfileListView().modelContainer(for: GuineaPig.self, inMemory: true)
}
