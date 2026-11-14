import SwiftUI

// MARK: - Точки на фото

/// Где на фото самоката дека и дисплей. Координаты 0...1 от картинки.
struct ScooterHotspotMap {
    let imageName: String
    let aspect: CGFloat
    let deck: CGRect
    let display: CGRect
    let tracker: CGRect

    static func forModel(_ modelID: String) -> ScooterHotspotMap {
        switch modelID {
        case "ninebot-s90l":
            return ScooterHotspotMap(
                imageName: "photo-ninebot-s90l",
                aspect: 715.0 / 1000.0,
                deck: CGRect(x: 0.28, y: 0.67, width: 0.46, height: 0.14),
                display: CGRect(x: 0.36, y: 0.16, width: 0.22, height: 0.10),
                tracker: CGRect(x: 0.30, y: 0.36, width: 0.16, height: 0.16)
            )
        default:
            // SNSC 2.0–2.4 — общее фото.
            return ScooterHotspotMap(
                imageName: "photo-snsc",
                aspect: 1.0,
                deck: CGRect(x: 0.33, y: 0.60, width: 0.47, height: 0.22),
                display: CGRect(x: 0.28, y: 0.01, width: 0.26, height: 0.10),
                tracker: CGRect(x: 0.30, y: 0.32, width: 0.16, height: 0.17)
            )
        }
    }
}

// MARK: - Этапы разборки

enum StripStep {
    case tracker
    case trackerBolts
    case deck
    case screwdriver
    case screws
    case controller
    case display
    case result
}

// MARK: - Игра разборки

struct StripGameView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let unit: StreetUnit

    @State private var step: StripStep = .tracker
    @State private var hint: String?
    @State private var showDeckHint = false
    @State private var showTrackerHint = false
    @State private var trackerBolts: Set<Int> = []
    @State private var removedScrews: Set<Int> = []
    @State private var target: Double = 0.5
    @State private var result: StripResult?
    @State private var done = false

    private var screwsLeft: Int { 4 - removedScrews.count }
    private var trackerBoltsLeft: Int { 2 - trackerBolts.count }

    private var hotspots: ScooterHotspotMap { .forModel(unit.modelID) }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    header

                    if done, let result {
                        resultView(result)
                    } else {
                        switch step {
                        case .tracker:      trackerStep
                        case .trackerBolts: trackerBoltsStep
                        case .deck:         deckStep
                        case .screwdriver:  screwdriverStep
                        case .screws:       screwsStep
                        case .controller:   controllerStep
                        case .display:      displayStep
                        case .result:       EmptyView()
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Шапка

    private var header: some View {
        HStack(spacing: 12) {
            ScooterVisual(model: unit.model, plate: unit.plate?.code)
                .frame(width: 58, height: 58)
                .background(Color.panel2)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(unit.model.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                Label(unit.address, systemImage: "mappin.and.ellipse")
                    .font(.system(size: 10))
                    .foregroundColor(.muted)
                Text(stepTitle)
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

    private var stepTitle: String {
        switch step {
        case .tracker, .trackerBolts:
            return "Шаг 1 из 5 · сними IoT-трекер"
        case .deck:        return "Шаг 2 из 5 · найди деку"
        case .screwdriver: return "Шаг 3 из 5 · вскрой деку"
        case .screws:      return "Шаг 4 из 5 · сними контроллер"
        case .controller:  return "Шаг 4 из 5 · контроллер снят"
        case .display:     return "Шаг 5 из 5 · сними дисплей"
        case .result:      return "Готово"
        }
    }

    // MARK: Шаг 1 — IoT-трекер

    private var trackerStep: some View {
        VStack(spacing: 12) {
            InfoCard(text: "Первым делом сними IoT-трекер. Он стоит посередине высокой рулевой колонки и держится на двух T20 торкс-болтах.")

            PhotoTapView(
                map: hotspots,
                highlight: showTrackerHint ? hotspots.tracker : nil,
                onTap: { point in
                    if hotspots.tracker.contains(point) {
                        hint = nil
                        step = .trackerBolts
                    } else {
                        showTrackerHint = true
                        hint = "Не то. Трекер — посередине рулевой колонки, на самой стойке."
                    }
                }
            )

            if let hint {
                Text(hint)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.bad)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var trackerBoltsStep: some View {
        VStack(spacing: 12) {
            if !store.owns(.torx) {
                torxShopCard
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("IoT-трекер")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.textPrimary)

                    Text("Открути два болта T20: осталось \(trackerBoltsLeft).")
                        .font(.system(size: 11))
                        .foregroundColor(.muted)

                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(hex: 0x161B24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.line, lineWidth: 1)
                            )

                        VStack(spacing: 6) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundColor(trackerBoltsLeft == 0 ? .good : .accent)
                            Text("GPS / IoT")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.muted)
                        }
                        .opacity(trackerBoltsLeft == 0 ? 1 : 0.5)

                        ForEach(0..<2, id: \.self) { index in
                            trackerBoltButton(index)
                                .offset(x: index == 0 ? -74 : 74)
                        }
                    }
                    .frame(height: 150)
                }
                .cardStyle()

                PrimaryActionButton(
                    title: trackerBoltsLeft == 0 ? "Снять трекер" : "Осталось болтов: \(trackerBoltsLeft)",
                    icon: "antenna.radiowaves.left.and.right",
                    enabled: trackerBoltsLeft == 0
                ) {
                    hint = nil
                    step = .deck
                }
            }
        }
    }

    private func trackerBoltButton(_ index: Int) -> some View {
        let removed = trackerBolts.contains(index)

        return Button {
            trackerBolts.insert(index)
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: 0x2A303B))
                    .frame(width: 38, height: 38)
                Circle()
                    .stroke(Color(hex: 0x4A5261), lineWidth: 1.5)
                    .frame(width: 38, height: 38)
                if removed {
                    Circle()
                        .fill(Color(hex: 0x0B0E13))
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: "asterisk")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.accent)
                }
            }
        }
        .buttonStyle(PressableStyle())
        .disabled(removed)
    }

    // MARK: Шаг 2 — дека

    private var deckStep: some View {
        VStack(spacing: 12) {
            InfoCard(text: "Найди на фото площадку под ногами — деку. По ней и будем вскрывать.")

            PhotoTapView(
                map: hotspots,
                highlight: showDeckHint ? hotspots.deck : nil,
                onTap: { point in
                    if hotspots.deck.contains(point) {
                        hint = nil
                        step = .screwdriver
                    } else {
                        SoundPlayer.shared.play(.deckMiss)
                        showDeckHint = true
                        hint = "Мимо. Дека — это широкая площадка между колёсами, под ногами."
                    }
                }
            )

            if let hint {
                Text(hint)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.bad)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: Шаг 2 — отвёртка

    private var screwdriverStep: some View {
        VStack(spacing: 12) {
            InfoCard(text: "Дека найдена. Возьми отвёртку и попади битой точно в винт: двигай ползунок и жми, когда метка в зелёной зоне.")

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "screwdriver.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.accent)
                    Text("Винт деки")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text("Torx T20")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.muted)
                }

                TimingBar(target: $target) { hit in
                    if hit {
                        hint = nil
                        SoundPlayer.shared.play(.deckOpen)
                        step = .screws
                    } else {
                        SoundPlayer.shared.play(.deckMiss)
                        hint = "Бита соскочила. Попробуй ещё раз — лови метку в зелёной зоне."
                        target = Double.random(in: 0.18...0.82)
                    }
                }

                if let hint {
                    Text(hint)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.bad)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .cardStyle()
        }
        .onAppear {
            target = Double.random(in: 0.18...0.82)
        }
    }

    // MARK: Шаг 3 — торкс-винты и контроллер

    private var torxShopCard: some View {
        VStack(spacing: 10) {
            InfoCard(text: "Контроллер и трекер прикручены торкс-винтами T20. Без набора торкс-бит их не снять.")

            HStack(spacing: 12) {
                PartArt(key: "torx")
                    .frame(width: 52, height: 52)
                    .padding(6)
                    .background(Color.panel2)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(ToolKind.torx.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text(ToolKind.torx.note)
                        .font(.system(size: 10))
                        .foregroundColor(.muted)
                }

                Spacer(minLength: 4)

                Button {
                    store.buyTool(.torx)
                } label: {
                    Text(rub(ToolKind.torx.price))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(store.state.money >= ToolKind.torx.price ? .appBg : .muted)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(store.state.money >= ToolKind.torx.price ? Color.accent : Color.panel2)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableStyle())
                .disabled(store.state.money < ToolKind.torx.price)
            }
            .cardStyle()
        }
    }

    private var screwsStep: some View {
        VStack(spacing: 12) {
            if !store.owns(.torx) {
                torxShopCard
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Дека вскрыта")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.textPrimary)

                    Text("Выкрути 4 торкс-винта контроллера: \(screwsLeft) осталось.")
                        .font(.system(size: 11))
                        .foregroundColor(.muted)

                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(hex: 0x161B24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.line, lineWidth: 1)
                            )

                        PartArt(key: "controller")
                            .opacity(screwsLeft == 0 ? 1 : 0.35)
                            .padding(34)

                        ForEach(0..<4, id: \.self) { index in
                            screwButton(index)
                                .offset(x: index % 2 == 0 ? -92 : 92,
                                        y: index < 2 ? -46 : 46)
                        }
                    }
                    .frame(height: 170)
                }
                .cardStyle()

                PrimaryActionButton(
                    title: screwsLeft == 0 ? "Вынуть контроллер" : "Осталось винтов: \(screwsLeft)",
                    icon: "cpu",
                    enabled: screwsLeft == 0
                ) {
                    step = .controller
                }
            }
        }
    }

    private func screwButton(_ index: Int) -> some View {
        let removed = removedScrews.contains(index)

        return Button {
            removedScrews.insert(index)
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: 0x2A303B))
                    .frame(width: 34, height: 34)
                Circle()
                    .stroke(Color(hex: 0x4A5261), lineWidth: 1.5)
                    .frame(width: 34, height: 34)
                if removed {
                    Circle()
                        .fill(Color(hex: 0x0B0E13))
                        .frame(width: 12, height: 12)
                } else {
                    Image(systemName: "asterisk")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.accent)
                }
            }
        }
        .buttonStyle(PressableStyle())
        .disabled(removed)
    }

    // MARK: Контроллер снят

    private var controllerStep: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.good)

            Text("Контроллер снят")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.textPrimary)

            Text("Теперь сними дисплей — он сверху, между ручками тормоза.")
                .font(.system(size: 12))
                .foregroundColor(.muted)
                .multilineTextAlignment(.center)

            PrimaryActionButton(title: "К дисплею", icon: "display") {
                step = .display
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: Шаг 4 — дисплей

    private var displayStep: some View {
        VStack(spacing: 12) {
            InfoCard(text: "Найди дисплей на фото: он сверху, по центру между ручками тормоза.")

            PhotoTapView(
                map: hotspots,
                highlight: nil,
                onTap: { point in
                    if hotspots.display.contains(point) {
                        hint = nil
                        finishStrip()
                    } else {
                        hint = "Это не дисплей. Экран — сверху, между ручками тормоза, по центру руля."
                    }
                }
            )

            if let hint {
                Text(hint)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.bad)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: Результат

    private func finishStrip() {
        guard !done else { return }
        let outcome = store.strip(unit)
        if case .caught = outcome {
            SoundPlayer.shared.play(.caught)
        }
        result = outcome
        done = true
        step = .result
    }

    @ViewBuilder
    private func resultView(_ result: StripResult) -> some View {
        switch result {
        case .caught:
            VStack(spacing: 12) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 52))
                    .foregroundColor(.bad)
                Text("Поймала СБ")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.textPrimary)
                Text("Служба безопасности изъяла все самокаты из гаража. Деньги и запчасти остались.")
                    .font(.system(size: 12))
                    .foregroundColor(.muted)
                    .multilineTextAlignment(.center)
                PrimaryActionButton(title: "Понял", icon: "checkmark", color: .bad) {
                    dismiss()
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .cardStyle()

        case .success(let parts):
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.good)
                    Text("Скрутили")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.textPrimary)
                }

                ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                    HStack(spacing: 10) {
                        PartArt(key: part.artKey)
                            .frame(width: 38, height: 38)
                            .padding(4)
                            .background(Color.panel2)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(part.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            Text(part.needsFirmware ? "На склад · нужна прошивка" : "Сразу на склад")
                                .font(.system(size: 10))
                                .foregroundColor(part.needsFirmware ? .warn : .good)
                        }

                        Spacer()

                        Text("+1")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(.good)
                    }
                    .padding(9)
                    .background(Color.panel2)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if parts.contains(where: { $0.needsFirmware }) {
                    Text("Электронику нужно прошить ST-LINK V2: «Магазин» → «Инструмент». Шанс успеха 70%, иначе блок уйдёт в мусор.")
                        .font(.system(size: 10))
                        .foregroundColor(.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PrimaryActionButton(title: "Готово", icon: "checkmark") {
                    dismiss()
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .cardStyle()
        }
    }
}

// MARK: - Фото с тапом по области

struct PhotoTapView: View {
    let map: ScooterHotspotMap
    var highlight: CGRect? = nil
    let onTap: (CGPoint) -> Void

    var body: some View {
        GeometryReader { geo in
            let rect = fittedRect(aspect: map.aspect, in: geo.size)

            ZStack(alignment: .topLeading) {
                Image(map.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)

                if let highlight {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.accent, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .frame(width: rect.width * highlight.width,
                               height: rect.height * highlight.height)
                        .offset(x: rect.minX + rect.width * highlight.minX,
                                y: rect.minY + rect.height * highlight.minY)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.appBg)
                            .padding(7)
                            .background(Color.accent)
                            .clipShape(Circle())
                            .padding(8)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onEnded { value in
                    let point = value.location
                    guard rect.contains(point) else {
                        onTap(CGPoint(x: -1, y: -1))
                        return
                    }
                    onTap(CGPoint(
                        x: (point.x - rect.minX) / rect.width,
                        y: (point.y - rect.minY) / rect.height
                    ))
                }
            )
        }
        .frame(height: 330)
        .background(Color(hex: 0xF6F8FC))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.line, lineWidth: 1)
        )
    }

    private func fittedRect(aspect: CGFloat, in size: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0, aspect > 0 else { return .zero }
        let container = size.width / size.height
        if container > aspect {
            let width = size.height * aspect
            return CGRect(x: (size.width - width) / 2, y: 0, width: width, height: size.height)
        } else {
            let height = size.width / aspect
            return CGRect(x: 0, y: (size.height - height) / 2, width: size.width, height: height)
        }
    }
}

// MARK: - Ползунок попадания

struct TimingBar: View {
    @Binding var target: Double
    let onResult: (Bool) -> Void

    private func position(at date: Date) -> Double {
        let t = date.timeIntervalSinceReferenceDate
        return (sin(t * 2.4) + 1) / 2
    }

    var body: some View {
        VStack(spacing: 10) {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.line)
                            .frame(height: 16)

                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.good.opacity(0.35))
                            .frame(width: geo.size.width * 0.18, height: 22)
                            .offset(x: geo.size.width * (target - 0.09))

                        Circle()
                            .fill(Color.accent)
                            .frame(width: 22, height: 22)
                            .offset(x: geo.size.width * position(at: context.date) - 11)
                    }
                    .frame(height: 22)
                }
                .frame(height: 22)
            }
            .frame(height: 22)

            PrimaryActionButton(title: "Вставить биту", icon: "screwdriver.fill") {
                let hit = abs(position(at: Date()) - target) < 0.09
                onResult(hit)
            }
        }
    }
}
