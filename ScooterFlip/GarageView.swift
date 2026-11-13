import SwiftUI

struct SelectedScooter: Identifiable {
    let id: UUID
}

struct GarageView: View {
    @EnvironmentObject private var store: GameStore
    @State private var selected: SelectedScooter?

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScreenHeader(title: "Гараж", subtitle: "Ремонт, тюнинг и продажа")

                ScrollView {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            StatChip(title: "Самокатов", value: "\(store.state.scooters.count)")
                            StatChip(title: "Вложено", value: rub(store.invested))
                            StatChip(title: "Оценка", value: rub(store.fleetValue))
                        }

                        if store.state.scooters.isEmpty {
                            EmptyStateView(
                                icon: "wrench.and.screwdriver",
                                title: "Гараж пуст",
                                text: "Купи первый самокат на Авито, чтобы начать."
                            )
                        } else {
                            ForEach(store.state.scooters) { scooter in
                                Button {
                                    selected = SelectedScooter(id: scooter.id)
                                } label: {
                                    GarageCard(scooter: scooter)
                                }
                                .buttonStyle(PressableStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 26)
                }
            }
        }
        .sheet(item: $selected) { item in
            ScooterDetailView(scooterID: item.id)
                .environmentObject(store)
        }
    }
}

struct GarageCard: View {
    @EnvironmentObject private var store: GameStore

    let scooter: OwnedScooter

    private var estimate: Int { store.sellEstimate(for: scooter) }
    private var part: PartKind { store.neededPart(for: scooter) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 11) {
                ScooterIconTile(model: scooter.model, size: 52)

                VStack(alignment: .leading, spacing: 5) {
                    Text(scooter.model.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 5) {
                        Tag(text: scooter.model.kind.title,
                            color: scooter.model.kind.color)
                        if let number = scooter.number {
                            NumberBadge(plate: number, compact: true)
                        }
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.muted)
                    .padding(.top, 4)
            }

            HStack(spacing: 6) {
                StatChip(title: "Состояние", value: "\(Int(scooter.condition))%")
                StatChip(title: "Батарея", value: "\(Int(scooter.battery))%")
                StatChip(title: "Пробег", value: "\(scooter.mileage) км")
            }

            HStack {
                if scooter.condition < 99 {
                    Label("Нужна деталь: \(part.title)",
                          systemImage: "wrench.and.screwdriver.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.warn)
                } else if scooter.firmware || scooter.bigBattery || scooter.custom {
                    Label("Есть тюнинг", systemImage: "sparkles")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.good)
                }
                Spacer()
                Text("≈ \(rub(estimate))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.accent)
            }
        }
        .cardStyle()
    }
}

struct ScooterDetailView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let scooterID: UUID

    @State private var confirmSell = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                if let scooter = store.scooter(scooterID) {
                    ScrollView {
                        VStack(spacing: 12) {
                            header(scooter)
                            priceCard(scooter)
                            repairCard(scooter)
                            tuningCard(scooter)
                            shareHint(scooter)
                            sellButton(scooter)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                } else {
                    EmptyStateView(icon: "checkmark.circle",
                                   title: "Самокат продан",
                                   text: "Этого самоката больше нет в гараже.")
                }
            }
            .navigationTitle("Карточка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") { dismiss() }
                        .foregroundColor(.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog("Продать самокат?", isPresented: $confirmSell, titleVisibility: .visible) {
            if let scooter = store.scooter(scooterID) {
                Button("Продать за ≈ \(rub(store.sellEstimate(for: scooter)))") {
                    store.sell(id: scooterID)
                    dismiss()
                }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Цена окончательная: покупатель может дать чуть больше или меньше.")
        }
    }

    // MARK: Секции

    private func header(_ scooter: OwnedScooter) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ScooterIconTile(model: scooter.model, size: 64)
                VStack(alignment: .leading, spacing: 5) {
                    Text(scooter.model.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 5) {
                        Tag(text: scooter.model.kind.title,
                            color: scooter.model.kind.color)
                        if let number = scooter.number {
                            NumberBadge(plate: number)
                        }
                    }
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 6) {
                StatChip(title: "Состояние", value: "\(Int(scooter.condition))%")
                StatChip(title: "Батарея", value: "\(Int(scooter.battery))%")
                StatChip(title: "Пробег", value: "\(scooter.mileage) км")
            }
        }
        .cardStyle()
    }

    private func priceCard(_ scooter: OwnedScooter) -> some View {
        let b = store.breakdown(for: scooter)

        return VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Из чего складывается цена")

            row("База", rub(b.base), .textPrimary)
            if b.condition != 0 {
                row("Износ", signedRub(b.condition), .bad)
            }
            if b.battery != 0 {
                row("Батарея", signedRub(b.battery), .warn)
            }
            if b.mileage != 0 {
                row("Пробег", signedRub(b.mileage), .warn)
            }
            if b.tuning > 0 {
                row("Тюнинг", signedRub(b.tuning), .good)
            }
            if b.number > 0 {
                row("Номер", signedRub(b.number), scooter.number?.rarity.color ?? .good)
            }

            Rectangle()
                .fill(Color.line)
                .frame(height: 1)

            row("Оценка", rub(b.total), .accent, bold: true)
        }
        .cardStyle()
    }

    private func repairCard(_ scooter: OwnedScooter) -> some View {
        let part = store.neededPart(for: scooter)
        let stock = store.stock(of: part)
        let cost = store.repairCost(for: scooter)
        let needsRepair = scooter.condition < 99.9

        return VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundColor(.warn)
                Text("Ремонт")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.textPrimary)
                Spacer()
                if !needsRepair {
                    Tag(text: "В порядке", color: .good)
                }
            }

            if needsRepair {
                Text("Нужна деталь: \(part.title) · на складе \(stock) шт.")
                    .font(.system(size: 12))
                    .foregroundColor(stock > 0 ? .muted : .bad)

                PrimaryActionButton(
                    title: "Починить за \(rub(cost))",
                    icon: "wrench.fill",
                    color: stock > 0 ? .accent : .panel2,
                    enabled: stock > 0 && store.state.money >= cost
                ) {
                    store.repair(id: scooter.id)
                }
            } else {
                Text("Состояние 100%. Можно ставить тюнинг и продавать.")
                    .font(.system(size: 12))
                    .foregroundColor(.muted)
            }
        }
        .cardStyle()
    }

    private func tuningCard(_ scooter: OwnedScooter) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Тюнинг и прошивка")

            ForEach(TuneKind.allCases) { kind in
                let done = store.isTuned(kind, scooter)
                let cost = store.tuneCost(kind, for: scooter)
                let affordable = store.state.money >= cost

                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.panel2)
                        Image(systemName: kind.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(done ? .good : .accent)
                    }
                    .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(kind.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Text(kind.effect)
                            .font(.system(size: 10))
                            .foregroundColor(.muted)
                    }

                    Spacer(minLength: 6)

                    Button {
                        store.applyTune(kind, id: scooter.id)
                    } label: {
                        Text(done ? "Готово" : rub(cost))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(done ? .good : (affordable ? .appBg : .muted))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(done ? Color.good.opacity(0.15) : (affordable ? Color.accent : Color.panel2))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(done || !affordable)
                }
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func shareHint(_ scooter: OwnedScooter) -> some View {
        if scooter.model.kind == .sharing && scooter.number == nil {
            InfoCard(
                text: "Номер не выбит. Зайди в раздел «Номера» — редкий номер добавит к цене до 300 000 ₽."
            )
        }
    }

    private func sellButton(_ scooter: OwnedScooter) -> some View {
        let estimate = store.sellEstimate(for: scooter)

        return PrimaryActionButton(
            title: "Продать за ≈ \(rub(estimate))",
            icon: "banknote.fill",
            color: .good
        ) {
            confirmSell = true
        }
    }

    private func row(_ title: String, _ value: String, _ color: Color, bold: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: bold ? .bold : .regular))
                .foregroundColor(bold ? .textPrimary : .muted)
            Spacer()
            Text(value)
                .font(.system(size: bold ? 16 : 12,
                              weight: bold ? .heavy : .semibold,
                              design: .rounded))
                .foregroundColor(color)
        }
    }
}
