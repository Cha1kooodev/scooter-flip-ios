import SwiftUI

struct StripLoot: Identifiable {
    let id = UUID()
    let parts: [PartKind]
}

struct StrippingView: View {
    @EnvironmentObject private var store: GameStore

    @State private var loot: StripLoot?
    @State private var caught = false
    @State private var confirmUnit: StreetUnit?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                warningCard

                HStack(spacing: 8) {
                    StatChip(title: "Скручено", value: "\(store.state.strips)")
                    StatChip(title: "Поймали", value: "\(store.state.caught)")
                    StatChip(title: "Деталей", value: "\(store.totalParts)")
                }

                if store.streetUnits.isEmpty {
                    nearbyEmpty
                } else {
                    SectionTitle(text: "Найдено рядом")

                    ForEach(store.streetUnits) { unit in
                        StreetUnitCard(unit: unit) {
                            confirmUnit = unit
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 26)
        }
        .confirmationDialog(
            "Скрутить детали?",
            isPresented: Binding(
                get: { confirmUnit != nil },
                set: { if !$0 { confirmUnit = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let unit = confirmUnit {
                Button("Скрутить с \(unit.model.name)", role: .destructive) {
                    let result = store.strip(unit)
                    confirmUnit = nil
                    switch result {
                    case .success(let parts):
                        loot = StripLoot(parts: parts)
                    case .caught:
                        caught = true
                    }
                }
            }
            Button("Отмена", role: .cancel) { confirmUnit = nil }
        } message: {
            Text("30% шанс, что поймает СБ — тогда изымут все самокаты из гаража.")
        }
        .sheet(item: $loot) { item in
            StripLootSheet(loot: item)
        }
        .alert("Поймала СБ", isPresented: $caught) {
            Button("Понял", role: .destructive) {}
        } message: {
            Text("Служба безопасности изъяла все самокаты из гаража. Деньги и запчасти остались.")
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
                title: "Скрутить детали",
                icon: "wrench.and.screwdriver.fill",
                color: .accent,
                action: action
            )
        }
        .cardStyle()
    }
}

struct StripLootSheet: View {
    @Environment(\.dismiss) private var dismiss

    let loot: StripLoot

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 14) {
                Spacer(minLength: 8)

                Text("Скрутили")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.textPrimary)

                Text("Детали на складе — можно чинить самокаты")
                    .font(.system(size: 11))
                    .foregroundColor(.muted)

                VStack(spacing: 8) {
                    ForEach(loot.parts) { part in
                        HStack(spacing: 10) {
                            PartArt(key: part.artKey)
                                .frame(width: 40, height: 40)
                                .padding(4)
                                .background(Color.panel2)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(part.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                Text(part.note)
                                    .font(.system(size: 10))
                                    .foregroundColor(.muted)
                            }

                            Spacer()

                            Text("+1")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundColor(.good)
                        }
                        .padding(10)
                        .background(Color.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 4)

                Spacer(minLength: 8)

                PrimaryActionButton(title: "На склад", icon: "shippingbox.fill") {
                    dismiss()
                }
            }
            .padding(20)
        }
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}
