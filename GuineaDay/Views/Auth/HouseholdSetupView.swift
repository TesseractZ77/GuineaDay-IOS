//
//  HouseholdSetupView.swift
//  GuineaDay
//
//  Created by Carol Zhou on 19/3/2026.
//

import SwiftUI

struct HouseholdSetupView: View {
    @StateObject private var session = AppSession.shared
    @EnvironmentObject var lang: LanguageManager
    @State private var inviteCodeInput = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        ZStack {
            Color.wallGray.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // ── Header ──
                    VStack(spacing: 6) {
                        Text(lang.setupTitle)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.inkBrown)
                        Text(lang.setupSubtitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.inkBrown.opacity(0.65))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 48)

                    // ── Error message ──
                    if let error = error {
                        Text(error)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.blushPink)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // ── Create new home card ──
                    VStack(spacing: 16) {
                        ChiikawaSectionHeader(title: lang.sectionStartFresh, color: .usagiYellow, icon: "house.fill")
                        Text(lang.startFreshDesc)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.inkBrown.opacity(0.75))
                            .multilineTextAlignment(.center)

                        if let code = session.inviteCode {
                            // ── Show code after creation ──
                            VStack(spacing: 8) {
                                Text(lang.shareCodePrompt)
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(.inkBrown.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                Text(code)
                                    .font(.system(size: 32, weight: .black, design: .monospaced))
                                    .foregroundColor(.inkBrown)
                                Button {
                                    UIPasteboard.general.string = code
                                } label: {
                                    Label(lang.copyCode, systemImage: "doc.on.doc.fill")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.inkBrown)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                }
                                .chiikawaCard(color: .usagiYellow, radius: 12)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        } else {
                            Button(action: {
                                Task {
                                    isLoading = true
                                    do { try await session.createHousehold() }
                                    catch { self.error = error.localizedDescription }
                                    isLoading = false
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text(lang.createNewHome)
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundColor(.inkBrown)
                            }
                            .chiikawaCard(color: .usagiYellow, radius: 16)
                            .disabled(isLoading)
                        }

                    }
                    .padding()
                    .chiikawaCard(color: .chiikawaWhite, radius: 24)
                    .padding(.horizontal)

                    // ── Divider ──
                    HStack {
                        Rectangle().fill(Color.inkBrown.opacity(0.2)).frame(height: 1.5)
                        Text(lang.orDivider).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.inkBrown.opacity(0.5))
                        Rectangle().fill(Color.inkBrown.opacity(0.2)).frame(height: 1.5)
                    }
                    .padding(.horizontal, 32)

                    // ── Join with invite code card ──
                    VStack(spacing: 16) {
                        ChiikawaSectionHeader(title: lang.sectionJoinHome, color: .hachiwareBlue, icon: "person.2.fill")
                        Text(lang.joinHomeDesc)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.inkBrown.opacity(0.75))
                            .multilineTextAlignment(.center)

                        // Styled text field
                        TextField("e.g. A3F9BC", text: $inviteCodeInput)
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.inkBrown)
                            .multilineTextAlignment(.center)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .chiikawaCard(color: .wallGray, radius: 16)

                        Button(action: {
                            Task {
                                isLoading = true
                                do { try await session.joinHousehold(code: inviteCodeInput) }
                                catch { self.error = error.localizedDescription }
                                isLoading = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text(lang.joinWithCode)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundColor(.inkBrown)
                        }
                        .chiikawaCard(color: .hachiwareBlue, radius: 16)
                        .disabled(inviteCodeInput.count < 4 || isLoading)
                        .opacity(inviteCodeInput.count < 4 ? 0.5 : 1)
                    }
                    .padding()
                    .chiikawaCard(color: .chiikawaWhite, radius: 24)
                    .padding(.horizontal)

                    Spacer().frame(height: 40)
                }
            }
        }
        .fontDesign(.rounded)
    }
}
