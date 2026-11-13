import SwiftUI

struct PartsView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScreenHeader(title: "Запчасти", subtitle: "Склад для ремонта")

                ScrollView {
                    VStack(spacing: 12) {
                        InfoCard(
                            text: "Для ремонта нужна конкретная деталь — при починке она списывается со склада. " +
                                  "Детали дешевле покупать заранее."
                        )

                        ForEach(PartKind.allCases) { part in
                            PartRow(part: part)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 26)
                }
            }
        }
    }
}

struct PartRow: View {
    @EnvironmentObject private var store: GameStore

    let part: PartKind

    private var count: Int { store.stock(of: part) }
    private var canAfford: Bool { store.state.money >= part.price }

    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.panel2)
                Image(systemName: part.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.accent)
            }
            .frame(width: 44, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
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
