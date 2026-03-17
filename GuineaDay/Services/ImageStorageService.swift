import SwiftUI

final class ImageStorageService {
    static let shared = ImageStorageService()
    
    private init() {}
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func saveImage(_ image: UIImage, name: String) -> String? {
        // Compress image slightly to save space
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let url = getDocumentsDirectory().appendingPathComponent(name)
        
        do {
            try data.write(to: url)
            return name
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return nil
        }
    }
    
    func loadImage(filename: String) -> UIImage? {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        if let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }
    
    func deleteImage(filename: String) {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            print("Error deleting image: \(error.localizedDescription)")
        }
    }
}
