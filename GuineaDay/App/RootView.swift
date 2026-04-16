//
//  RootView.swift
//  GuineaDay
//
//  Created by Carol Zhou on 19/3/2026.
//

import SwiftUI

struct RootView: View {
    @StateObject private var session = AppSession.shared
    @StateObject private var lang = LanguageManager.shared
    // @AppStorage mirrors UserDefaults — any write auto-triggers re-render here
    @AppStorage("hasShownRegionSelector") private var hasShownRegionSelector = false
    @AppStorage("appMode")               private var appModeRaw              = ""

    var body: some View {
        Group {
            // ── 1. First launch: pick region ─────────────────────────────────
            if !hasShownRegionSelector {
                RegionSelectionView(onSelected: {})   // AppMode.set() writes the key → auto re-renders

            // ── 2. China Mainland: skip Firebase entirely ─────────────────────
            } else if AppMode.current == .local {
                ContentView()
                    .environmentObject(FirestoreService(householdId: "local"))  // all methods are no-ops

            // ── 3. International: full cloud flow ─────────────────────────────
            } else {
                ZStack {
                    if session.startupFailed {
                        NetworkErrorView { session.retrySignIn() }
                    } else if !session.isSignedIn {
                        Color.wallGray.ignoresSafeArea()
                            .onAppear { Task { try? await session.signInAnonymously() } }
                    } else if session.householdId == nil {
                        HouseholdSetupView()
                    } else if session.showingInviteCode, let code = session.inviteCode {
                        inviteCodeScreen(code: code)
                    } else {
                        ContentView()
                            .environmentObject(FirestoreService(householdId: session.householdId!))
                    }
                }
                .onAppear {
                    session.setupCloudServices()
                }
            }
        }
        .environmentObject(lang)  // all descendant views can access via @EnvironmentObject var lang: LanguageManager
        .animation(.easeInOut, value: hasShownRegionSelector)
        .animation(.easeInOut, value: appModeRaw)
        .animation(.easeInOut, value: session.startupFailed)
        .animation(.easeInOut, value: session.isSignedIn)
        .animation(.easeInOut, value: session.householdId)
        .animation(.easeInOut, value: session.showingInviteCode)
    }

    // MARK: - Invite Code Screen (shown once after household creation)
    @ViewBuilder
    private func inviteCodeScreen(code: String) -> some View {
        ZStack {
            Color.wallGray.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("🏡")
                    .font(.system(size: 64))

                VStack(spacing: 8) {
                    Text(lang.inviteCodeTitle)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.inkBrown)
                    Text(lang.inviteCodeSubtitle)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.inkBrown.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Code display card
                VStack(spacing: 16) {
                    Text(code)
                        .font(.system(size: 44, weight: .black, design: .monospaced))
                        .foregroundColor(.inkBrown)
                        .tracking(8)

                    Button {
                        UIPasteboard.general.string = code
                    } label: {
                        Label(lang.copyCode, systemImage: "doc.on.doc.fill")
                            .fontWeight(.bold)
                            .foregroundColor(.inkBrown)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .chiikawaCard(color: .usagiYellow, radius: 16)
                }
                .padding(24)
                .chiikawaCard(color: .chiikawaWhite, radius: 24)
                .padding(.horizontal)

                Spacer()

                Button(lang.continueToApp) {
                    session.showingInviteCode = false
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.inkBrown.opacity(0.6))
                .padding(.bottom, 48)
            }
        }
        .fontDesign(.rounded)
    }
}

