import SwiftUI

struct StrippingView: View {
    @EnvironmentObject private var store: GameStore

    @State private var gameUnit: StreetUnit?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                warningCard

                HStack(spacing: 8) {
                    StatChip(title: "Скручено", value: "\(store.state.strips)")
                    StatChip(title: "Поймали", value: "\(store.state.caught)")
                    StatChip(title: "На прошивке", value: "\(store.unflashedCount)")
                }

                if !store.owns(.torx) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "screwdriver.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.warn)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Нужен набор торкс-бит")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textPrimary)
                            Text("Без него контроллер с деки не снять. Купи в «Магазине» → «Инструмент» за \(rub(ToolKind.torx.price)).")
                                .font(.system(size: 10))
                                .foregroundColor(.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .cardStyle()
                }

                if store.streetUnits.isEmpty {
                    nearbyEmpty
                } else {
                    SectionTitle(text: "Найдено рядом")

                    ForEach(store.streetUnits) { unit in
                        StreetUnitCard(unit: unit) {
                            gameUnit = unit
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 26)
        }
        .sheet(item: $gameUnit) { unit in
            StripGameView(unit: unit)
                .environmentObject(store)
        }
    }

    private var warningCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.bad)

            VStack(alignment: .leading, spacing: 4) {
                Text("Риск 30%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.bad)
                Text("Скручивай детали с шеринговых Ninebot: S90L и SNSC 2.0–2.4. " +
                     "В 30% случаев приезжает СБ и изымает все самокаты из гаража. " +
                     "Деньги и запчасти остаются.")
                    .font(.system(size: 11))
                    .foregroundColor(.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bad.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.bad.opacity(0.35), lineWidth: 1)
        )
    }

    private var nearbyEmpty: some View {
        VStack(spacing: 10) {
            EmptyStateView(
                icon: "mappin.slash",
                title: "Рядом пусто",
                text: "Все найденные самокаты уже разобраны. Поищи ещё."
            )
            PrimaryActionButton(title: "Искать ещё", icon: "location.magnifyingglass") {
                store.refreshStreet()
            }
        }
        .cardStyle()
    }
}

struct StreetUnitCard: View {
    let unit: StreetUnit
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ArtBanner(model: unit.model, plate: unit.plate?.code, height: 104)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(unit.model.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Label(unit.address, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 10))
                        .foregroundColor(.muted)
                }

                Spacer(minLength: 4)

                if let plate = unit.plate {
                    NumberBadge(plate: plate, compact: true)
                }
            }

            PrimaryActionButton(
                title: "Начать разборку",
                icon: "wrench.and.screwdriver.fill",
                color: .accent,
                action: action
            )
        }
        .cardStyle()
    }
}
