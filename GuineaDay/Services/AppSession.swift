//
//  AppSession.swift
//  GuineaDay
//
//  Created by Carol Zhou on 19/3/2026.
//

import SwiftData
import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AppSession: ObservableObject {
    static let shared = AppSession()
    
    @Published var isSignedIn = false
    @Published var householdId: String? = nil
    @Published var inviteCode: String? = nil
    @Published var showingInviteCode = false

    
    private let db = Firestore.firestore()
    private var authListener: AuthStateDidChangeListenerHandle?
    
    init() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.isSignedIn = true
                    await self?.loadHousehold(for: user.uid)
                } else {
                    self?.isSignedIn = false
                    self?.householdId = nil
                }
            }
        }
    }
    
    // MARK: - Sign In Anonymously
    func signInAnonymously() async throws {
        try await Auth.auth().signInAnonymously()
    }
    
    // MARK: - Create a new household
    func createHousehold() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let code = String(UUID().uuidString.prefix(6).uppercased())
        let hid = db.collection("households").document().documentID
        try await db.collection("households").document(hid).setData([
            "members": [uid],
            "inviteCode": code,
            "createdAt": FieldValue.serverTimestamp()
        ])
        try await db.collection("users").document(uid).setData(["householdId": hid])
        self.inviteCode = code
        self.showingInviteCode = true   // ← show code BEFORE entering the app
        self.householdId = hid
    }

    
    // MARK: - Join an existing household via invite code
    func joinHousehold(code: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let snap = try await db.collection("households")
            .whereField("inviteCode", isEqualTo: code.uppercased())
            .getDocuments()
        guard let doc = snap.documents.first else {
            throw NSError(domain: "GuineaDay", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invite code not found"])
        }
        let hid = doc.documentID
        try await db.collection("households").document(hid).updateData([
            "members": FieldValue.arrayUnion([uid])
        ])
        try await db.collection("users").document(uid).setData(["householdId": hid])
        self.householdId = hid
        let householdDoc = try? await db.collection("households").document(hid).getDocument()
        self.inviteCode = householdDoc?.data()?["inviteCode"] as? String

    }
    
    // MARK: - Leave current household
    func leaveHousehold(modelContext: ModelContext) async {
        
        // remove current UID from household members BEFORE signing out
        if let uid = Auth.auth().currentUser?.uid, let hid = householdId {
            try? await db.collection("households").document(hid).updateData([
                "members": FieldValue.arrayRemove([uid])
            ])
        }
        // Clear all local SwiftData
        try? modelContext.delete(model: TaskItem.self)
        try? modelContext.delete(model: GuineaPig.self)
        try? modelContext.delete(model: Photo.self)
        try? modelContext.delete(model: WeightLog.self)
        try? modelContext.save()

        // Clear session state — RootView will transition to HouseholdSetupView
        householdId = nil
        inviteCode  = nil

        // Sign out and immediately sign in again as a new anonymous user
        try? Auth.auth().signOut()
        try? await signInAnonymously()
    }

    // MARK: - Load existing household for user
    private func loadHousehold(for uid: String) async {
        let doc = try? await db.collection("users").document(uid).getDocument()
        if let hid = doc?.data()?["householdId"] as? String {
            self.householdId = hid
            let snap = try? await db.collection("households").document(hid).getDocument()
            self.inviteCode = snap?.data()?["inviteCode"] as? String
        }
    }
}
