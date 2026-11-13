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
                .tabItem { Label("Запчасти", systemImage: "shippingbox.fill") }

            NumbersView()
                .tabItem { Label("Номера", systemImage: "number") }
        }
        .tint(Color.accent)
        .preferredColorScheme(.dark)
        .toolbarBackground(Color.appBg, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toast(store.toast)
    }
}
