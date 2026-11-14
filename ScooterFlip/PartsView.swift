import SwiftUI

enum PartsTab: String, CaseIterable, Identifiable {
    case repair
    case tuning

    var id: String { rawValue }

    var title: String {
        switch self {
        case .repair: return "Ремонт"
        case .tuning: return "Тюнинг"
        }
    }
}

struct PartsView: View {
    @EnvironmentObject private var store: GameStore

    @State private var tab: PartsTab = .repair
    @State private var installTarget: UpgradeKind?

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScreenHeader(title: "Магазин", subtitle: "Запчасти и тюнинг")

                ScrollView {
                    VStack(spacing: 12) {
                        Picker("Раздел", selection: $tab) {
                            ForEach(PartsTab.allCases) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(Color.accent)

                        if tab == .repair {
                            repairSection
                        } else {
                            tuningSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 26)
                }
            }
        }
        .sheet(item: $installTarget) { kind in
            UpgradeInstallSheet(kind: kind)
                .environmentObject(store)
        }
    }

    // MARK: Ремонт

    @ViewBuilder
    private var repairSection: some View {
        InfoCard(
            text: "Для ремонта нужна конкретная деталь — при починке она списывается со склада. " +
                  "Детали дешевле покупать заранее."
        )

        ForEach(PartKind.allCases) { part in
            PartRow(part: part)
        }
    }

    // MARK: Тюнинг

    @ViewBuilder
    private var tuningSection: some View {
        InfoCard(
            text: "Железо ставится на конкретный самокат в гараже или прямо отсюда. " +
                  "Каждый апгрейд добавляет процент к цене при продаже."
        )

        if store.state.scooters.isEmpty {
            EmptyStateView(
                icon: "cart",
                title: "Пока не на что ставить",
                text: "Сначала купи самокат на Авито."
            )
        } else {
            ForEach(UpgradeKind.allCases) { kind in
                UpgradeShopCard(kind: kind) {
                    installTarget = kind
                }
            }
        }
    }
}

// MARK: - Деталь на складе

struct PartRow: View {
    @EnvironmentObject private var store: GameStore

    let part: PartKind

    private var count: Int { store.stock(of: part) }
    private var canAfford: Bool { store.state.money >= part.price }

    var body: some View {
        HStack(spacing: 11) {
            PartArt(key: part.artKey)
                .frame(width: 46, height: 46)
                .padding(5)
                .background(Color.panel2)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.line, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(part.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(part.note)
                    .font(.system(size: 10))
                    .foregroundColor(.muted)
                Text("на складе: \(count) шт.")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(count > 0 ? .good : .muted)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 6) {
                Text(rub(part.price))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.textPrimary)

                Button {
                    store.buyPart(part)
                } label: {
                    Text("Купить")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(canAfford ? .appBg : .muted)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(canAfford ? Color.accent : Color.panel2)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableStyle())
                .disabled(!canAfford)
            }
        }
        .cardStyle()
    }
}

// MARK: - Апгрейд в магазине

struct UpgradeShopCard: View {
    @EnvironmentObject private var store: GameStore

    let kind: UpgradeKind
    let action: () -> Void

    private var minPrice: Int? {
        store.state.scooters
            .map { store.upgradeCost(kind, for: $0) }
            .min()
    }

    private var installedCount: Int {
        store.state.scooters.filter { $0.has(kind) }.count
    }

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            PartArt(key: kind.artKey)
                .frame(width: 52, height: 52)
                .padding(6)
                .background(Color.panel2)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color.line, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(kind.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(kind.detail)
                    .font(.system(size: 10))
                    .foregroundColor(.muted)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Tag(text: kind.bonusText, color: .good)
                    if installedCount > 0 {
                        Tag(text: "стоит: \(installedCount)", color: .muted)
                    }
                }
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 6) {
                Text(minPrice.map { "от \(rub($0))" } ?? "—")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.trailing)

                Button(action: action) {
                    Text("Ставить")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.appBg)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Color.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableStyle())
            }
        }
        .cardStyle()
    }
}

// MARK: - Выбор самоката

struct UpgradeInstallSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let kind: UpgradeKind

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            PartArt(key: kind.artKey)
                                .frame(width: 56, height: 56)
                                .padding(6)
                                .background(Color.panel2)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(kind.title)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.textPrimary)
                                Text(kind.detail)
                                    .font(.system(size: 11))
                                    .foregroundColor(.muted)
                                Text(kind.bonusText)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.good)
                            }
                            Spacer(minLength: 0)
                        }
                        .cardStyle()

                        if store.state.scooters.isEmpty {
                            EmptyStateView(
                                icon: "scooter",
                                title: "Гараж пуст",
                                text: "Купи самокат, чтобы ставить железо."
                            )
                        } else {
                            ForEach(store.state.scooters) { scooter in
                                scooterRow(scooter)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Куда ставим?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") { dismiss() }
                        .foregroundColor(.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func scooterRow(_ scooter: OwnedScooter) -> some View {
        let installed = scooter.has(kind)
        let cost = store.upgradeCost(kind, for: scooter)
        let affordable = store.state.money >= cost

        return HStack(spacing: 10) {
            ScooterVisual(model: scooter.model, plate: scooter.number?.code)
                .frame(width: 88, height: 46)
                .background(Color.panel2)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(scooter.model.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if installed {
                    Text("Уже установлено")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.good)
                } else {
                    Text(rub(cost))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(affordable ? .accent : .bad)
                }
            }

            Spacer(minLength: 4)

            Button {
                store.installUpgrade(kind, id: scooter.id)
                dismiss()
            } label: {
                Text(installed ? "Готово" : "Ставить")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(installed ? .good : (affordable ? .appBg : .muted))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(installed ? Color.good.opacity(0.15) : (affordable ? Color.accent : Color.panel2))
                    .clipShape(Capsule())
            }
            .buttonStyle(PressableStyle())
            .disabled(installed || !affordable)
        }
        .cardStyle(padding: 10, corner: 14)
    }
}
