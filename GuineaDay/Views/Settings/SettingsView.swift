import SwiftUI
import SwiftData
import FirebaseAuth

struct SettingsView: View {
    @StateObject private var session = AppSession.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var householdName    = ""
    @State private var myNickname       = ""
    @State private var isSavingName     = false
    @State private var isSavingNickname = false
    @State private var codeCopied       = false
    @State private var showLeaveAlert   = false
    @State private var memberToRemove: HouseholdMember? = nil
    @State private var isLoading               = true
    @State private var showRegionChangeAlert   = false
    @AppStorage("appMode") private var appModeRaw = ""

    private var currentUID: String? { Auth.auth().currentUser?.uid }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1"
//        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v)"
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color.wallGray.ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(Color.inkBrown)
                            .scaleEffect(1.2)
                        Text("Loading…")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color.inkBrown.opacity(0.5))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {

                            // ─── 📍 Region ─────────────── always visible ──
                            settingsSection(title: "📍 Region") {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(AppMode.current == .local ? "🇨🇳 China Mainland" : "🌏 International")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color.inkBrown)
                                        Text(AppMode.current == .local ? "Local only · 本地存储" : "Cloud sync enabled")
                                            .font(.system(size: 11, design: .rounded))
                                            .foregroundColor(Color.inkBrown.opacity(0.45))
                                    }
                                    Spacer()
                                    Button("Change") { showRegionChangeAlert = true }
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(Color.hachiwareBlue)
                                }
                            }

                            // ─── Cloud-only sections ──────────────────────
                            if AppMode.current == .cloud {

                                // 🏡 Our Home
                                settingsSection(title: "🏡 \(session.householdName ?? "Our Home")") {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("HOUSEHOLD NAME").settingsLabel()
                                        HStack {
                                            TextField("Give your home a name…", text: $householdName)
                                                .font(.system(size: 15, design: .rounded))
                                                .foregroundColor(Color.inkBrown)
                                                .submitLabel(.done)
                                                .onSubmit { Task { await saveHouseholdName() } }
                                            if isSavingName {
                                                ProgressView().tint(Color.inkBrown)
                                            } else {
                                                Button("Save") { Task { await saveHouseholdName() } }
                                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                                    .foregroundColor(householdName.trimmed.isEmpty
                                                                     ? Color.inkBrown.opacity(0.3) : Color.inkBrown)
                                                    .disabled(householdName.trimmed.isEmpty)
                                            }
                                        }
                                        Divider().background(Color.inkBrown.opacity(0.15))
                                    }
                                    if let code = session.inviteCode {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("INVITE CODE").settingsLabel()
                                            HStack {
                                                Text(code)
                                                    .font(.system(size: 22, weight: .black, design: .monospaced))
                                                    .foregroundColor(Color.inkBrown)
                                                    .tracking(4)
                                                Spacer()
                                                Button {
                                                    UIPasteboard.general.string = code
                                                    withAnimation { codeCopied = true }
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                        withAnimation { codeCopied = false }
                                                    }
                                                } label: {
                                                    Image(systemName: codeCopied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                                        .font(.system(size: 22))
                                                        .foregroundColor(codeCopied ? Color.mintGreen : Color.inkBrown)
                                                }
                                            }
                                        }
                                    }
                                }

                                // 👥 Members
                                settingsSection(title: "👥 Members") {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("MY NICKNAME").settingsLabel()
                                        HStack {
                                            TextField("Set your nickname…", text: $myNickname)
                                                .font(.system(size: 15, design: .rounded))
                                                .foregroundColor(Color.inkBrown)
                                                .submitLabel(.done)
                                                .onSubmit { Task { await saveNickname() } }
                                            if isSavingNickname {
                                                ProgressView().tint(Color.inkBrown)
                                            } else {
                                                Button("Save") { Task { await saveNickname() } }
                                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                                    .foregroundColor(myNickname.trimmed.isEmpty
                                                                     ? Color.inkBrown.opacity(0.3) : Color.inkBrown)
                                                    .disabled(myNickname.trimmed.isEmpty)
                                            }
                                        }
                                    }
                                    if !session.members.isEmpty {
                                        Divider().background(Color.inkBrown.opacity(0.15)).padding(.vertical, 2)
                                        Text("IN THIS HOUSEHOLD").settingsLabel()
                                        VStack(spacing: 10) {
                                            ForEach(session.members) { member in
                                                let isMe = member.id == currentUID
                                                HStack(spacing: 12) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(isMe ? Color.usagiYellow : Color.blushPink)
                                                            .frame(width: 36, height: 36)
                                                            .overlay(Circle().stroke(Color.inkBrown, lineWidth: 2))
                                                        Text(String(member.nickname.prefix(1)).uppercased())
                                                            .font(.system(size: 14, weight: .black, design: .rounded))
                                                            .foregroundColor(Color.inkBrown)
                                                    }
                                                    VStack(alignment: .leading, spacing: 1) {
                                                        Text(member.nickname)
                                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                            .foregroundColor(Color.inkBrown)
                                                        if isMe {
                                                            Text("You")
                                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                                                .foregroundColor(Color.hachiwareBlue)
                                                        }
                                                    }
                                                    Spacer()
                                                    if !isMe {
                                                        Button { memberToRemove = member } label: {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .font(.system(size: 20))
                                                                .foregroundColor(Color.blushPink.opacity(0.8))
                                                        }
                                                        .buttonStyle(.plain)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // 🚪 Account (leave household)
                                settingsSection(title: "Account") {
                                    Button(role: .destructive) { showLeaveAlert = true } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                            Text("Leave Household")
                                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        }
                                        .foregroundColor(.red.opacity(0.8))
                                    }
                                }

                            } // end if .cloud

                            // ─── ℹ️ About ─────────────── always visible ──
                            settingsSection(title: "ℹ️ About") {
                                HStack {
                                    Text("App Version")
                                        .font(.system(size: 15, design: .rounded))
                                        .foregroundColor(Color.inkBrown)
                                    Spacer()
                                    Text(appVersion)
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundColor(Color.inkBrown.opacity(0.45))
                                }
                            }

                            Spacer().frame(height: 24)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color.inkBrown)
                }
            }
        }
        .task {
            guard AppMode.current == .cloud else {
                isLoading = false  // nothing to fetch in local mode
                return
            }
            await session.reloadSettings()
            householdName = session.householdName ?? ""
            myNickname    = session.myNickname    ?? ""
            isLoading     = false
        }
        .alert("Leave Household?", isPresented: $showLeaveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                Task {
                    await session.leaveHousehold(modelContext: modelContext)
                    dismiss()
                }
            }
        } message: {
            Text("Your local data will be cleared. You can join or create a new household.")
        }
        .alert("Remove \(memberToRemove?.nickname ?? "this member")?",
               isPresented: Binding(get: { memberToRemove != nil }, set: { if !$0 { memberToRemove = nil } })) {
            Button("Cancel", role: .cancel) { memberToRemove = nil }
            Button("Remove", role: .destructive) {
                if let m = memberToRemove {
                    Task { try? await session.removeMember(uid: m.id) }
                    memberToRemove = nil
                }
            }
        } message: {
            Text("They will be removed from the household. This cannot be undone.")
        }
        .alert("Change Region?", isPresented: $showRegionChangeAlert) {
            Button("Cancel", role: .cancel) {}
            Button(AppMode.current == .local ? "Switch to International" : "Switch to China Mainland") {
                if AppMode.current == .local {
                    // Switching to Cloud
                    AppSession.shared.setupCloudServices()
                    AppMode.set(.cloud)
                } else {
                    // Switching to Local
                    AppSession.shared.teardownCloudServices()
                    AppMode.set(.local)
                }
                dismiss()
            }
        } message: {
            if AppMode.current == .local {
                Text("Switching to International will enable cloud sync and household features. You'll need to sign in and join or create a household.")
            } else {
                Text("Switching to China Mainland will pause cloud sync. The app will run on local storage only. Data added while in local mode won't sync back automatically.")
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Color.inkBrown.opacity(0.45))
                .padding(.leading, 4)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.chiikawaWhite)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.inkBrown, lineWidth: 2.5))
            .shadow(color: Color.inkBrown.opacity(0.3), radius: 0, x: 2, y: 3)
        }
    }

    private func saveHouseholdName() async {
        let name = householdName.trimmed
        guard !name.isEmpty else { return }
        isSavingName = true
        try? await session.updateHouseholdName(name)
        isSavingName = false
    }

    private func saveNickname() async {
        let nickname = myNickname.trimmed
        guard !nickname.isEmpty else { return }
        isSavingNickname = true
        try? await session.updateMyNickname(nickname)
        isSavingNickname = false
    }
}

// MARK: - Helpers
private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespaces) }
}

private extension Text {
    func settingsLabel() -> some View {
        self.font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(Color.inkBrown.opacity(0.45))
            .textCase(.uppercase)
    }
}

#Preview {
    SettingsView()
}
