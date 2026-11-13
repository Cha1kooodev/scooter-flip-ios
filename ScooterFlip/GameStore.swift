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
            bestNumber: nil
        )
    }
}

/// Виды тюнинга.
enum TuneKind: String, CaseIterable, Identifiable {
    case firmware
    case battery
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firmware: return "Прошивка"
        case .battery:  return "Апгрейд батареи"
        case .custom:   return "Кастом-тюнинг"
        }
    }

    var icon: String {
        switch self {
        case .firmware: return "bolt.horizontal.fill"
        case .battery:  return "battery.100"
        case .custom:   return "paintbrush.fill"
        }
    }

    var effect: String {
        switch self {
        case .firmware: return "+12% к цене, но сажает батарею"
        case .battery:  return "+15% к цене, батарея 100%"
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

// MARK: - Игровой склад

@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var state: GameState
    @Published var toast: String?

    private let saveKey = "scooter-flip-save-v1"
    private var toastWork: DispatchWorkItem?

    init() {
        if let saved = Self.loadState() {
            state = saved
        } else {
            state = GameState.fresh()
            regenerateMarket(free: true)
        }
    }

    // MARK: Доступ

    func scooter(_ id: UUID) -> OwnedScooter? {
        state.scooters.first { $0.id == id }
    }

    func listing(_ id: UUID) -> Listing? {
        state.listings.first { $0.id == id }
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

    func stock(of part: PartKind) -> Int {
        state.parts[part.rawValue] ?? 0
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

        var tuning = 0.0
        if scooter.firmware { tuning += Double(afterMileage) * 0.12 }
        if scooter.bigBattery { tuning += Double(afterMileage) * 0.15 }
        if scooter.custom { tuning += Double(afterMileage) * 0.06 }
        let tuningValue = Int(tuning)

        let numberValue = scooter.number?.rarity.bonus ?? 0

        return ValueBreakdown(
            base: base,
            condition: afterCondition - base,
            battery: afterBattery - afterCondition,
            mileage: afterMileage - afterBattery,
            tuning: tuningValue,
            number: numberValue,
            total: afterMileage + tuningValue + numberValue
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
            neededPart: listing.neededPart
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
        let condition = Double(Int.random(in: 22...88))
        let battery = Double(Int.random(in: 42...100))
        let mileage = Int.random(in: 300...14_000)

        var number: NumberPlate?
        if model.kind == .sharing && Int.random(in: 0..<100) < 30 {
            number = NumberFactory.make(NumberFactory.rollRarity())
        }

        let needed = Self.pickNeededPart(condition: condition, battery: battery)
        let temp = OwnedScooter(
            modelID: model.id,
            condition: condition,
            battery: battery,
            mileage: mileage,
            number: number,
            boughtPrice: 0,
            neededPart: needed
        )

        let fair = breakdown(for: temp).total
        let factor = Double.random(in: 0.72...0.97)
        let price = roundToHundred(Int(Double(max(fair, 3_000)) * factor))

        return Listing(
            modelID: model.id,
            condition: condition,
            battery: battery,
            mileage: mileage,
            number: number,
            price: price,
            seller: Self.sellerName(for: model.kind),
            neededPart: needed
        )
    }

    func buy(_ listing: Listing) {
        guard state.money >= listing.price else {
            showToast("Не хватает \(rub(listing.price - state.money))")
            return
        }

        state.money -= listing.price
        let scooter = OwnedScooter(
            modelID: listing.modelID,
            condition: listing.condition,
            battery: listing.battery,
            mileage: listing.mileage,
            number: listing.number,
            boughtPrice: listing.price,
            neededPart: listing.neededPart
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
        state.parts[part.rawValue] = max(0, stock(of: part) - 1)
        state.scooters[index].condition = 100
        state.scooters[index].battery = max(state.scooters[index].battery, 60)
        state.scooters[index].neededPart = nil
        state.repairs += 1
        save()
        showToast("Отремонтировал: \(scooter.model.name)")
    }

    func tuneCost(_ kind: TuneKind, for scooter: OwnedScooter) -> Int {
        let base = scooter.model.basePrice
        switch kind {
        case .firmware: return max(2_500, Int(Double(base) * 0.04))
        case .battery:  return max(9_000, Int(Double(base) * 0.15))
        case .custom:   return max(3_000, Int(Double(base) * 0.05))
        }
    }

    func isTuned(_ kind: TuneKind, _ scooter: OwnedScooter) -> Bool {
        switch kind {
        case .firmware: return scooter.firmware
        case .battery:  return scooter.bigBattery
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

        state.money -= cost
        switch kind {
        case .firmware:
            state.scooters[index].firmware = true
            state.scooters[index].battery = max(30, state.scooters[index].battery - 4)
        case .battery:
            state.scooters[index].bigBattery = true
            state.scooters[index].battery = 100
        case .custom:
            state.scooters[index].custom = true
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
        state.parts[part.rawValue] = stock(of: part) + 1
        save()
        showToast("Купил: \(part.title)")
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
        case ..<32: return .tire
        case ..<64: return .pads
        case ..<80: return .controller
        case ..<94: return .motor
        default:    return .battery
        }
    }

    private static func sellerName(for kind: ScooterKind) -> String {
        let personal = ["Артём", "Даня", "Серёга", "Марина", "Костя", "Дядя Вова", "Лёха", "Настя"]
        let sharing = ["Сервис аренды", "Прокат №1", "Склад шеринга", "Мастерская парка"]
        let pool = kind == .sharing ? sharing : personal
        return pool.randomElement() ?? "Продавец"
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }

    private static func loadState() -> GameState? {
        guard let data = UserDefaults.standard.data(forKey: "scooter-flip-save-v1") else {
            return nil
        }
        return try? JSONDecoder().decode(GameState.self, from: data)
    }
}
