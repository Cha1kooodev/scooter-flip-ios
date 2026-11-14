import SwiftUI

enum SharingTab: String, CaseIterable, Identifiable {
    case numbers
    case stripping

    var id: String { rawValue }

    var title: String {
        switch self {
        case .numbers:   return "Номера"
        case .stripping: return "Разборка"
        }
    }
}

struct SharingView: View {
    @EnvironmentObject private var store: GameStore

    @State private var tab: SharingTab = .numbers

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScreenHeader(
                    title: "Шеринг",
                    subtitle: tab == .numbers ? "Редкость решает цену" : "Разборка и запчасти"
                )

                Picker("Раздел", selection: $tab) {
                    ForEach(SharingTab.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .tint(Color.accent)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                if tab == .numbers {
                    NumbersView()
                } else {
                    StrippingView()
                }
            }
        }
    }
}
