import SwiftUI
import UIKit

enum MainTab: Hashable {
    case guide, map, profile, promoter, admin, venueManager
    
    var title: String {
        switch self {
        case .guide: "GUIDE"
        case .map: "MAP"
        case .profile: "PROFILE"
        case .promoter: "PROMOTER"
        case .admin: "ADMIN"
        case .venueManager: "MANAGER"
        }
    }
    
    var systemImage: String {
        switch self {
        case .guide: "list.star"
        case .map: "map"
        case .profile: "person"
        case .promoter: "chart.bar.fill"
        case .admin: "shield.fill"
        case .venueManager: "building.2.fill"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var localeManager: LocalizationManager
    @EnvironmentObject var chatManager: ConciergeChatManager
    @State private var selection: MainTab = .guide
    @State private var impactGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var lastChatUserId: String?
    @State private var showForYou: Bool = false
    
    private var unreadMessageCount: Int {
        chatManager.chatThreads.reduce(0) { $0 + $1.unreadCount }
    }
    
    private var tabs: [MainTab] {
        var base: [MainTab] = [.guide, .map, .profile]
        if authManager.userRole == .promoter { base.append(.promoter) }
        if authManager.userRole == .admin { base.append(.admin) }
        if authManager.userRole == .venueManager { base.append(.venueManager) }
        
        return base
    }
    
    var body: some View {
        TabView(selection: $selection) {
            ForEach(tabs, id: \.self) { tab in
                makeTabContent(for: tab)
                    .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                    .tag(tab)
            }
        }
        .sheet(isPresented: $showForYou) { ForYouView() }
        .tint(Color.theme.accent)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.92), Color.theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onChange(of: authManager.userRole) { _, _ in
            if !tabs.contains(selection) {
                selection = .guide
            }
        }
        .onChange(of: selection) { _, _ in
            impactGenerator.impactOccurred()
            impactGenerator.prepare()
        }
        .onAppear {
            if let userId = authManager.user?.id, userId != lastChatUserId {
                chatManager.initialize(for: userId)
                lastChatUserId = userId
            }
            impactGenerator.prepare()
        }
        .environment(\.layoutDirection, localeManager.usesRTL ? .rightToLeft : .leftToRight)
    }

    @ViewBuilder
    private func makeTabContent(for tab: MainTab) -> some View {
        if tab == .guide {
            let forYouText = localeManager.localized("For You")
            ZStack(alignment: .bottomTrailing) {
                tabContent(for: tab)
                Button {
                    showForYou = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text(forYouText).bold()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
                .accessibilityLabel("For You")
            }
        } else {
            tabContent(for: tab)
        }
    }
    
    @ViewBuilder
    private func tabContent(for tab: MainTab) -> some View {
        switch tab {
        case .guide:
            VenueListView()
        case .map:
            VenueMapView()
        case .profile:
            ProfileView()
        case .promoter:
            PromoterDashboardView()
        case .admin:
            AdminView()
        case .venueManager:
            VenueManagerDashboardView()
        }
    }
}
