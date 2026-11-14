import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: GameStore

    @State private var confirmReset = false
    @FocusState private var nameFocused: Bool

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScreenHeader(title: "Профиль", subtitle: "Статистика игрока")

                ScrollView {
                    VStack(spacing: 12) {
                        identityCard
                        moneyCard
                        statsGrid
                        journeyCard
                        InfoCard(
                            text: "Аккаунты и облачные сохранения появятся в следующих версиях. " +
                                  "Пока прогресс хранится локально на этом iPhone."
                        )
                        resetButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
        }
        .confirmationDialog("Сбросить прогресс?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Удалить всё", role: .destructive) {
                store.resetProgress()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Деньги, гараж, запчасти и номера обнулятся. Это нельзя отменить.")
        }
    }

    // MARK: Личность

    private var identityCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                avatar

                VStack(alignment: .leading, spacing: 6) {
                    TextField("Имя игрока", text: nameBinding)
                        .font(.system(size: 21, weight: .heavy))
                        .foregroundColor(.textPrimary)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($nameFocused)
                        .submitLabel(.done)
                        .onSubmit { nameFocused = false }

                    HStack(spacing: 6) {
                        Tag(text: store.level.title, color: .accent)
                        Text("ур. \(store.levelIndex + 1)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.muted)
                    }

                    if let next = store.nextLevel {
                        Text("до «\(next.title)»: \(rub(max(0, next.need - store.state.profit)))")
                            .font(.system(size: 10))
                            .foregroundColor(.muted)
                    } else {
                        Text("Максимальный уровень")
                            .font(.system(size: 10))
                            .foregroundColor(.good)
                    }
                }

                Spacer(minLength: 0)
            }

            MeterBar(value: store.levelProgress * 100, color: .accent)
        }
        .cardStyle()
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xFFD400), Color(hex: 0xF59E0B)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(initials)
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(.appBg)
        }
        .frame(width: 72, height: 72)
        .overlay(
            Circle()
                .trim(from: 0, to: max(0.03, store.levelProgress))
                .stroke(Color.good, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(-6)
        )
    }

    private var initials: String {
        let parts = store.state.playerName.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init).joined()
        return letters.isEmpty ? "Р" : letters.uppercased()
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { store.state.playerName },
            set: { store.setPlayerName($0) }
        )
    }

    // MARK: Деньги

    private var moneyCard: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Чистая прибыль")
                        .font(.system(size: 11))
                        .foregroundColor(.muted)
                    Text(signedRub(store.state.profit))
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(store.state.profit >= 0 ? .good : .bad)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("На руках")
                        .font(.system(size: 11))
                        .foregroundColor(.muted)
                    Text(rub(store.state.money))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.accent)
                }
            }

            Rectangle()
                .fill(Color.line)
                .frame(height: 1)

            HStack(spacing: 8) {
                miniStat("Заработано", rub(store.state.totalEarned), .good)
                miniStat("Потрачено", rub(store.state.totalSpent), .bad)
                miniStat("Капитал", rub(store.netWorth), .textPrimary)
            }
        }
        .cardStyle()
    }

    private func miniStat(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(.muted)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Статистика

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle(text: "Цифры")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                spacing: 8
            ) {
                StatTile(icon: "cart.fill", title: "Куплено", value: "\(store.state.totalBought)", color: .accent)
                StatTile(icon: "banknote.fill", title: "Продано", value: "\(store.state.soldCount)", color: .good)
                StatTile(icon: "scooter", title: "В гараже", value: "\(store.state.scooters.count)", color: .textPrimary)
                StatTile(icon: "wrench.fill", title: "Ремонтов", value: "\(store.state.repairs)", color: .warn)
                StatTile(icon: "number", title: "Номеров выбито", value: "\(store.state.rolls)", color: .textPrimary)
                StatTile(
                    icon: "star.fill",
                    title: "Лучший номер",
                    value: store.state.bestNumber?.code ?? "—",
                    color: store.state.bestNumber?.rarity.color ?? .muted
                )
            }
        }
        .cardStyle()
    }

    // MARK: Путь игрока

    private var journeyCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle(text: "История")

            journeyRow(icon: "calendar", title: "В игре с",
                       value: Self.dateFormatter.string(from: store.state.startedAt))
            journeyRow(icon: "clock", title: "Дней в игре", value: "\(store.daysInGame + 1)")
            journeyRow(icon: "flame.fill", title: "Сделок закрыто", value: "\(store.state.soldCount)")
            journeyRow(icon: "sparkles", title: "Выбито номеров", value: "\(store.state.rolls)")
        }
        .cardStyle()
    }

    private func journeyRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.accent)
                .frame(width: 18)
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.muted)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textPrimary)
        }
    }

    // MARK: Сброс

    private var resetButton: some View {
        Button {
            confirmReset = true
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("Сбросить прогресс")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.bad)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.bad.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(Color.bad.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle())
    }
}
