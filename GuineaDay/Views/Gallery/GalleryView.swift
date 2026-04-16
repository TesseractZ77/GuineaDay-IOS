import SwiftUI
import SwiftData
import PhotosUI
import Photos

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Photo.dateTaken, order: .reverse) private var photos: [Photo]
    @EnvironmentObject var firestore: FirestoreService

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var zoomedPhoto: Photo?
    @State private var uploadFailedAlert = false
    @State private var photoLoadFailedAlert = false

    let columns = [GridItem(.adaptive(minimum: 100), spacing: 10)]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.wallGray.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header (title only — + button is a ZStack overlay below)
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
            // + button OUTSIDE ScrollView — no gesture conflict with photo grid
            .overlay(alignment: .topTrailing) {
                ChiikawaPhotoPickerButton(color: .lavenderPurple, selectedItems: $selectedItems)
                    .padding(.top, 16)
                    .padding(.trailing, 16)
            }
            .navigationBarHidden(true)
            .task { await prefetchPhotos() }
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    var anyFailed = false
                    for item in newItems {
                        if let img = await loadLocalImage(from: item) {
                            await savePhoto(img)
                        } else {
                            anyFailed = true
                        }
                    }
                    selectedItems = []
                    if anyFailed { photoLoadFailedAlert = true }
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
                    } else if photo.filename.hasPrefix("http"),
                              let url = URL(string: photo.filename) {
                        // Cloud photo: re-download from Firebase if cache was evicted
                        CachedAsyncImage(url: url) { img in
                            img.resizable().scaledToFit()
                                .padding(20)
                                .chiikawaCard(color: .chiikawaWhite, radius: 28)
                                .padding()
                        } placeholder: {
                            ProgressView()
                        }
                    } else if let img = ImageStorageService.shared.loadImage(filename: photo.filename) {
                        // Local photo: load directly from device storage
                        Image(uiImage: img).resizable().scaledToFit()
                            .padding(20)
                            .chiikawaCard(color: .chiikawaWhite, radius: 28)
                            .padding()
                    }

                }
            }
            .alert("Photo Upload Failed", isPresented: $uploadFailedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Could not upload the photo. Please check your internet connection and try again.")
            }
            .alert("Photo Not Available Offline", isPresented: $photoLoadFailedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("One or more photos could not be loaded. If your iPhone uses iCloud Photo Library with 'Optimize Storage', the original photo may only exist in iCloud. Connect to the internet to download it first, then try again.")
            }
        }
    }

    @MainActor
    private func savePhoto(_ image: UIImage) async {
        let name = "photos_\(UUID().uuidString).jpg" // underscore prevents folder creation errors in local storage
        let finalFilename: String
        
        if AppMode.current == .cloud {
            guard let url = try? await StorageService.shared.uploadImage(image, householdId: firestore.householdId, name: name) else {
                uploadFailedAlert = true // Option A: show error, don't silently drop
                return
            }
            finalFilename = url
        } else {
            guard let savedName = ImageStorageService.shared.saveImage(image, name: name) else { return }
            finalFilename = savedName
        }
        
        let photo = Photo(filename: finalFilename)
        modelContext.insert(photo)
        try? modelContext.save() // Guarantee SwiftData registers the insert before thread jumps
        
        if AppMode.current == .cloud {
            try? await firestore.addPhoto(photo)
        }
    }

    private func deletePhoto(_ photo: Photo) {
        let filename = photo.filename
        let id = photo.id
        // Delete local JPEG from Documents/ — prevents ghost files accumulating on device
        if !filename.hasPrefix("http") {
            ImageStorageService.shared.deleteImage(filename: filename)
        }
        modelContext.delete(photo)
        if AppMode.current == .cloud {
            Task { try? await firestore.deletePhoto(id: id) }
        }
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

    // MARK: - Helpers

    /// Loads image from PHAsset without iCloud network access.
    /// Uses .fastFormat to return whatever is locally cached, no iCloud download.
    private func loadLocalImage(from item: PhotosPickerItem) async -> UIImage? {
        // Path 1: PHImageManager — works offline, returns locally cached version
        if let identifier = item.itemIdentifier {
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            if let asset = fetchResult.firstObject {
                let options = PHImageRequestOptions()
                options.deliveryMode = .fastFormat    // Returns fastest local version; never waits for iCloud
                options.isNetworkAccessAllowed = false
                options.isSynchronous = false

                let image: UIImage? = await withCheckedContinuation { continuation in
                    PHImageManager.default().requestImage(
                        for: asset,
                        targetSize: PHImageManagerMaximumSize,
                        contentMode: .aspectFit,
                        options: options
                    ) { img, _ in continuation.resume(returning: img) }
                }
                if let image { return image }
            }
        }

        // Path 2: Fallback — loadTransferable works when photo IS fully on device
        if let data = try? await item.loadTransferable(type: Data.self) {
            return UIImage(data: data)
        }

        // Both paths failed: photo is iCloud-only with no internet access
        return nil
    }
}

extension Photo: Identifiable {}

#Preview { GalleryView() }
