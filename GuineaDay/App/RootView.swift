//
//  RootView.swift
//  GuineaDay
//
//  Created by Carol Zhou on 19/3/2026.
//

import SwiftUI

struct RootView: View {
    @StateObject private var session = AppSession.shared

    var body: some View {
        Group {
            if session.startupFailed {
                // Bug 1: Firebase unreachable (e.g. blocked in mainland China)
                NetworkErrorView {
                    session.retrySignIn()
                }
            } else if !session.isSignedIn {
                // Silent auto sign-in — shows briefly while Firebase authenticates
                Color.wallGray.ignoresSafeArea()
                    .onAppear {
                        Task { try? await session.signInAnonymously() }
                    }
            } else if session.householdId == nil {
                HouseholdSetupView()
            } else if session.showingInviteCode, let code = session.inviteCode {
                inviteCodeScreen(code: code)
            } else {
                ContentView()
                    .environmentObject(FirestoreService(householdId: session.householdId!))
            }
        }
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
                    Text("Your Invite Code")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.inkBrown)
                    Text("Share this with your partner so they can join your home")
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
                        Label("Copy Code", systemImage: "doc.on.doc.fill")
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

                Button("Continue to App →") {
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

