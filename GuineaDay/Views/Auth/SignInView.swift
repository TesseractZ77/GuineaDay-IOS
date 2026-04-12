//
//  SignInView.swift
//  GuineaDay
//
//  Created by Carol Zhou on 19/3/2026.
//

import SwiftUI

struct SignInView: View {
    @StateObject private var session = AppSession.shared
    @State private var isLoading = false
    @State private var error: String?

    private let sparkles: [(x: CGFloat, y: CGFloat, size: CGFloat, color: Color)] = [
        (0.10, 0.12, 14, .blushPink),
        (0.88, 0.10, 10, .hachiwareBlue),
        (0.15, 0.60, 12, .usagiYellow),
        (0.85, 0.50, 16, .mintGreen),
        (0.50, 0.07, 10, .lavenderPurple),
    ]

    var body: some View {
        ZStack {
            Color.wallGray.ignoresSafeArea()

            GeometryReader { geo in
                ForEach(sparkles.indices, id: \.self) { i in
                    let s = sparkles[i]
                    SparkleView(size: s.size, color: s.color)
                        .position(x: s.x * geo.size.width, y: s.y * geo.size.height)
                }
            }
            .allowsHitTesting(false)

            VStack(spacing: 32) {
                Spacer()

                // ── Welcome card ──
                ZStack {
                    LinearGradient(
                        colors: [Color.usagiYellow, Color.blushPink.opacity(0.5)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    VStack(spacing: 12) {
                        Image("kui")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.inkBrown.opacity(0.3), radius: 0, x: 2, y: 3)
                        Text("GuineaDay")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.inkBrown)
                        Text("Track your piggies together!")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.inkBrown.opacity(0.75))
                    }
                    .padding(.vertical, 36)
                }
                .chiikawaCard(color: .clear, radius: 28)
                .padding(.horizontal)

                Spacer()

                if let error = error {
                    Text(error)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.blushPink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // ── Get Started button ──
                Button(action: {
                    Task {
                        isLoading = true
                        do { try await session.signInAnonymously() }
                        catch { self.error = error.localizedDescription }
                        isLoading = false
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "pawprint.fill")
                        }
                        Text(isLoading ? "Starting…" : "Get Started")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundColor(.inkBrown)
                }
                .chiikawaCard(color: .usagiYellow, radius: 16)
                .padding(.horizontal)
                .disabled(isLoading)

                Spacer().frame(height: 40)
            }
        }
        .fontDesign(.rounded)
    }
}
