//
//  StorageService.swift
//  GuineaDay
//
//  Created by Carol Zhou on 19/3/2026.
//

import UIKit
import FirebaseStorage

final class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage()
    
    func uploadImage(_ image: UIImage, householdId: String, name: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "GuineaDay", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not compress image"])
        }
        let ref = storage.reference().child("households/\(householdId)/\(name)")
        _ = try await ref.putDataAsync(data)
        let url = try await ref.downloadURL()
        return url.absoluteString // Store this URL in Firestore instead of the local filename
    }
    
    func downloadImage(urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return UIImage(data: data)
    }

}
