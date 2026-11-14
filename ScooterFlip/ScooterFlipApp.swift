import SwiftUI

@main
struct ScooterFlipApp: App {
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        TabView {
            MarketView()
                .tabItem { Label("Авито", systemImage: "bag.fill") }

            GarageView()
                .tabItem { Label("Гараж", systemImage: "wrench.and.screwdriver.fill") }

            PartsView()
                .tabItem { Label("Магазин", systemImage: "shippingbox.fill") }

            SharingView()
                .tabItem { Label("Шеринг", systemImage: "number") }

            ProfileView()
                .tabItem { Label("Профиль", systemImage: "person.crop.circle.fill") }
        }
        .tint(Color.accent)
        .preferredColorScheme(.dark)
        .toolbarBackground(Color.appBg, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toast(store.toast)
    }
}
