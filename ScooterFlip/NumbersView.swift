import SwiftUI

struct NumberResult: Identifiable {
    let id = UUID()
    let plate: NumberPlate
    let scooterName: String
}

struct NumbersView: View {
    @EnvironmentObject private var store: GameStore

    @State private var rollingID: UUID?
    @State private var ticker = NumberFactory.randomCommonCode()
    @State private var result: NumberResult?

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScreenHeader(title: "Номера", subtitle: "Редкость решает цену")

                ScrollView {
                    VStack(spacing: 12) {
                        InfoCard(
                            text: "Номера выбиваются только на шеринговых самокатах. " +
                                  "Чем реже номер — тем дороже самокат: редкий даёт +30 000 ₽, " +
                                  "а легендарный вроде 777-777 — +300 000 ₽."
                        )

                        bestCard

                        rarityCard

                        HStack {
                            SectionTitle(text: "Шеринговые самокаты")
                            Spacer()
                            Text("выбито: \(store.state.rolls)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.muted)
                        }

                        if store.sharingScooters.isEmpty {
                            EmptyStateView(
                                icon: "number",
                                title: "Нет шеринговых самокатов",
                                text: "Купи модель с пометкой «Шеринг» на Авито — и сможешь выбить ей номер."
                            )
                        } else {
                            ForEach(store.sharingScooters) { scooter in
                                NumberScooterCard(
                                    scooter: scooter,
                                    isRolling: rollingID == scooter.id,
                                    ticker: ticker
                                ) {
                                    roll(scooter)
                                }
                                .opacity(rollingID == nil || rollingID == scooter.id ? 1 : 0.55)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 26)
                }
            }
        }
        .sheet(item: $result) { item in
            NumberResultSheet(result: item)
        }
    }

    // MARK: Секции

    @ViewBuilder
    private var bestCard: some View {
        if let best = store.state.bestNumber {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Лучший номер")
                        .font(.system(size: 11))
                        .foregroundColor(.muted)
                    Text(best.rarity.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(best.rarity.color)
                }
                Spacer()
                NumberBadge(plate: best)
            }
            .cardStyle()
        }
    }

    private var rarityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Редкость и надбавка")

            ForEach(NumberRarity.allCases) { rarity in
                HStack(spacing: 8) {
                    Circle()
                        .fill(rarity.color)
                        .frame(width: 7, height: 7)
                    Text(rarity.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text(rarity.bonus == 0 ? "без надбавки" : "+ \(rub(rarity.bonus))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(rarity.bonus == 0 ? .muted : rarity.color)
                }
            }
        }
        .cardStyle()
    }

    // MARK: Выбивание

    private func roll(_ scooter: OwnedScooter) {
        guard rollingID == nil else { return }
        guard let outcome = store.prepareRoll(for: scooter.id) else { return }

        rollingID = scooter.id
        Task { @MainActor in
            for _ in 0..<15 {
                ticker = NumberFactory.randomCommonCode()
                try? await Task.sleep(nanoseconds: 65_000_000)
            }
            store.commitRoll(outcome)
            rollingID = nil
            result = NumberResult(plate: outcome.plate, scooterName: scooter.model.name)
        }
    }
}

struct NumberScooterCard: View {
    @EnvironmentObject private var store: GameStore

    let scooter: OwnedScooter
    let isRolling: Bool
    let ticker: String
    let onRoll: () -> Void

    private var cost: Int { store.rollCost(for: scooter) }
    private var canAfford: Bool { store.state.money >= cost }

    private var displayCode: String {
        if isRolling { return ticker }
        return scooter.number?.code ?? "— — —"
    }

    private var displayColor: Color {
        if isRolling { return .textPrimary }
        return scooter.number?.rarity.color ?? .muted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 11) {
                ScooterIconTile(model: scooter.model, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(scooter.model.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let number = scooter.number {
                        Text("\(number.rarity.title) · + \(rub(number.rarity.bonus)) к цене")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(number.rarity.color)
                    } else {
                        Text("Номер не выбит")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.muted)
                    }
                }

                Spacer(minLength: 0)
            }

            Text(displayCode)
                .font(.system(size: 30, weight: .heavy, design: .monospaced))
                .foregroundColor(displayColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.panel2)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(displayColor.opacity(isRolling ? 0.2 : 0.45), lineWidth: 1)
                )
                .animation(.easeOut(duration: 0.1), value: displayCode)

            PrimaryActionButton(
                title: isRolling
                    ? "Выбиваем…"
                    : (scooter.number == nil
                        ? "Выбить номер · \(rub(cost))"
                        : "Перебить номер · \(rub(cost))"),
                icon: "number.circle.fill",
                enabled: !isRolling && canAfford,
                action: onRoll
            )
        }
        .cardStyle()
    }
}

struct NumberResultSheet: View {
    @Environment(\.dismiss) private var dismiss

    let result: NumberResult

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 14) {
                Spacer(minLength: 8)

                if result.plate.rarity == .legendary {
                    Text("🎉 ЛЕГЕНДА!")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(.accent)
                } else {
                    Text("Номер выбит")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.muted)
                }

                Text(result.plate.code)
                    .font(.system(size: 46, weight: .heavy, design: .monospaced))
                    .foregroundColor(result.plate.rarity.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 12)

                Text(result.plate.rarity.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(result.plate.rarity.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(result.plate.rarity.color.opacity(0.15))
                    .clipShape(Capsule())

                Text(result.plate.rarity.bonus == 0
                     ? "Без надбавки к цене"
                     : "+ \(rub(result.plate.rarity.bonus)) к цене самоката")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text("Установлен на \(result.scooterName)")
                    .font(.system(size: 11))
                    .foregroundColor(.muted)
                    .multilineTextAlignment(.center)

                Spacer(minLength: 8)

                PrimaryActionButton(title: "Забрать", icon: "checkmark") {
                    dismiss()
                }
            }
            .padding(20)
        }
        .presentationDetents([.height(390)])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}
