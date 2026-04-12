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

/// A member of the household returned from Firestore.
struct HouseholdMember: Identifiable {
    let id: String       // Firebase UID
    let nickname: String // display name, or "Member N" if unset
}

private let kHouseholdIdKey = "cached_householdId"

@MainActor
final class AppSession: ObservableObject {
    static let shared = AppSession()
    
    @Published var isSignedIn       = false
    @Published var householdId: String?  = nil
    @Published var inviteCode: String?   = nil
    @Published var showingInviteCode     = false
    @Published var startupFailed         = false  // Bug 1
    @Published var householdName: String? = nil    // Settings
    @Published var members: [HouseholdMember] = [] // Settings
    @Published var myNickname: String?   = nil     // Settings

    
    private let db = Firestore.firestore()
    private var authListener: AuthStateDidChangeListenerHandle?
    private var watchdogTask: Task<Void, Never>?  // Bug 1: startup timeout
    private var membershipListener: ListenerRegistration?  // watches household membership
    
    init() {
        // Pre-populate from cache so returning cloud users see no flash
        if let cachedHid = UserDefaults.standard.string(forKey: kHouseholdIdKey) {
            self.householdId = cachedHid
        }
        if Auth.auth().currentUser != nil {
            self.isSignedIn = true
        }
    }
    
    // MARK: - Cloud Services Setup/Teardown
    
    /// Boot up Firebase logic properly when in Cloud Mode
    func setupCloudServices() {
        guard authListener == nil else { return } // already running
        
        // Start watchdog — if not signed in within 8s, flag as failed
        if !isSignedIn {
            watchdogTask = Task {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                if !Task.isCancelled && !self.isSignedIn {
                    self.startupFailed = true
                }
            }
        }

        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.watchdogTask?.cancel()
                    self?.startupFailed = false
                    self?.isSignedIn = true
                    await self?.loadHousehold(for: user.uid)
                } else {
                    self?.isSignedIn = false
                    self?.householdId = nil
                    UserDefaults.standard.removeObject(forKey: kHouseholdIdKey)
                }
            }
        }
    }
    
    /// Halt background networking entirely when pivoting to Local Mode
    func teardownCloudServices() {
        watchdogTask?.cancel()
        watchdogTask = nil
        
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
        authListener = nil
        
        membershipListener?.remove()
        membershipListener = nil
        
        // Avoid lingering NetworkErrorView prompts
        startupFailed = false
    }
    
    // MARK: - Sign In Anonymously
    func signInAnonymously() async throws {
        try await Auth.auth().signInAnonymously()
    }

    // MARK: - Retry after network failure (Bug 1)
    func retrySignIn() {
        startupFailed = false
        // Restart watchdog
        watchdogTask = Task {
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            if !Task.isCancelled && !self.isSignedIn {
                self.startupFailed = true
            }
        }
        Task { try? await signInAnonymously() }
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
        self.showingInviteCode = true
        self.householdId = hid
        startMembershipListener(hid: hid, uid: uid)  // watch for being kicked
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
        startMembershipListener(hid: hid, uid: uid)  // watch for being kicked
    }
    
    // MARK: - Leave current household
    func leaveHousehold(modelContext: ModelContext) async {
        // Stop membership listener FIRST so it doesn't self-trigger handleKicked
        membershipListener?.remove()
        membershipListener = nil

        // remove current UID from household members
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
        // 1. Load user doc — only need householdId
        let userDoc = try? await db.collection("users").document(uid).getDocument()

        guard let hid = userDoc?.data()?["householdId"] as? String else {
            UserDefaults.standard.removeObject(forKey: kHouseholdIdKey)
            self.householdId = nil
            return
        }

        // 2. Load household doc
        let snap              = try? await db.collection("households").document(hid).getDocument()
        self.inviteCode       = snap?.data()?["inviteCode"]       as? String
        self.householdName    = snap?.data()?["name"]             as? String
        let memberUIDs        = snap?.data()?["members"]          as? [String] ?? []
        let nicknameMap       = snap?.data()?["memberNicknames"]  as? [String: String] ?? [:]

        // 3. Guard: if current UID is not in the members list, we were kicked
        guard memberUIDs.contains(uid) else {
            UserDefaults.standard.removeObject(forKey: kHouseholdIdKey)
            self.householdId = nil
            return
        }

        self.householdId = hid
        UserDefaults.standard.set(hid, forKey: kHouseholdIdKey)
        self.myNickname = nicknameMap[uid]
        self.members = memberUIDs.enumerated().map { index, memberUID in
            let name = nicknameMap[memberUID] ?? "Member \(index + 1)"
            return HouseholdMember(id: memberUID, nickname: name)
        }

        // 4. Start real-time listener so we detect future kicks instantly
        startMembershipListener(hid: hid, uid: uid)
    }

    // MARK: - Membership listener (detects being kicked in real-time)
    private func startMembershipListener(hid: String, uid: String) {
        membershipListener?.remove()
        membershipListener = db.collection("households").document(hid)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                Task { @MainActor in
                    let members = snap?.data()?["members"] as? [String] ?? []
                    if !members.contains(uid) {
                        await self.handleKicked()
                    }
                }
            }
    }

    /// Called when the real-time listener detects this device's UID is gone from members.
    private func handleKicked() async {
        membershipListener?.remove()
        membershipListener = nil
        UserDefaults.standard.removeObject(forKey: kHouseholdIdKey)
        householdId   = nil
        inviteCode    = nil
        householdName = nil
        members       = []
        myNickname    = nil
        // Sign out + new anonymous session → authListener fires → loadHousehold
        // → no householdId found → stays on HouseholdSetupView
        try? Auth.auth().signOut()
        try? await signInAnonymously()
    }

    // MARK: - Reload settings data (call when Settings sheet opens)
    func reloadSettings() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        await loadHousehold(for: uid)
    }

    // MARK: - Update household name
    func updateHouseholdName(_ name: String) async throws {
        guard let hid = householdId else { return }
        try await db.collection("households").document(hid).updateData(["name": name])
        self.householdName = name
    }

    // MARK: - Update own nickname
    func updateMyNickname(_ nickname: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid,
              let hid = householdId else { return }
        // Write into the household's shared memberNicknames map using dot-notation.
        // All household members can read this — no cross-user security rule issues.
        try await db.collection("households").document(hid).updateData([
            "memberNicknames.\(uid)": nickname
        ])
        self.myNickname = nickname
        members = members.map {
            $0.id == uid ? HouseholdMember(id: uid, nickname: nickname) : $0
        }
    }

    // MARK: - Remove a member from the household
    func removeMember(uid: String) async throws {
        guard let hid = householdId else { return }
        // 1. Remove UID from the household members array
        //    AND delete their entry from the shared nickname map
        try await db.collection("households").document(hid).updateData([
            "members":                        FieldValue.arrayRemove([uid]),
            "memberNicknames.\(uid)":          FieldValue.delete()
        ])
        // 2. Disconnect the user's own doc
        try? await db.collection("users").document(uid).updateData([
            "householdId": FieldValue.delete()
        ])
        // 3. Update local state
        members.removeAll { $0.id == uid }
    }
}
