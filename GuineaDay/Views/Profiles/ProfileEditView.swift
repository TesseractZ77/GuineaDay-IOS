import SwiftUI
import SwiftData
import PhotosUI
import Photos

struct ProfileEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firestore: FirestoreService

    
    let guineaPig: GuineaPig?
    
    @State private var name = ""
    @State private var birthDate = Date()
    @State private var breed = "American"
    @State private var gender = "Male"
    
    // Photo handling
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var profileImageAssetName: String?

    // Bug 3: Prevent duplicate saves from multiple rapid taps
    @State private var isSaving = false
    @State private var uploadFailedAlert = false
    @State private var photoLoadFailedAlert = false
    
    let breeds = ["American", "Abyssinian", "Alpaca", "Baldwin", "Peruvian", "Silkie", "Skinny", "Rex", "Texel", "Coronet", "Himalayan", "Sheltie", "Sheba"]
    let genders = ["Boar", "Sow"]
    
    init(guineaPig: GuineaPig? = nil) {
        self.guineaPig = guineaPig
        _name = State(initialValue: guineaPig?.name ?? "")
        _birthDate = State(initialValue: guineaPig?.birthDate ?? Date())
        _breed = State(initialValue: guineaPig?.breed ?? "American")
        _gender = State(initialValue: guineaPig?.gender ?? "Boar")
        _profileImageAssetName = State(initialValue: guineaPig?.profileImageAssetName)
        
        // selectedImage stays nil — existing URL photos are displayed via AsyncImage in the view
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.wallGray.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Photo").foregroundStyle(Color.inkBrown)) {
                        HStack {
                            Spacer()
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                if let selectedImage {
                                    // Newly picked image (not yet uploaded)
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.inkBrown, lineWidth: 3))
                                } else if let urlStr = profileImageAssetName {
                                    if urlStr.hasPrefix("http"), let url = URL(string: urlStr) {
                                        // Cloud photo: load from Firebase Storage URL
                                        CachedAsyncImage(url: url) { img in
                                            img.resizable().scaledToFill()
                                                .frame(width: 120, height: 120)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.inkBrown, lineWidth: 3))
                                        } placeholder: {
                                            Circle().fill(Color.usagiYellow)
                                                .frame(width: 120, height: 120)
                                                .overlay(ProgressView())
                                        }
                                    } else if let img = ImageStorageService.shared.loadImage(filename: urlStr) {
                                        // Local photo: load directly from device storage
                                        Image(uiImage: img).resizable().scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.inkBrown, lineWidth: 3))
                                    }
                                } else {
                                    VStack {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.largeTitle)
                                        Text("Add Photo")
                                            .font(.caption)
                                    }
                                    .frame(width: 120, height: 120)
                                    .background(Circle().fill(Color.usagiYellow))
                                    .foregroundColor(Color.inkBrown)
                                    .overlay(Circle().stroke(Color.inkBrown, lineWidth: 3))
                                }
                            }
                            .onChange(of: selectedItem) { _, newItem in
                                Task {
                                    let loaded = await loadLocalImage(from: newItem)
                                    if loaded == nil && newItem != nil {
                                        photoLoadFailedAlert = true
                                    }
                                    selectedImage = loaded
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical)
                    }
                    .listRowBackground(Color.chiikawaWhite)
                    
                    Section(header: Text("Details").foregroundStyle(Color.inkBrown)) {
                        HStack {
                            Text("Name")
                            TextField("Name", text: $name)
                                .multilineTextAlignment(.trailing)
                        }
                        DatePicker("Birthday", selection: $birthDate, displayedComponents: .date)
                        Picker("Breed", selection: $breed) {
                            ForEach(breeds, id: \.self) { Text($0) }
                        }
                        Picker("Gender", selection: $gender) {
                            ForEach(genders, id: \.self) { Text($0) }
                        }
                    }
                    .listRowBackground(Color.chiikawaWhite)
                    .tint(Color.inkBrown)
                    
                    // Show weight log if editing an existing pig
                    if let pig = guineaPig {
                        Section(header: Text("Health").foregroundStyle(Color.inkBrown)) {
                            WeightLogView(guineaPig: pig)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(guineaPig == nil ? "New Piggy" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.inkBrown)
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                            .tint(Color.inkBrown)
                    } else {
                        Button("Save") { saveProfile() }
                            .foregroundStyle(Color.inkBrown)
                            .disabled(name.isEmpty)
                    }
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
            Text("This photo could not be loaded. If your iPhone uses iCloud Photo Library with 'Optimize Storage', the photo may only exist in iCloud. Connect to the internet to download it first, then try again.")
        }
    }
    
    // MARK: - Helpers

    /// Loads image from PHAsset without iCloud network access.
    /// Falls back to loadTransferable for locally-stored photos.
    private func loadLocalImage(from item: PhotosPickerItem?) async -> UIImage? {
        guard let item else { return nil }

        // Try PHImageManager first — returns locally cached version, never downloads from iCloud
        if let identifier = item.itemIdentifier {
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat    // Returns fastest local version; NEVER waits for iCloud
            options.isNetworkAccessAllowed = false
            options.isSynchronous = false

            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            if let asset = fetchResult.firstObject {
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

        // Fallback: loadTransferable (works for non-iCloud / already-downloaded photos)
        if let data = try? await item.loadTransferable(type: Data.self) {
            return UIImage(data: data)
        }
        return nil
    }

    private func saveProfile() {
        // Bug 3: Guard against multiple concurrent taps
        guard !isSaving else { return }
        isSaving = true

        Task {
            defer { isSaving = false }

            var finalImageName = profileImageAssetName

            // If a new image was picked, upload to Firebase Storage or save locally
            if let newImage = selectedImage {
                let filename = "profiles_\(UUID().uuidString).jpg"
                
                if AppMode.current == .cloud {
                    guard let url = try? await StorageService.shared.uploadImage(
                        newImage, householdId: firestore.householdId, name: filename) else {
                        uploadFailedAlert = true
                        return // Option A: abort save, show error — no silent drops
                    }
                    ImageCacheService.shared.store(newImage, for: url)
                    finalImageName = url
                } else {
                    if let savedName = ImageStorageService.shared.saveImage(newImage, name: filename) {
                        finalImageName = savedName // Use local var to bypass @State async timing delay
                    }
                }
            }

            if let guineaPig {
                guineaPig.name      = name
                guineaPig.birthDate = birthDate
                guineaPig.breed     = breed
                guineaPig.gender    = gender
                // Issue 5: Don't perpetuate cloud URLs in local mode — clear them so image shows as blank
                // rather than a broken placeholder
                if AppMode.current == .local, let name = finalImageName, name.hasPrefix("http") {
                    guineaPig.profileImageAssetName = nil
                } else if let finalImageName {
                    guineaPig.profileImageAssetName = finalImageName
                }
                
                try? modelContext.save() // Guarantee explicit save
                
                if AppMode.current == .cloud {
                    try? await firestore.savePig(guineaPig)
                }
            } else {
                let newPig = GuineaPig(name: name, birthDate: birthDate, breed: breed, gender: gender)
                // Issue 5: Don't persist cloud URLs for piggies created fresh in local mode
                if AppMode.current == .local, let name = finalImageName, name.hasPrefix("http") {
                    newPig.profileImageAssetName = nil
                } else {
                    newPig.profileImageAssetName = finalImageName
                }
                modelContext.insert(newPig)
                
                try? modelContext.save() // Guarantee explicit save
                
                if AppMode.current == .cloud {
                    try? await firestore.savePig(newPig)
                }
            }

            dismiss()
        }
    }
}
