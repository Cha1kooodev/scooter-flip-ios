import SwiftUI

// MARK: - Деньги

private let rubFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.groupingSeparator = " "
    f.maximumFractionDigits = 0
    return f
}()

func rub(_ value: Int) -> String {
    let number = rubFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    return number + " ₽"
}

func roundToHundred(_ value: Int) -> Int {
    max(100, Int((Double(value) / 100).rounded()) * 100)
}

// MARK: - Палитра

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    static let appBg = Color(hex: 0x0B0E13)
    static let panel = Color(hex: 0x12161F)
    static let panel2 = Color(hex: 0x171D28)
    static let line = Color(hex: 0x222A38)
    static let textPrimary = Color(hex: 0xE8EDF6)
    static let muted = Color(hex: 0x8B97AB)
    static let accent = Color(hex: 0xFFD400)
    static let good = Color(hex: 0x22C55E)
    static let warn = Color(hex: 0xF59E0B)
    static let bad = Color(hex: 0xEF4444)
}

// MARK: - Тип самоката

enum ScooterKind: String, Codable {
    case personal
    case sharing

    var title: String {
        switch self {
        case .personal: return "Личный"
        case .sharing:  return "Шеринг"
        }
    }

    var color: Color {
        switch self {
        case .personal: return Color.muted
        case .sharing:  return Color.accent
        }
    }
}

// MARK: - Внешний вид для иллюстраций

struct ScooterStyle: Hashable {
    var bodyHex: UInt32
    var accentHex: UInt32
    var offroad = false
    var seat = false
    var bigWheels = false
    var dual = false
    var suspension = false
}

// MARK: - Модели

struct ScooterModel: Identifiable, Hashable {
    let id: String
    let name: String
    let kind: ScooterKind
    let basePrice: Int
    let style: ScooterStyle
}

enum ScooterCatalog {
    // Палитры брендов
    private static let xiaomi   = ScooterStyle(bodyHex: 0x3C424B, accentHex: 0x9AA3AF)
    private static let xiaomiPro = ScooterStyle(bodyHex: 0x333842, accentHex: 0xB8BFC9)
    private static let ninebot  = ScooterStyle(bodyHex: 0x232833, accentHex: 0xC9D1DC)
    private static let ninebotBig = ScooterStyle(bodyHex: 0x262B36, accentHex: 0xC9D1DC, bigWheels: true, suspension: true)
    private static let kugoo    = ScooterStyle(bodyHex: 0xE8762C, accentHex: 0x23262C)
    private static let kugooPro = ScooterStyle(bodyHex: 0xD96522, accentHex: 0x23262C, offroad: true, suspension: true)
    private static let dualtron = ScooterStyle(bodyHex: 0x2B2F36, accentHex: 0xE23B3B, offroad: true, bigWheels: true, dual: true, suspension: true)
    private static let kaabo    = ScooterStyle(bodyHex: 0x30343C, accentHex: 0xF2C230, offroad: true, bigWheels: true, dual: true, suspension: true)
    private static let vsett    = ScooterStyle(bodyHex: 0x2E2733, accentHex: 0xB56CFF, offroad: true, bigWheels: true, suspension: true)
    private static let nami     = ScooterStyle(bodyHex: 0x22262E, accentHex: 0xFF5A3C, offroad: true, bigWheels: true, dual: true, suspension: true)
    private static let apollo   = ScooterStyle(bodyHex: 0x2A2E35, accentHex: 0x38BDF8, suspension: true)
    private static let sharing  = ScooterStyle(bodyHex: 0xFFD400, accentHex: 0x17191E, bigWheels: true)
    private static let sharingGrey = ScooterStyle(bodyHex: 0x30353F, accentHex: 0xFFD400, bigWheels: true)

    static let all: [ScooterModel] = [
        // Xiaomi
        ScooterModel(id: "xiaomi-essential", name: "Xiaomi Mi Electric Scooter Essential", kind: .personal, basePrice: 17_000, style: xiaomi),
        ScooterModel(id: "xiaomi-4-lite", name: "Xiaomi Electric Scooter 4 Lite", kind: .personal, basePrice: 25_000, style: xiaomi),
        ScooterModel(id: "xiaomi-1s", name: "Xiaomi Mi Electric Scooter 1S", kind: .personal, basePrice: 21_000, style: xiaomi),
        ScooterModel(id: "xiaomi-pro2", name: "Xiaomi Mi Electric Scooter Pro 2", kind: .personal, basePrice: 30_000, style: xiaomiPro),
        ScooterModel(id: "xiaomi-4-pro", name: "Xiaomi Electric Scooter 4 Pro", kind: .personal, basePrice: 46_000, style: xiaomiPro),
        ScooterModel(id: "xiaomi-4-max", name: "Xiaomi Electric Scooter 4 Max", kind: .personal, basePrice: 55_000, style: xiaomiPro),
        ScooterModel(id: "xiaomi-4-ultra", name: "Xiaomi Electric Scooter 4 Ultra", kind: .personal, basePrice: 78_000, style: xiaomiPro),
        ScooterModel(id: "xiaomi-5-max", name: "Xiaomi Electric Scooter 5 Max", kind: .personal, basePrice: 72_000, style: xiaomiPro),

        // Ninebot
        ScooterModel(id: "ninebot-e22e", name: "Ninebot KickScooter E22E", kind: .personal, basePrice: 21_000, style: ninebot),
        ScooterModel(id: "ninebot-f30e", name: "Ninebot KickScooter F30E", kind: .personal, basePrice: 27_000, style: ninebot),
        ScooterModel(id: "ninebot-f40e", name: "Ninebot KickScooter F40E", kind: .personal, basePrice: 35_000, style: ninebot),
        ScooterModel(id: "ninebot-d38e", name: "Ninebot KickScooter D38E", kind: .personal, basePrice: 31_000, style: ninebotBig),
        ScooterModel(id: "ninebot-e45e", name: "Ninebot KickScooter E45E", kind: .personal, basePrice: 38_000, style: ninebot),
        ScooterModel(id: "ninebot-f2-pro", name: "Ninebot KickScooter F2 Pro", kind: .personal, basePrice: 43_000, style: ninebot),
        ScooterModel(id: "ninebot-g30p", name: "Ninebot KickScooter Max G30P", kind: .personal, basePrice: 42_000, style: ninebotBig),
        ScooterModel(id: "ninebot-g30d", name: "Ninebot KickScooter Max G30D II", kind: .personal, basePrice: 48_000, style: ninebotBig),
        ScooterModel(id: "ninebot-g2", name: "Ninebot KickScooter Max G2", kind: .personal, basePrice: 68_000, style: ninebotBig),
        ScooterModel(id: "ninebot-gt1", name: "Ninebot KickScooter GT1", kind: .personal, basePrice: 120_000, style: ScooterStyle(bodyHex: 0x262B36, accentHex: 0xF2C230, bigWheels: true, suspension: true)),
        ScooterModel(id: "ninebot-gt2", name: "Ninebot KickScooter GT2", kind: .personal, basePrice: 165_000, style: ScooterStyle(bodyHex: 0x22262E, accentHex: 0xF2C230, bigWheels: true, suspension: true)),
        ScooterModel(id: "ninebot-zt3-pro", name: "Ninebot KickScooter ZT3 Pro", kind: .personal, basePrice: 88_000, style: ScooterStyle(bodyHex: 0x232833, accentHex: 0xE23B3B, offroad: true, bigWheels: true, suspension: true)),

        // Kugoo
        ScooterModel(id: "kugoo-s3", name: "Kugoo S3", kind: .personal, basePrice: 14_000, style: kugoo),
        ScooterModel(id: "kugoo-s3-pro", name: "Kugoo S3 Pro", kind: .personal, basePrice: 19_000, style: kugoo),
        ScooterModel(id: "kugoo-m4-pro", name: "Kugoo M4 Pro", kind: .personal, basePrice: 33_000, style: kugooPro),
        ScooterModel(id: "kugoo-kirin-m4-pro", name: "Kugoo Kirin M4 Pro", kind: .personal, basePrice: 36_000, style: kugooPro),
        ScooterModel(id: "kugoo-g2-pro", name: "Kugoo G2 Pro", kind: .personal, basePrice: 42_000, style: kugooPro),
        ScooterModel(id: "kugoo-m5-pro", name: "Kugoo M5 Pro", kind: .personal, basePrice: 45_000, style: kugooPro),
        ScooterModel(id: "kugoo-kirin-g3-pro", name: "Kugoo Kirin G3 Pro", kind: .personal, basePrice: 52_000, style: kugooPro),
        ScooterModel(id: "kugoo-kirin-v2", name: "Kugoo Kirin V2", kind: .personal, basePrice: 58_000, style: kugooPro),
        ScooterModel(id: "kugoo-kirin-gx", name: "Kugoo Kirin GX", kind: .personal, basePrice: 66_000, style: kugooPro),

        // Производительные бренды
        ScooterModel(id: "apollo-city", name: "Apollo City 2023", kind: .personal, basePrice: 90_000, style: apollo),
        ScooterModel(id: "dualtron-mini", name: "Dualtron Mini", kind: .personal, basePrice: 95_000, style: dualtron),
        ScooterModel(id: "vsett-9", name: "Vsett 9+", kind: .personal, basePrice: 110_000, style: vsett),
        ScooterModel(id: "kaabo-mantis-10", name: "Kaabo Mantis 10", kind: .personal, basePrice: 130_000, style: kaabo),
        ScooterModel(id: "vsett-10", name: "Vsett 10+", kind: .personal, basePrice: 160_000, style: vsett),
        ScooterModel(id: "dualtron-eagle", name: "Dualtron Eagle Pro", kind: .personal, basePrice: 210_000, style: dualtron),
        ScooterModel(id: "kaabo-wolf-x", name: "Kaabo Wolf Warrior X", kind: .personal, basePrice: 240_000, style: kaabo),
        ScooterModel(id: "nami-burn-e2", name: "NAMI Burn-e 2", kind: .personal, basePrice: 280_000, style: nami),

        // Шеринг
        ScooterModel(id: "ninebot-es2-es4", name: "Ninebot KickScooter ES2 / ES4 (Commercial / Sharing Edition)", kind: .sharing, basePrice: 28_000, style: sharing),
        ScooterModel(id: "ninebot-snsc20", name: "Ninebot KickScooter Max SNSC 2.0", kind: .sharing, basePrice: 55_000, style: sharingGrey),
        ScooterModel(id: "ninebot-snsc22", name: "Ninebot KickScooter Max SNSC 2.2", kind: .sharing, basePrice: 62_000, style: sharingGrey),
        ScooterModel(id: "ninebot-snsc23", name: "Ninebot KickScooter Max SNSC 2.3", kind: .sharing, basePrice: 68_000, style: sharingGrey),
        ScooterModel(id: "ninebot-snsc24", name: "Ninebot KickScooter Max SNSC 2.4", kind: .sharing, basePrice: 75_000, style: sharingGrey),
        ScooterModel(id: "ninebot-t60", name: "Ninebot KickScooter T60 (Sharing)", kind: .sharing, basePrice: 85_000, style: sharing),
        ScooterModel(id: "ninebot-s90l", name: "Ninebot KickScooter S90L", kind: .sharing, basePrice: 95_000, style: sharing),
    ]

    static func model(_ id: String) -> ScooterModel {
        all.first { $0.id == id }
            ?? ScooterModel(id: id, name: "Неизвестный самокат", kind: .personal, basePrice: 20_000, style: xiaomi)
    }
}

// MARK: - Редкость номера

enum NumberRarity: String, Codable, CaseIterable, Identifiable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .common:    return "Обычный"
        case .uncommon:  return "Необычный"
        case .rare:      return "Редкий"
        case .epic:      return "Эпический"
        case .legendary: return "Легендарный"
        }
    }

    /// Надбавка к цене самоката при продаже.
    var bonus: Int {
        switch self {
        case .common:    return 0
        case .uncommon:  return 2_000
        case .rare:      return 30_000
        case .epic:      return 90_000
        case .legendary: return 300_000
        }
    }

    var color: Color {
        switch self {
        case .common:    return Color.muted
        case .uncommon:  return Color.good
        case .rare:      return Color(hex: 0x38BDF8)
        case .epic:      return Color(hex: 0xA78BFA)
        case .legendary: return Color.accent
        }
    }

    var rank: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        }
    }
}

struct NumberPlate: Codable, Equatable, Identifiable {
    var id: String { code }
    let code: String
    let rarity: NumberRarity
}

enum NumberFactory {
    static let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")

    static func randomLetter() -> String {
        String(letters[Int.random(in: 0..<letters.count)])
    }

    static func letters3() -> String {
        randomLetter() + randomLetter() + randomLetter()
    }

    static func digits3() -> String {
        (0..<3).map { _ in String(Int.random(in: 0...9)) }.joined()
    }

    static func randomCommonCode() -> String {
        letters3() + digits3()
    }

    /// Редкость выпадает по весам: легендарка ~0,6%.
    static func rollRarity() -> NumberRarity {
        let roll = Double.random(in: 0..<100)
        switch roll {
        case ..<62:  return .common
        case ..<88:  return .uncommon
        case ..<97:  return .rare
        case ..<99.4: return .epic
        default:     return .legendary
        }
    }

    static func make(_ rarity: NumberRarity) -> NumberPlate {
        let code: String
        switch rarity {
        case .legendary:
            let d = Int.random(in: 1...9)
            code = "\(d)\(d)\(d)-\(d)\(d)\(d)"

        case .epic:
            let l = randomLetter()
            let d = Int.random(in: 0...9)
            code = "\(l)\(l)\(l)\(d)\(d)\(d)"

        case .rare:
            let l = randomLetter()
            code = "\(l)\(l)\(l)\(digits3())"

        case .uncommon:
            let d1 = Int.random(in: 0...9)
            var d2 = Int.random(in: 0...9)
            if d2 == d1 { d2 = (d1 + 1) % 10 }
            code = "\(letters3())\(d1)\(d1)\(d2)"

        case .common:
            code = letters3() + digits3()
        }
        return NumberPlate(code: code, rarity: rarity)
    }
}

// MARK: - Запчасти для ремонта

enum PartKind: String, Codable, CaseIterable, Identifiable {
    case tire
    case pads
    case controller
    case battery
    case motor
    case bearing
    case disc

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tire:       return "Покрышка"
        case .pads:       return "Тормозные колодки"
        case .controller: return "Контроллер"
        case .battery:    return "Аккумулятор"
        case .motor:      return "Мотор-колесо"
        case .bearing:    return "Подшипники"
        case .disc:       return "Тормозной диск"
        }
    }

    var icon: String {
        switch self {
        case .tire:       return "circle.dashed"
        case .pads:       return "line.3.horizontal"
        case .controller: return "cpu"
        case .battery:    return "bolt.fill"
        case .motor:      return "gearshape.fill"
        case .bearing:    return "circle.hexagongrid"
        case .disc:       return "record.circle"
        }
    }

    var artKey: String {
        switch self {
        case .tire:       return "tire"
        case .pads:       return "pads"
        case .controller: return "controller"
        case .battery:    return "battery"
        case .motor:      return "motor"
        case .bearing:    return "bearing"
        case .disc:       return "disc"
        }
    }

    var price: Int {
        switch self {
        case .tire:       return 2_500
        case .pads:       return 1_500
        case .controller: return 12_000
        case .battery:    return 19_000
        case .motor:      return 22_000
        case .bearing:    return 1_200
        case .disc:       return 2_200
        }
    }

    var note: String {
        switch self {
        case .tire:       return "Проколы и износ колёс"
        case .pads:       return "Тормоза и скрип"
        case .controller: return "Ошибки, самокат не едет"
        case .battery:    return "Просадка батареи"
        case .motor:      return "Гудит и не тянет"
        case .bearing:    return "Люфт и хруст в колесе"
        case .disc:       return "Восьмёрка и биение"
        }
    }
}

// MARK: - Тюнинг

/// Железо: ставится на конкретный самокат и даёт процент к цене.
enum UpgradeKind: String, Codable, CaseIterable, Identifiable {
    case vesc
    case motor
    case battery
    case suspension
    case tires
    case brakes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vesc:       return "Контроллер VESC"
        case .motor:      return "Мотор 1000 Вт"
        case .battery:    return "Батарея 60V 20Ah"
        case .suspension: return "Подвеска"
        case .tires:      return "Внедорожные покрышки"
        case .brakes:     return "Гидравлические тормоза"
        }
    }

    var icon: String {
        switch self {
        case .vesc:       return "cpu"
        case .motor:      return "gearshape.2.fill"
        case .battery:    return "bolt.batteryblock.fill"
        case .suspension: return "arrow.up.and.down"
        case .tires:      return "circle.dashed"
        case .brakes:     return "record.circle"
        }
    }

    var artKey: String {
        switch self {
        case .vesc:       return "vesc"
        case .motor:      return "motor"
        case .battery:    return "batteryUp"
        case .suspension: return "suspension"
        case .tires:      return "tiresUp"
        case .brakes:     return "disc"
        }
    }

    var detail: String {
        switch self {
        case .vesc:       return "Плавный газ, рекуперация и настройка тока"
        case .motor:      return "Динамика и тяга в горку"
        case .battery:    return "Запас хода и меньше просадка"
        case .suspension: return "Мягче на плитке и бордюрах"
        case .tires:      return "Сцепление на грунте и в дождь"
        case .brakes:     return "Тормозит уверенно с любой скорости"
        }
    }

    /// Доля от базовой цены модели.
    var priceFactor: Double {
        switch self {
        case .vesc:       return 0.16
        case .motor:      return 0.18
        case .battery:    return 0.22
        case .suspension: return 0.13
        case .tires:      return 0.07
        case .brakes:     return 0.09
        }
    }

    /// Надбавка к цене самоката.
    var valueBonus: Double {
        switch self {
        case .vesc:       return 0.10
        case .motor:      return 0.16
        case .battery:    return 0.20
        case .suspension: return 0.12
        case .tires:      return 0.06
        case .brakes:     return 0.08
        }
    }

    var bonusText: String {
        "+\(Int((valueBonus * 100).rounded()))% к цене"
    }
}

// MARK: - Владение

struct OwnedScooter: Identifiable, Codable, Equatable {
    var id = UUID()
    var modelID: String
    var condition: Double        // 0...100
    var battery: Double          // здоровье батареи 0...100
    var mileage: Int             // км
    var number: NumberPlate?
    var firmware = false
    var custom = false
    var upgrades: [UpgradeKind] = []
    var boughtPrice: Int
    var neededPart: PartKind?

    var model: ScooterModel { ScooterCatalog.model(modelID) }

    func has(_ upgrade: UpgradeKind) -> Bool {
        upgrades.contains(upgrade)
    }
}

/// Шеринговый самокат, найденный «на улице» для разборки.
struct StreetUnit: Identifiable {
    let id = UUID()
    let modelID: String
    let address: String
    let plate: NumberPlate?

    var model: ScooterModel { ScooterCatalog.model(modelID) }
}

enum StripResult {
    case success([PartKind])
    case caught
}

struct Listing: Identifiable, Codable {
    var id = UUID()
    var modelID: String
    var condition: Double
    var battery: Double
    var mileage: Int
    var number: NumberPlate?
    var price: Int
    var seller: String
    var neededPart: PartKind?

    var model: ScooterModel { ScooterCatalog.model(modelID) }
}

// MARK: - Расчёт цены

struct ValueBreakdown {
    var base: Int
    var condition: Int
    var battery: Int
    var mileage: Int
    var tuning: Int
    var upgrades: Int
    var number: Int
    var total: Int
}
