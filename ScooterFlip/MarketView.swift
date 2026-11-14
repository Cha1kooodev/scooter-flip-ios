import SwiftUI

struct MarketView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScreenHeader(title: "Авито", subtitle: "Барахолка самокатов")

                ScrollView {
                    VStack(spacing: 12) {
                        InfoCard(
                            text: "Покупай дешевле, чини, ставь железо и продавай дороже. " +
                                  "Шеринговым моделям выбивай номера — редкость добавляет к цене."
                        )

                        HStack {
                            SectionTitle(text: "Свежие объявления")
                            Spacer()
                            Button {
                                store.regenerateMarket()
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("500 ₽")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.accent.opacity(0.12))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(PressableStyle())
                        }

                        if store.state.listings.isEmpty {
                            EmptyStateView(
                                icon: "bag",
                                title: "Лента пустая",
                                text: "Обнови объявления, чтобы найти новые самокаты."
                            )
                        } else {
                            ForEach(store.state.listings) { listing in
                                ListingCard(listing: listing)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 26)
                }
            }
        }
    }
}

struct ListingCard: View {
    @EnvironmentObject private var store: GameStore

    let listing: Listing

    private var estimate: Int { store.listEstimate(for: listing) }
    private var isDeal: Bool { listing.price < Int(Double(estimate) * 0.85) }
    private var canAfford: Bool { store.state.money >= listing.price }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ArtBanner(model: listing.model, plate: listing.number?.code, height: 98)

            VStack(alignment: .leading, spacing: 5) {
                Text(listing.model.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 5) {
                    Tag(text: listing.model.kind.title, color: listing.model.kind.color)
                    if let number = listing.number {
                        NumberBadge(plate: number, compact: true)
                    }
                    Spacer(minLength: 0)
                    if isDeal {
                        Text("🔥 выгодно")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.good)
                    }
                }
            }

            HStack(alignment: .firstTextBaseline) {
                Text("Цена")
                    .font(.system(size: 11))
                    .foregroundColor(.muted)
                Spacer()
                Text(rub(listing.price))
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundColor(.accent)
            }

            HStack(spacing: 6) {
                StatChip(title: "Состояние", value: "\(Int(listing.condition))%")
                StatChip(title: "Батарея", value: "\(Int(listing.battery))%")
                StatChip(title: "Пробег", value: "\(listing.mileage) км")
            }

            if let part = listing.neededPart {
                HStack(spacing: 6) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 10))
                    Text("Нужна деталь: \(part.title)")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.warn)
            }

            if let fault = listing.flashFault {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.horizontal.fill")
                        .font(.system(size: 10))
                    Text(fault.title + " · ST-LINK V2")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.bad)
            }

            if listing.isClean {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                    Text("Без поломок")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.good)
            }

            Rectangle()
                .fill(Color.line)
                .frame(height: 1)

            HStack {
                Text("Продавец: \(listing.seller)")
                    .font(.system(size: 11))
                    .foregroundColor(.muted)
                Spacer()
                Text("оценка \(rub(estimate))")
                    .font(.system(size: 10))
                    .foregroundColor(.muted)
            }

            PrimaryActionButton(
                title: canAfford
                    ? "Купить за \(rub(listing.price))"
                    : "Не хватает \(rub(listing.price - store.state.money))",
                icon: "cart.fill",
                enabled: canAfford
            ) {
                store.buy(listing)
            }
        }
        .cardStyle()
    }
}
