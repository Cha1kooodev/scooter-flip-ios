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

// MARK: - Модели

struct ScooterModel: Identifiable, Hashable {
    let id: String
    let name: String
    let kind: ScooterKind
    let basePrice: Int
}

enum ScooterCatalog {
    static let all: [ScooterModel] = [
        // личные
        ScooterModel(id: "xiaomi-essential", name: "Xiaomi Mi Electric Scooter Essential", kind: .personal, basePrice: 17_000),
        ScooterModel(id: "xiaomi-4-lite", name: "Xiaomi Electric Scooter 4 Lite", kind: .personal, basePrice: 25_000),
        ScooterModel(id: "xiaomi-1s", name: "Xiaomi Mi Electric Scooter 1S", kind: .personal, basePrice: 21_000),
        ScooterModel(id: "xiaomi-4-pro", name: "Xiaomi Electric Scooter 4 Pro", kind: .personal, basePrice: 46_000),
        ScooterModel(id: "xiaomi-4-ultra", name: "Xiaomi Electric Scooter 4 Ultra", kind: .personal, basePrice: 78_000),
        ScooterModel(id: "ninebot-e22e", name: "Ninebot KickScooter E22E", kind: .personal, basePrice: 21_000),
        ScooterModel(id: "ninebot-f2-pro", name: "Ninebot KickScooter F2 Pro", kind: .personal, basePrice: 43_000),
        ScooterModel(id: "ninebot-g30p", name: "Ninebot KickScooter Max G30P", kind: .personal, basePrice: 42_000),
        ScooterModel(id: "ninebot-g2", name: "Ninebot KickScooter Max G2", kind: .personal, basePrice: 68_000),
        ScooterModel(id: "ninebot-gt2", name: "Ninebot KickScooter GT2", kind: .personal, basePrice: 165_000),

        // шеринг
        ScooterModel(id: "ninebot-es2-es4", name: "Ninebot KickScooter ES2 / ES4", kind: .sharing, basePrice: 28_000),
        ScooterModel(id: "ninebot-snsc20", name: "Ninebot KickScooter Max SNSC 2.0", kind: .sharing, basePrice: 55_000),
        ScooterModel(id: "ninebot-snsc22", name: "Ninebot KickScooter Max SNSC 2.2", kind: .sharing, basePrice: 62_000),
        ScooterModel(id: "ninebot-snsc23", name: "Ninebot KickScooter Max SNSC 2.3", kind: .sharing, basePrice: 68_000),
        ScooterModel(id: "ninebot-snsc24", name: "Ninebot KickScooter Max SNSC 2.4", kind: .sharing, basePrice: 75_000),
        ScooterModel(id: "ninebot-s90l", name: "Ninebot KickScooter S90L", kind: .sharing, basePrice: 95_000),

        // Kugoo
        ScooterModel(id: "kugoo-s3", name: "Kugoo S3", kind: .personal, basePrice: 14_000),
        ScooterModel(id: "kugoo-m4-pro", name: "Kugoo Kirin M4 Pro", kind: .personal, basePrice: 36_000),
        ScooterModel(id: "kugoo-g2-pro", name: "Kugoo G2 Pro", kind: .personal, basePrice: 42_000),
        ScooterModel(id: "kugoo-g3-pro", name: "Kugoo Kirin G3 Pro", kind: .personal, basePrice: 52_000),
        ScooterModel(id: "kugoo-gx", name: "Kugoo Kirin GX", kind: .personal, basePrice: 66_000),
    ]

    static func model(_ id: String) -> ScooterModel {
        all.first { $0.id == id }
            ?? ScooterModel(id: id, name: "Неизвестный самокат", kind: .personal, basePrice: 20_000)
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

// MARK: - Запчасти

enum PartKind: String, Codable, CaseIterable, Identifiable {
    case tire
    case pads
    case controller
    case battery
    case motor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tire:       return "Покрышка"
        case .pads:       return "Тормозные колодки"
        case .controller: return "Контроллер"
        case .battery:    return "Аккумулятор"
        case .motor:      return "Мотор-колесо"
        }
    }

    var icon: String {
        switch self {
        case .tire:       return "circle.dashed"
        case .pads:       return "line.3.horizontal"
        case .controller: return "cpu"
        case .battery:    return "bolt.fill"
        case .motor:      return "gearshape.fill"
        }
    }

    var price: Int {
        switch self {
        case .tire:       return 2_500
        case .pads:       return 1_500
        case .controller: return 12_000
        case .battery:    return 19_000
        case .motor:      return 22_000
        }
    }

    var note: String {
        switch self {
        case .tire:       return "Проколы и износ колёс"
        case .pads:       return "Тормоза и скрип"
        case .controller: return "Ошибки, самокат не едет"
        case .battery:    return "Просадка батареи"
        case .motor:      return "Гудит и не тянет"
        }
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
    var bigBattery = false
    var custom = false
    var boughtPrice: Int
    var neededPart: PartKind?

    var model: ScooterModel { ScooterCatalog.model(modelID) }
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
    var number: Int
    var total: Int
}
