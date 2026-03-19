import SwiftUI
import SwiftData
import PhotosUI

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
    
    let breeds = ["American", "Abyssinian", "Peruvian", "Silkie", "Skinny", "Rex", "Texel"]
    let genders = ["Boar", "Sow"]
    
    init(guineaPig: GuineaPig? = nil) {
        self.guineaPig = guineaPig
        _name = State(initialValue: guineaPig?.name ?? "")
        _birthDate = State(initialValue: guineaPig?.birthDate ?? Date())
        _breed = State(initialValue: guineaPig?.breed ?? "American")
        _gender = State(initialValue: guineaPig?.gender ?? "Boar")
        _profileImageAssetName = State(initialValue: guineaPig?.profileImageAssetName)
        
        if let imageName = guineaPig?.profileImageAssetName {
            _selectedImage = State(initialValue: ImageStorageService.shared.loadImage(filename: imageName))
        }
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
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.inkBrown, lineWidth: 3))
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
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        selectedImage = uiImage
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical)
                    }
                    .listRowBackground(Color.chiikawaWhite)
                    
                    Section(header: Text("Details").foregroundStyle(Color.inkBrown)) {
                        TextField("Name", text: $name)
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
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveProfile() }
                        .foregroundStyle(Color.inkBrown)
                        .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveProfile() {
        if let newImage = selectedImage {
            // Give it a generic filename
            let filename = UUID().uuidString + ".jpg"
            if let savedFilename = ImageStorageService.shared.saveImage(newImage, name: filename) {
                // delete old one if updating
                if let oldFilename = profileImageAssetName {
                    ImageStorageService.shared.deleteImage(filename: oldFilename)
                }
                profileImageAssetName = savedFilename
            }
        }
        
        if let guineaPig {
                guineaPig.name = name
                guineaPig.birthDate = birthDate
                guineaPig.breed = breed
                guineaPig.gender = gender
                guineaPig.profileImageAssetName = profileImageAssetName
                Task { try? await firestore.savePig(guineaPig) }  // ← Firestore sync (update)
            } else {
                let newPig = GuineaPig(name: name, birthDate: birthDate, breed: breed, gender: gender)
                newPig.profileImageAssetName = profileImageAssetName
                modelContext.insert(newPig)
                Task { try? await firestore.savePig(newPig) }  // ← Firestore sync (create)
            }
            dismiss()
    }
}
