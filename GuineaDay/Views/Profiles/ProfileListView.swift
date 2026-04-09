import SwiftUI
import SwiftData

// MARK: - Sheet destination
private enum SheetDestination: Identifiable {
    case addNew
    case edit(GuineaPig)

    var id: String {
        switch self {
        case .addNew:       return "add"
        case .edit(let p):  return p.id.uuidString
        }
    }
}

struct ProfileListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var firestore: FirestoreService
    @Query(sort: \GuineaPig.name) private var guineaPigs: [GuineaPig]

    @State private var sheetDestination: SheetDestination?  // single sheet state
    @State private var pigToDelete: GuineaPig?              // delete confirmation

    let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.wallGray.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header banner (title only — + button is a ZStack overlay below)
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
                                    // Use Button (not onTapGesture) for precise hit-testing
                                    Button { sheetDestination = .edit(pig) } label: {
                                        PigCard(
                                            pig: pig,
                                            onDelete: { pigToDelete = pig }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) { pigToDelete = pig }
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
            // + button is OUTSIDE the ScrollView — no gesture conflict with card grid
            .overlay(alignment: .topTrailing) {
                ChiikawaAddButton(color: .blushPink) { sheetDestination = .addNew }
                    .padding(.top, 16)
                    .padding(.trailing, 16)
            }
            .navigationBarHidden(true)
            // Single sheet handles both "Add New" and "Edit Existing"
            .sheet(item: $sheetDestination) { destination in
                switch destination {
                case .addNew:       ProfileEditView()
                case .edit(let p): ProfileEditView(guineaPig: p)
                }
            }
            // Bug 3: delete confirmation alert
            .alert("Delete \(pigToDelete?.name ?? "Piggy")?", isPresented: Binding(
                get:  { pigToDelete != nil },
                set:  { if !$0 { pigToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let pig = pigToDelete { deletePig(pig) }
                    pigToDelete = nil
                }
                Button("Cancel", role: .cancel) { pigToDelete = nil }
            } message: {
                Text("This will permanently remove \(pigToDelete?.name ?? "this piggy") for everyone in your household.")
            }
        }
    }

    // Bug 3: Delete locally AND from Firestore (permanent for all household members)
    private func deletePig(_ pig: GuineaPig) {
        let pigId = pig.id
        if let img = pig.profileImageAssetName { ImageStorageService.shared.deleteImage(filename: img) }
        modelContext.delete(pig)
        Task { try? await firestore.deletePig(id: pigId) }
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
    var onDelete: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            // Blush pink header band
            ZStack {
                Color.blushPink
                if let urlStr = pig.profileImageAssetName {
                    if urlStr.hasPrefix("http"), let url = URL(string: urlStr) {
                        // New: Firebase Storage URL — cached
                        CachedAsyncImage(url: url) { img in
                            img.resizable().scaledToFill()
                                .frame(height: 110).clipped()
                                .overlay(Color.blushPink.opacity(0.15))
                        } placeholder: {
                            Text("🐾").font(.system(size: 50))
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
        // Trash button at bottom-right of full card
        .overlay(alignment: .bottomTrailing) {
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.inkBrown)
                    .padding(7)
                    .background(Circle().fill(Color.chiikawaWhite))
                    .overlay(Circle().stroke(Color.inkBrown, lineWidth: 1.5))
                    .shadow(color: Color.inkBrown.opacity(0.3), radius: 0, x: 1, y: 2)
            }
            .padding(8)
        }
    }
}

#Preview {
    ProfileListView().modelContainer(for: GuineaPig.self, inMemory: true)
}
