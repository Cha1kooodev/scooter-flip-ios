import Foundation
import SwiftUI

// MARK: - Состояние игры

struct GameState: Codable {
    var money: Int
    var scooters: [OwnedScooter]
    var listings: [Listing]
    var parts: [String: Int]
    var profit: Int
    var soldCount: Int
    var repairs: Int
    var rolls: Int
    var bestNumber: NumberPlate?

    // Профиль игрока
    var playerName: String
    var startedAt: Date
    var totalBought: Int
    var totalSpent: Int
    var totalEarned: Int

    // Разборка шеринга
    var strips: Int
    var caught: Int

    // Прошивка
    var unflashed: [String: Int]
    var tools: [String: Bool]
    var flashedParts: Int
    var flashedScooters: Int
    var flashFails: Int

    enum CodingKeys: String, CodingKey {
        case money, scooters, listings, parts, profit, soldCount, repairs, rolls
        case bestNumber, playerName, startedAt, totalBought, totalSpent, totalEarned
        case strips, caught
        case unflashed, tools, flashedParts, flashedScooters, flashFails
    }

    init(money: Int,
         scooters: [OwnedScooter],
         listings: [Listing],
         parts: [String: Int],
         profit: Int,
         soldCount: Int,
         repairs: Int,
         rolls: Int,
         bestNumber: NumberPlate?,
         playerName: String,
         startedAt: Date,
         totalBought: Int,
         totalSpent: Int,
         totalEarned: Int,
         strips: Int = 0,
         caught: Int = 0,
         unflashed: [String: Int] = [:],
         tools: [String: Bool] = [:],
         flashedParts: Int = 0,
         flashedScooters: Int = 0,
         flashFails: Int = 0) {
        self.money = money
        self.scooters = scooters
        self.listings = listings
        self.parts = parts
        self.profit = profit
        self.soldCount = soldCount
        self.repairs = repairs
        self.rolls = rolls
        self.bestNumber = bestNumber
        self.playerName = playerName
        self.startedAt = startedAt
        self.totalBought = totalBought
        self.totalSpent = totalSpent
        self.totalEarned = totalEarned
        self.strips = strips
        self.caught = caught
        self.unflashed = unflashed
        self.tools = tools
        self.flashedParts = flashedParts
        self.flashedScooters = flashedScooters
        self.flashFails = flashFails
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        money = try container.decode(Int.self, forKey: .money)
        scooters = try container.decode([OwnedScooter].self, forKey: .scooters)
        listings = try container.decode([Listing].self, forKey: .listings)
        parts = try container.decode([String: Int].self, forKey: .parts)
        profit = try container.decode(Int.self, forKey: .profit)
        soldCount = try container.decode(Int.self, forKey: .soldCount)
        repairs = try container.decode(Int.self, forKey: .repairs)
        rolls = try container.decode(Int.self, forKey: .rolls)
        bestNumber = try container.decodeIfPresent(NumberPlate.self, forKey: .bestNumber)
        playerName = try container.decodeIfPresent(String.self, forKey: .playerName) ?? "Райдер"
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt) ?? Date()
        totalBought = try container.decodeIfPresent(Int.self, forKey: .totalBought) ?? 0
        totalSpent = try container.decodeIfPresent(Int.self, forKey: .totalSpent) ?? 0
        totalEarned = try container.decodeIfPresent(Int.self, forKey: .totalEarned) ?? 0
        strips = try container.decodeIfPresent(Int.self, forKey: .strips) ?? 0
        caught = try container.decodeIfPresent(Int.self, forKey: .caught) ?? 0
        unflashed = try container.decodeIfPresent([String: Int].self, forKey: .unflashed) ?? [:]
        tools = try container.decodeIfPresent([String: Bool].self, forKey: .tools) ?? [:]
        flashedParts = try container.decodeIfPresent(Int.self, forKey: .flashedParts) ?? 0
        flashedScooters = try container.decodeIfPresent(Int.self, forKey: .flashedScooters) ?? 0
        flashFails = try container.decodeIfPresent(Int.self, forKey: .flashFails) ?? 0
    }

    static func fresh() -> GameState {
        let starter = OwnedScooter(
            modelID: "kugoo-s3",
            condition: 45,
            battery: 72,
            mileage: 4_200,
            number: nil,
            boughtPrice: 12_000,
            neededPart: .pads
        )
        return GameState(
            money: 60_000,
            scooters: [starter],
            listings: [],
            parts: [PartKind.pads.rawValue: 1],
            profit: 0,
            soldCount: 0,
            repairs: 0,
            rolls: 0,
            bestNumber: nil,
            playerName: "Райдер",
            startedAt: Date(),
            totalBought: 1,
            totalSpent: 12_000,
            totalEarned: 0
        )
    }
}

/// Программный тюнинг.
enum TuneKind: String, CaseIterable, Identifiable {
    case firmware
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firmware: return "Прошивка"
        case .custom:   return "Стайлинг"
        }
    }

    var icon: String {
        switch self {
        case .firmware: return "bolt.horizontal.fill"
        case .custom:   return "paintbrush.fill"
        }
    }

    var effect: String {
        switch self {
        case .firmware: return "+12% к цене, но сажает батарею"
        case .custom:   return "+6% к цене и внешний вид"
        }
    }
}

struct RollOutcome: Identifiable {
    let id = UUID()
    let scooterID: UUID
    let plate: NumberPlate
    let cost: Int
}

/// Уровень игрока зависит от чистой прибыли.
struct LevelTier {
    let title: String
    let need: Int

    static let all: [LevelTier] = [
        LevelTier(title: "Новичок", need: 0),
        LevelTier(title: "Курьер", need: 25_000),
        LevelTier(title: "Механик", need: 75_000),
        LevelTier(title: "Перекуп", need: 200_000),
        LevelTier(title: "Барыга", need: 500_000),
        LevelTier(title: "Магнат", need: 1_200_000),
        LevelTier(title: "Легенда рынка", need: 3_000_000),
    ]
}

// MARK: - Игровой склад

@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var state: GameState
    @Published var toast: String?
    @Published private(set) var streetUnits: [StreetUnit] = []

    private let saveKey = "scooter-flip-save-v2"
    private var toastWork: DispatchWorkItem?

    init() {
        if let saved = Self.loadState() {
            state = saved
        } else {
            state = GameState.fresh()
            regenerateMarket(free: true)
        }
        refreshStreet()
    }

    // MARK: Доступ

    func scooter(_ id: UUID) -> OwnedScooter? {
        state.scooters.first { $0.id == id }
    }

    var sharingScooters: [OwnedScooter] {
        state.scooters.filter { $0.model.kind == .sharing }
    }

    var fleetValue: Int {
        state.scooters.reduce(0) { $0 + breakdown(for: $1).total }
    }

    var invested: Int {
        state.scooters.reduce(0) { $0 + $1.boughtPrice }
    }

    var netWorth: Int {
        state.money + fleetValue
    }

    func stock(of part: PartKind) -> Int {
        state.parts[part.rawValue] ?? 0
    }

    /// Непрошитые детали, снятые с шеринга.
    func unflashedStock(of part: PartKind) -> Int {
        state.unflashed[part.rawValue] ?? 0
    }

    var totalParts: Int {
        state.parts.values.reduce(0, +) + state.unflashed.values.reduce(0, +)
    }

    func owns(_ tool: ToolKind) -> Bool {
        state.tools[tool.rawValue] ?? false
    }

    var unflashedCount: Int {
        state.unflashed.values.reduce(0, +)
    }

    // MARK: Цена

    func breakdown(for scooter: OwnedScooter) -> ValueBreakdown {
        let model = scooter.model
        let base = model.basePrice

        let condF = 0.55 + 0.45 * (scooter.condition / 100)
        let battF = 0.80 + 0.20 * (scooter.battery / 100)
        let mileF = max(0.70, 1 - Double(scooter.mileage) / 70_000)

        let afterCondition = Int(Double(base) * condF)
        let afterBattery = Int(Double(afterCondition) * battF)
        let afterMileage = Int(Double(afterBattery) * mileF)

        var tuningRate = 0.0
        if scooter.firmware { tuningRate += 0.12 }
        if scooter.custom { tuningRate += 0.06 }
        let tuningValue = Int(Double(afterMileage) * tuningRate)

        let upgradesRate = scooter.upgrades.reduce(0.0) { $0 + $1.valueBonus }
        let upgradesValue = Int(Double(afterMileage) * upgradesRate)

        let numberValue = scooter.number?.rarity.bonus ?? 0

        // Непрошитый контроллер/батарея/дисплей режут цену, пока не прошьёшь.
        let flashPenalty = scooter.flashFault == nil ? 0 : -Int(Double(afterMileage) * 0.20)

        return ValueBreakdown(
            base: base,
            condition: afterCondition - base,
            battery: afterBattery - afterCondition,
            mileage: afterMileage - afterBattery,
            tuning: tuningValue,
            upgrades: upgradesValue,
            number: numberValue,
            flash: flashPenalty,
            total: afterMileage + tuningValue + upgradesValue + numberValue + flashPenalty
        )
    }

    func sellEstimate(for scooter: OwnedScooter) -> Int {
        breakdown(for: scooter).total
    }

    func listEstimate(for listing: Listing) -> Int {
        let temp = OwnedScooter(
            modelID: listing.modelID,
            condition: listing.condition,
            battery: listing.battery,
            mileage: listing.mileage,
            number: listing.number,
            boughtPrice: 0,
            neededPart: listing.neededPart,
            flashFault: listing.flashFault
        )
        return breakdown(for: temp).total
    }

    // MARK: Авито

    func regenerateMarket(free: Bool = false) {
        let cost = 500
        if !free {
            guard state.money >= cost else {
                showToast("Нужно \(rub(cost)) на обновление ленты")
                return
            }
            state.money -= cost
            state.totalSpent += cost
        }

        var fresh: [Listing] = []
        for _ in 0..<7 {
            fresh.append(makeListing())
        }
        state.listings = fresh
        save()
    }

    private func makeListing() -> Listing {
        let model = ScooterCatalog.all.randomElement() ?? ScooterCatalog.model("kugoo-s3")

        // Примерно каждое третье объявление — без поломок.
        let clean = Int.random(in: 0..<100) < 42

        var condition: Double
        var battery: Double
        var mileage: Int
        var needed: PartKind?
        var flashFault: FlashFault?

        if clean {
            condition = 100
            battery = Double(Int.random(in: 74...100))
            mileage = Int.random(in: 150...5_000)
            needed = nil
        } else {
            condition = Double(Int.random(in: 22...88))
            battery = Double(Int.random(in: 42...100))
            mileage = Int.random(in: 300...14_000)
            needed = Self.pickNeededPart(condition: condition, battery: battery)
        }

        // Прошивка — только у шеринговых моделей.
        if model.kind == .sharing && Int.random(in: 0..<100) < 50 {
            flashFault = [FlashFault.all, .controller, .battery, .display].randomElement()
            condition = min(condition, 90)
        }

        var number: NumberPlate?
        if model.kind == .sharing && Int.random(in: 0..<100) < 30 {
            number = NumberFactory.make(NumberFactory.rollRarity())
        }

        let temp = OwnedScooter(
            modelID: model.id,
            condition: condition,
            battery: battery,
            mileage: mileage,
            number: number,
            boughtPrice: 0,
            neededPart: needed,
            flashFault: flashFault
        )

        let fair = breakdown(for: temp).total
        let factor = clean ? Double.random(in: 0.86...1.02) : Double.random(in: 0.72...0.97)
        let price = roundToHundred(Int(Double(max(fair, 3_000)) * factor))

        return Listing(
            modelID: model.id,
            condition: condition,
            battery: battery,
            mileage: mileage,
            number: number,
            price: price,
            seller: Self.sellerName(for: model.kind),
            neededPart: needed,
            flashFault: flashFault
        )
    }

    func buy(_ listing: Listing) {
        guard state.money >= listing.price else {
            showToast("Не хватает \(rub(listing.price - state.money))")
            return
        }

        state.money -= listing.price
        state.totalSpent += listing.price
        state.totalBought += 1

        let scooter = OwnedScooter(
            modelID: listing.modelID,
            condition: listing.condition,
            battery: listing.battery,
            mileage: listing.mileage,
            number: listing.number,
            boughtPrice: listing.price,
            neededPart: listing.neededPart,
            flashFault: listing.flashFault
        )
        state.scooters.insert(scooter, at: 0)
        state.listings.removeAll { $0.id == listing.id }
        save()
        showToast("Купил \(listing.model.name) за \(rub(listing.price))")
    }

    // MARK: Гараж

    func repairCost(for scooter: OwnedScooter) -> Int {
        Int((100 - scooter.condition) * Double(scooter.model.basePrice) * 0.0032) + 400
    }

    func neededPart(for scooter: OwnedScooter) -> PartKind {
        scooter.neededPart ?? .pads
    }

    func repair(id: UUID) {
        guard let index = state.scooters.firstIndex(where: { $0.id == id }) else { return }
        let scooter = state.scooters[index]
        if let fault = scooter.flashFault {
            showToast("Сначала прошей: \(fault.shortTitle)")
            return
        }
        guard scooter.condition < 99.9 else {
            showToast("Самокат и так в порядке")
            return
        }

        let part = neededPart(for: scooter)
        guard stock(of: part) > 0 else {
            showToast("Купи «\(part.title)» в разделе Запчасти")
            return
        }

        let cost = repairCost(for: scooter)
        guard state.money >= cost else {
            showToast("Не хватает \(rub(cost - state.money)) на ремонт")
            return
        }

        state.money -= cost
        state.totalSpent += cost
        state.parts[part.rawValue] = max(0, stock(of: part) - 1)
        state.scooters[index].condition = 100
        state.scooters[index].battery = max(state.scooters[index].battery, 60)
        state.scooters[index].neededPart = nil
        state.repairs += 1
        save()
        showToast("Отремонтировал: \(scooter.model.name)")
    }

    // MARK: Тюнинг

    func tuneCost(_ kind: TuneKind, for scooter: OwnedScooter) -> Int {
        let base = scooter.model.basePrice
        switch kind {
        case .firmware: return max(2_500, Int(Double(base) * 0.04))
        case .custom:   return max(3_000, Int(Double(base) * 0.05))
        }
    }

    func isTuned(_ kind: TuneKind, _ scooter: OwnedScooter) -> Bool {
        switch kind {
        case .firmware: return scooter.firmware
        case .custom:   return scooter.custom
        }
    }

    func applyTune(_ kind: TuneKind, id: UUID) {
        guard let index = state.scooters.firstIndex(where: { $0.id == id }) else { return }
        let scooter = state.scooters[index]
        guard !isTuned(kind, scooter) else { return }

        let cost = tuneCost(kind, for: scooter)
        guard state.money >= cost else {
            showToast("Не хватает \(rub(cost - state.money))")
            return
        }
        if kind == .firmware && !owns(.stlink) {
            showToast("Для прошивки нужен ST-LINK V2 (Магазин → Инструмент)")
            return
        }

        state.money -= cost
        state.totalSpent += cost
        switch kind {
        case .firmware:
            state.scooters[index].firmware = true
            state.scooters[index].battery = max(30, state.scooters[index].battery - 4)
        case .custom:
            state.scooters[index].custom = true
        }
        save()
        showToast("\(kind.title) установлен")
    }

    // MARK: Апгрейды

    func upgradeCost(_ kind: UpgradeKind, for scooter: OwnedScooter) -> Int {
        max(1_500, roundToHundred(Int(Double(scooter.model.basePrice) * kind.priceFactor)))
    }

    func hasUpgrade(_ kind: UpgradeKind, _ scooter: OwnedScooter) -> Bool {
        scooter.has(kind)
    }

    func installUpgrade(_ kind: UpgradeKind, id: UUID) {
        guard let index = state.scooters.firstIndex(where: { $0.id == id }) else { return }
        let scooter = state.scooters[index]
        guard !scooter.has(kind) else {
            showToast("Этот апгрейд уже стоит")
            return
        }

        let cost = upgradeCost(kind, for: scooter)
        guard state.money >= cost else {
            showToast("Не хватает \(rub(cost - state.money))")
            return
        }

        state.money -= cost
        state.totalSpent += cost
        state.scooters[index].upgrades.append(kind)

        switch kind {
        case .battery:
            state.scooters[index].battery = 100
        case .motor:
            state.scooters[index].condition = min(100, state.scooters[index].condition + 3)
        default:
            break
        }

        save()
        showToast("\(kind.title) установлен")
    }

    func sell(id: UUID) {
        guard let index = state.scooters.firstIndex(where: { $0.id == id }) else { return }
        let scooter = state.scooters[index]
        let value = breakdown(for: scooter).total
        let price = roundToHundred(Int(Double(value) * Double.random(in: 0.95...1.07)))

        state.money += price
        state.totalEarned += price
        state.profit += price - scooter.boughtPrice
        state.soldCount += 1
        state.scooters.remove(at: index)

        if let number = scooter.number, number.rarity.rank > (state.bestNumber?.rarity.rank ?? -1) {
            state.bestNumber = number
        }

        save()
        showToast("Продано за \(rub(price))")
    }

    // MARK: Номера

    func rollCost(for scooter: OwnedScooter) -> Int {
        scooter.number == nil ? 5_000 : 8_000
    }

    func prepareRoll(for id: UUID) -> RollOutcome? {
        guard let scooter = scooter(id), scooter.model.kind == .sharing else {
            showToast("Номера выбивают только на шеринговых моделях")
            return nil
        }
        let cost = rollCost(for: scooter)
        guard state.money >= cost else {
            showToast("Не хватает \(rub(cost - state.money)) на выбивание")
            return nil
        }
        return RollOutcome(
            scooterID: id,
            plate: NumberFactory.make(NumberFactory.rollRarity()),
            cost: cost
        )
    }

    func commitRoll(_ outcome: RollOutcome) {
        guard let index = state.scooters.firstIndex(where: { $0.id == outcome.scooterID }) else { return }
        guard state.money >= outcome.cost else {
            showToast("Не хватает денег")
            return
        }

        state.money -= outcome.cost
        state.totalSpent += outcome.cost
        state.scooters[index].number = outcome.plate
        state.rolls += 1
        if outcome.plate.rarity.rank > (state.bestNumber?.rarity.rank ?? -1) {
            state.bestNumber = outcome.plate
        }
        save()
    }

    // MARK: Запчасти

    func buyPart(_ part: PartKind) {
        guard state.money >= part.price else {
            showToast("Не хватает \(rub(part.price - state.money))")
            return
        }
        state.money -= part.price
        state.totalSpent += part.price
        state.parts[part.rawValue] = stock(of: part) + 1
        save()
        showToast("Купил: \(part.title)")
    }

    // MARK: Инструмент и прошивка

    func buyTool(_ tool: ToolKind) {
        guard !owns(tool) else { return }
        guard state.money >= tool.price else {
            showToast("Не хватает \(rub(tool.price - state.money))")
            return
        }
        state.money -= tool.price
        state.totalSpent += tool.price
        state.tools[tool.rawValue] = true
        save()
        showToast("Куплено: \(tool.title)")
    }

    /// Прошивка завершена: деталь со склада или самокат с прошивочной неисправностью.
    /// Успех — 70%, иначе блок блокируется: деталь уходит в мусор, ошибка самоката остаётся.
    @discardableResult
    func finishFlash(_ job: FlashJobKind) -> FlashResult {
        let success = Int.random(in: 0..<100) < 70
        var result: FlashResult = success ? .success : .failed

        switch job {
        case .part(let part):
            let pending = unflashedStock(of: part)
            guard pending > 0 else {
                showToast("Нечего прошивать")
                return .failed
            }
            state.unflashed[part.rawValue] = pending - 1
            if success {
                state.parts[part.rawValue] = stock(of: part) + 1
                state.flashedParts += 1
            } else {
                state.flashFails += 1
                result = .failed
            }

        case .scooter(let id, _):
            guard let index = state.scooters.firstIndex(where: { $0.id == id }) else {
                return .failed
            }
            if success {
                state.scooters[index].flashFault = nil
                state.flashedScooters += 1
            } else {
                state.flashFails += 1
                result = .failed
            }
        }
        save()
        return result
    }

    // MARK: Профиль

    func setPlayerName(_ name: String) {
        let trimmed = String(name.prefix(18))
        state.playerName = trimmed
        save()
    }

    func resetProgress() {
        state = GameState.fresh()
        regenerateMarket(free: true)
        showToast("Прогресс сброшен")
    }

    var levelIndex: Int {
        var result = 0
        for (index, tier) in LevelTier.all.enumerated() where state.profit >= tier.need {
            result = index
        }
        return result
    }

    var level: LevelTier {
        LevelTier.all[levelIndex]
    }

    var nextLevel: LevelTier? {
        let next = levelIndex + 1
        return next < LevelTier.all.count ? LevelTier.all[next] : nil
    }

    /// Прогресс до следующего уровня, 0...1.
    var levelProgress: Double {
        guard let next = nextLevel else { return 1 }
        let from = level.need
        let span = max(1, next.need - from)
        return min(1, max(0, Double(state.profit - from) / Double(span)))
    }

    var daysInGame: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: state.startedAt)
        let today = calendar.startOfDay(for: Date())
        return max(0, calendar.dateComponents([.day], from: start, to: today).day ?? 0)
    }

    // MARK: Разборка шеринга

    private static let stripModels = [
        "ninebot-s90l",
        "ninebot-snsc20", "ninebot-snsc22", "ninebot-snsc23", "ninebot-snsc24",
    ]

    private static let stripAddresses = [
        "ул. Ленина, 12", "парк у метро", "набережная, 4",
        "ТЦ «Галерея»", "школа №7", "сквер у вокзала", "двор на Пушкина",
    ]

    func refreshStreet() {
        var units: [StreetUnit] = []
        for _ in 0..<3 {
            let modelID = Self.stripModels.randomElement() ?? "ninebot-s90l"
            units.append(
                StreetUnit(
                    modelID: modelID,
                    address: Self.stripAddresses.randomElement() ?? "улица",
                    plate: NumberFactory.make(NumberFactory.rollRarity())
                )
            )
        }
        streetUnits = units
    }

    /// Возвращает добычу или сигнал, что поймала служба безопасности.
    /// Шанс поимки — 30%, тогда изымаются все самокаты из гаража.
    func strip(_ unit: StreetUnit) -> StripResult {
        streetUnits.removeAll { $0.id == unit.id }
        state.strips += 1

        if Int.random(in: 0..<100) < 30 {
            let lost = state.scooters.count
            state.scooters.removeAll()
            state.caught += 1
            save()
            showToast("СБ изъяла все самокаты (\(lost) шт.)")
            return .caught
        }

        // С шерингового Ninebot всегда снимаем электронику: контроллер, батарею и дисплей.
        let loot: [PartKind] = [.controller, .battery, .display]
        for part in loot {
            state.unflashed[part.rawValue] = unflashedStock(of: part) + 1
        }
        save()
        return .success(loot)
    }

    // MARK: Тост

    func showToast(_ text: String) {
        toastWork?.cancel()
        toast = text
        let work = DispatchWorkItem { [weak self] in self?.toast = nil }
        toastWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6, execute: work)
    }

    // MARK: Приватное

    private static func pickNeededPart(condition: Double, battery: Double) -> PartKind {
        if battery < 55 { return .battery }
        let roll = Int.random(in: 0..<100)
        switch roll {
        case ..<22: return .tire
        case ..<42: return .pads
        case ..<56: return .controller
        case ..<62: return .display
        case ..<74: return .motor
        case ..<86: return .bearing
        case ..<94: return .disc
        default:    return .battery
        }
    }

    private static func sellerName(for kind: ScooterKind) -> String {
        let personal = ["Артём", "Даня", "Серёга", "Марина", "Костя", "Дядя Вова", "Лёха", "Настя", "Илья", "Витя"]
        let sharing = ["Сервис аренды", "Прокат №1", "Склад шеринга", "Мастерская парка", "Кикшеринг-склад"]
        let pool = kind == .sharing ? sharing : personal
        return pool.randomElement() ?? "Продавец"
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }

    private static func loadState() -> GameState? {
        guard let data = UserDefaults.standard.data(forKey: "scooter-flip-save-v2") else {
            return nil
        }
        return try? JSONDecoder().decode(GameState.self, from: data)
    }
}
