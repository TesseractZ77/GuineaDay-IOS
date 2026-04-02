import SwiftUI
import SwiftData
import PhotosUI

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Photo.dateTaken, order: .reverse) private var photos: [Photo]
    @EnvironmentObject var firestore: FirestoreService

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var zoomedPhoto: Photo?

    let columns = [GridItem(.adaptive(minimum: 100), spacing: 10)]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.wallGray.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Memories 🌸")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundStyle(Color.inkBrown)
                                Text("\(photos.count) photo\(photos.count == 1 ? "" : "s")")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(Color.inkBrown.opacity(0.6))
                            }
                            Spacer()
                            PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                                ZStack {
                                    Circle().fill(Color.lavenderPurple).frame(width: 44, height: 44)
                                        .overlay(Circle().stroke(Color.inkBrown, lineWidth: 2.5))
                                        .shadow(color: Color.inkBrown.opacity(0.4), radius: 0, x: 2, y: 3)
                                    Image(systemName: "plus").font(.system(size: 18, weight: .black)).foregroundColor(.inkBrown)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)

                        if photos.isEmpty {
                            VStack(spacing: 16) {
                                Text("📷").font(.system(size: 60))
                                Text("No memories yet!")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.inkBrown)
                                Text("Tap + to add your first photo")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(Color.inkBrown.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 60)
                            .chiikawaCard(color: .chiikawaWhite, radius: 28)
                            .padding(.horizontal)
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(photos) { photo in
                                    Group {
                                        if photo.filename.hasPrefix("http") {
                                            // New photos: load via cache
                                            CachedAsyncImage(url: URL(string: photo.filename)) { img in
                                                img.resizable().scaledToFill()
                                            } placeholder: {
                                                Color.blushPink.overlay(
                                                    Image(systemName: "photo")
                                                        .foregroundColor(.inkBrown.opacity(0.4))
                                                )
                                            }
                                        } else if let img = ImageStorageService.shared.loadImage(filename: photo.filename) {
                                            // Old photos: load from local storage (physical phone only)
                                            Image(uiImage: img).resizable().scaledToFill()
                                        } else {
                                            Color.blushPink.overlay(Image(systemName: "photo").foregroundColor(.inkBrown.opacity(0.4)))
                                        }
                                    }
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.inkBrown, lineWidth: 3))
                                    .shadow(color: Color.inkBrown.opacity(0.4), radius: 0, x: 2, y: 3)
                                    .onTapGesture { zoomedPhoto = photo }
                                    .contextMenu {
                                        Button(role: .destructive) { deletePhoto(photo) }
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
            .task { await prefetchPhotos() }
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) { await savePhoto(img) }
                    }
                    selectedItems = []
                }
            }
            .sheet(item: $zoomedPhoto) { photo in
                ZStack {
                    Color.wallGray.ignoresSafeArea()
                    // Try reading directly from cache first (instant, no async needed)
                    if let cachedImg = ImageCacheService.shared.image(for: photo.filename) {
                        Image(uiImage: cachedImg)
                            .resizable().scaledToFit()
                            .padding(20)
                            .chiikawaCard(color: .chiikawaWhite, radius: 28)
                            .padding()
                    } else {
                        // Fallback: download if cache was evicted
                        CachedAsyncImage(url: URL(string: photo.filename)) { img in
                            img.resizable().scaledToFit()
                                .padding(20)
                                .chiikawaCard(color: .chiikawaWhite, radius: 28)
                                .padding()
                        } placeholder: {
                            ProgressView()
                        }
                    }

                }
            }
        }
    }

    private func savePhoto(_ image: UIImage) async {
        let name = "photos/\(UUID().uuidString).jpg"
        guard let url = try? await StorageService.shared.uploadImage(image, householdId: firestore.householdId, name: name) else { return }
        let photo = Photo(filename: url)   // ← store Firebase Storage URL, not local filename
        modelContext.insert(photo)
        try? await firestore.addPhoto(photo)
    }

    private func deletePhoto(_ photo: Photo) {
        let id = photo.id
        modelContext.delete(photo)
        Task { try? await firestore.deletePhoto(id: id) }
    }
    private func prefetchPhotos() async {
        await withTaskGroup(of: Void.self) { group in
            for photo in photos where photo.filename.hasPrefix("http") {
                let urlStr = photo.filename
                guard ImageCacheService.shared.image(for: urlStr) == nil,
                      let url = URL(string: urlStr) else { continue }
                group.addTask {
                    if let (data, _) = try? await URLSession.shared.data(from: url),
                       let img = UIImage(data: data) {
                        ImageCacheService.shared.store(img, for: urlStr)
                    }
                }
            }
        }
    }

}

extension Photo: Identifiable {}

#Preview { GalleryView() }
