import SwiftUI

// MARK: - Tab definition
enum AppTab: Int, CaseIterable {
    case home, duties, gallery, piggies, game

    var label: String {
        switch self {
        case .home:    return "Home"
        case .duties:  return "Duties"
        case .gallery: return "Gallery"
        case .piggies: return "Piggies"
        case .game:    return "Play"
        }
    }

    var icon: String {
        switch self {
        case .home:    return "house.fill"
        case .duties:  return "list.bullet.clipboard.fill"
        case .gallery: return "photo.stack.fill"
        case .piggies: return "pawprint.fill"
        case .game:    return "gamecontroller.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .home:    return .usagiYellow
        case .duties:  return .mintGreen
        case .gallery: return .lavenderPurple
        case .piggies: return .blushPink
        case .game:    return .peachOrange
        }
    }
}

// MARK: - Main ContentView
struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var firestore: FirestoreService
    @State private var syncManager: SyncManager?
    var body: some View {
        ZStack(alignment: .bottom) {
            // Page content
            ZStack {
                DashboardView(selectedTab: $selectedTab)
                    .opacity(selectedTab == .home ? 1 : 0)
                    .allowsHitTesting(selectedTab == .home)

                TaskListView()
                    .opacity(selectedTab == .duties ? 1 : 0)
                    .allowsHitTesting(selectedTab == .duties)

                GalleryView()
                    .opacity(selectedTab == .gallery ? 1 : 0)
                    .allowsHitTesting(selectedTab == .gallery)

                ProfileListView()
                    .opacity(selectedTab == .piggies ? 1 : 0)
                    .allowsHitTesting(selectedTab == .piggies)

                PiggyCrushView(selectedTab: $selectedTab)
                    .opacity(selectedTab == .game ? 1 : 0)
                    .allowsHitTesting(selectedTab == .game)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)


            // Floating Chiikawa Tab Bar
            ChiikawaTabBar(selected: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .ignoresSafeArea(edges: .bottom)
        .fontDesign(.rounded)
        .onAppear {
            if syncManager == nil && AppMode.current == .cloud {
                syncManager = SyncManager(modelContext: modelContext,
                                          householdId: firestore.householdId)
            }
        }
        .onDisappear {
            syncManager?.stopListeners()
            syncManager = nil
        }
    }
}

// MARK: - Chiikawa Floating Tab Bar
struct ChiikawaTabBar: View {
    @Binding var selected: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                TabBarButton(tab: tab, isSelected: selected == tab) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selected = tab
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color.chiikawaWhite)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.inkBrown, lineWidth: 3))
        .shadow(color: Color.inkBrown.opacity(0.55), radius: 0, x: 3, y: 4)
    }
}

// MARK: - Individual Tab Button
struct TabBarButton: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Yellow blob for selected tab
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(tab.accentColor)
                            .frame(width: 44, height: 34)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.inkBrown, lineWidth: 2))
                            .shadow(color: Color.inkBrown.opacity(0.4), radius: 0, x: 1, y: 2)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.inkBrown)
                        .scaleEffect(isSelected ? 1.1 : 0.9)
                }
                .frame(height: 34)

                Text(tab.label)
                    .font(.system(size: 9, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(Color.inkBrown)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
