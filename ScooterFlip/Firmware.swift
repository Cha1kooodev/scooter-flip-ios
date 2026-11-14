import SwiftUI

// MARK: - Пины

enum FlashPin: String, CaseIterable, Identifiable {
    case swdio
    case swclk
    case gnd

    var id: String { rawValue }

    var label: String {
        switch self {
        case .swdio: return "SWDIO"
        case .swclk: return "SWCLK"
        case .gnd:   return "GND"
        }
    }

    var wire: String {
        switch self {
        case .swdio: return "жёлтый"
        case .swclk: return "синий"
        case .gnd:   return "чёрный"
        }
    }

    var color: Color {
        switch self {
        case .swdio: return Color(hex: 0xFFD400)
        case .swclk: return Color(hex: 0x38BDF8)
        case .gnd:   return Color(hex: 0x8B97AB)
        }
    }
}

// MARK: - Мини-игра прошивки

struct FlashGameView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let job: FlashJobKind

    @State private var round = 0
    @State private var pins: [FlashPin] = FlashPin.allCases.shuffled()
    @State private var connected: Set<FlashPin> = []
    @State private var selected: FlashPin?
    @State private var errorText: String?
    @State private var flashing = false
    @State private var done = false
    @State private var failed = false

    private var blocks: [PartKind] { job.blocks }
    private var currentBlock: PartKind? {
        blocks.indices.contains(round) ? blocks[round] : blocks.last
    }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            if !store.owns(.stlink) {
                missingTool
            } else if done {
                successView
            } else if failed {
                failedView
            } else {
                content
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Контент

    private var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                headerCard

                boardCard

                if let errorText {
                    Text(errorText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.bad)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                wiresRow

                PrimaryActionButton(
                    title: connected.count == 3 ? "Прошить" : "Подключи все три пина",
                    icon: "bolt.horizontal.fill",
                    color: .good,
                    enabled: connected.count == 3 && !flashing
                ) {
                    startFlash()
                }

                Text("Порядок пинов на плате меняется — смотри подписи. " +
                     "ST-LINK V2 подключается к SWDIO, SWCLK и GND. " +
                     "Прошивка проходит в 70% случаев: остальные 30% — блок не отвечает.")
                    .font(.system(size: 10))
                    .foregroundColor(.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .overlay {
            if flashing {
                ZStack {
                    Color.black.opacity(0.55).ignoresSafeArea()
                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(Color.accent)
                        Text("Шьём \(currentBlock?.title.lowercased() ?? "блок")…")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                    .padding(20)
                    .background(Color.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 12) {
            PartArt(key: "stlink")
                .frame(width: 52, height: 52)
                .padding(6)
                .background(Color.panel2)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(job.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(job.subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.muted)
                Text("Блок \(round + 1) из \(blocks.count): \(currentBlock?.title ?? "—")")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.accent)
            }

            Spacer(minLength: 0)

            Button("Закрыть") { dismiss() }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.muted)
        }
        .cardStyle()
    }

    // MARK: Плата

    private var boardCard: some View {
        VStack(spacing: 12) {
            Text("Плата \(currentBlock?.title.lowercased() ?? "")")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.muted)

            HStack(spacing: 10) {
                ForEach(pins) { pin in
                    padView(pin)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: 0x123326))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(hex: 0x1F5C42), lineWidth: 1)
            )

            HStack(spacing: 6) {
                Image(systemName: connected.count == 3 ? "checkmark.circle.fill" : "cable.connector")
                    .font(.system(size: 10))
                Text("Подключено \(connected.count) из 3")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(connected.count == 3 ? .good : .muted)
        }
        .cardStyle()
    }

    private func padView(_ pin: FlashPin) -> some View {
        let isOn = connected.contains(pin)
        return Button {
            tapPad(pin)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isOn ? pin.color : Color(hex: 0x0B0E13))
                        .frame(width: 36, height: 36)
                    Circle()
                        .stroke(isOn ? pin.color : Color(hex: 0x2E3A4C), lineWidth: 2)
                        .frame(width: 36, height: 36)
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(.appBg)
                    }
                }
                Text(pin.label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(isOn ? .textPrimary : .muted)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableStyle())
        .disabled(isOn || flashing)
    }

    // MARK: Провода

    private var wiresRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Провода ST-LINK")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.muted)

            HStack(spacing: 8) {
                ForEach(FlashPin.allCases) { pin in
                    wireChip(pin)
                }
            }
        }
        .cardStyle()
    }

    private func wireChip(_ pin: FlashPin) -> some View {
        let isUsed = connected.contains(pin)
        let isSelected = selected == pin

        return Button {
            guard !isUsed else { return }
            selected = isSelected ? nil : pin
            errorText = nil
        } label: {
            VStack(spacing: 5) {
                Capsule()
                    .fill(pin.color)
                    .frame(height: 5)
                Text(pin.wire)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(isUsed ? .muted : .textPrimary)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? pin.color.opacity(0.16) : Color.panel2)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(isSelected ? pin.color : Color.line, lineWidth: isSelected ? 1.6 : 1)
            )
            .opacity(isUsed ? 0.45 : 1)
        }
        .buttonStyle(PressableStyle())
        .disabled(isUsed)
    }

    // MARK: Логика

    private func tapPad(_ pin: FlashPin) {
        guard !flashing else { return }
        guard let wire = selected else {
            errorText = "Сначала выбери провод ST-LINK внизу."
            return
        }
        if wire == pin {
            connected.insert(pin)
            selected = nil
            errorText = nil
        } else {
            errorText = "Не тот пин: \(wire.wire) провод — это \(wire.label), а не \(pin.label)."
            selected = nil
        }
    }

    private func startFlash() {
        flashing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            flashing = false
            if round + 1 < blocks.count {
                round += 1
                pins = FlashPin.allCases.shuffled()
                connected = []
                selected = nil
                errorText = nil
            } else {
                let outcome = store.finishFlash(job)
                switch outcome {
                case .success: done = true
                case .failed:
                    SoundPlayer.shared.play(.flashFail)
                    failed = true
                }
            }
        }
    }

    // MARK: Готово

    private var successView: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundColor(.good)

            Text("Прошивка завершена")
                .font(.system(size: 21, weight: .heavy))
                .foregroundColor(.textPrimary)

            Text(doneText)
                .font(.system(size: 12))
                .foregroundColor(.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            PrimaryActionButton(title: "Готово", icon: "checkmark") {
                dismiss()
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 24)
    }

    private var doneText: String {
        switch job {
        case .part(let part):
            return "\(part.title) прошит и лежит на складе — можно ставить на самокат."
        case .scooter(_, let fault):
            return fault == .all
                ? "Контроллер, батарея и дисплей прошиты. Ошибка снята."
                : "\(fault.blocks.first?.title ?? "Блок") прошит. Ошибка снята."
        }
    }

    // MARK: Неудача

    private var failedView: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 64))
                .foregroundColor(.bad)

            Text("Прошивка не удалась")
                .font(.system(size: 21, weight: .heavy))
                .foregroundColor(.textPrimary)

            Text(failedText)
                .font(.system(size: 12))
                .foregroundColor(.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text("Шанс успеха — 70%")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.warn)

            Spacer()

            PrimaryActionButton(title: "Готово", icon: "checkmark", color: .bad) {
                dismiss()
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 24)
    }

    private var failedText: String {
        switch job {
        case .part(let part):
            return "\(part.title) заблокировался и ушёл в мусор. Скрути ещё один с шеринга."
        case .scooter:
            return "Блок не отвечает, ошибка осталась. Можно попробовать прошить снова."
        }
    }

    // MARK: Нет программатора

    private var missingTool: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "cable.connector.slash")
                .font(.system(size: 54))
                .foregroundColor(.warn)
            Text("Нужен ST-LINK V2")
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.textPrimary)
            Text("Без программатора прошить контроллер, батарею или дисплей не получится.")
                .font(.system(size: 12))
                .foregroundColor(.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 26)
            PrimaryActionButton(
                title: store.state.money >= ToolKind.stlink.price
                    ? "Купить за \(rub(ToolKind.stlink.price))"
                    : "Не хватает \(rub(ToolKind.stlink.price - store.state.money))",
                icon: "cart.fill",
                enabled: store.state.money >= ToolKind.stlink.price
            ) {
                store.buyTool(.stlink)
            }
            .padding(.horizontal, 16)
            Button("Закрыть") { dismiss() }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.muted)
            Spacer()
        }
        .padding(.bottom, 24)
    }
}
