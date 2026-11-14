import SwiftUI

// MARK: - Заголовок экрана

struct ScreenHeader: View {
    @EnvironmentObject private var store: GameStore

    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.muted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(rub(store.state.money))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.accent)
                Text("прибыль \(signedRub(store.state.profit))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(store.state.profit >= 0 ? .good : .bad)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.panel)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.line, lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
}

func signedRub(_ value: Int) -> String {
    let sign = value >= 0 ? "+" : "−"
    return sign + rub(abs(value))
}

// MARK: - Карточки и мелочи

extension View {
    func cardStyle(padding: CGFloat = 14, corner: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .background(Color.panel)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.line, lineWidth: 1)
            )
    }
}

struct Tag: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 0.8))
    }
}

struct NumberBadge: View {
    let plate: NumberPlate
    var compact = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "number")
                .font(.system(size: compact ? 9 : 10, weight: .bold))
            Text(plate.code)
                .font(.system(size: compact ? 11 : 13, weight: .bold, design: .monospaced))
            if !compact {
                Text(plate.rarity.title)
                    .font(.system(size: 9, weight: .semibold))
            }
        }
        .foregroundColor(plate.rarity.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(plate.rarity.color.opacity(0.14))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(plate.rarity.color.opacity(0.5), lineWidth: 1))
    }
}

struct ScooterIconTile: View {
    let model: ScooterModel
    var size: CGFloat = 54

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Color.panel2)
            Image(systemName: "scooter")
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundColor(model.kind == .sharing ? .accent : .textPrimary)
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(Color.line, lineWidth: 1)
        )
    }
}

struct StatChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.muted)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.panel2)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct MeterBar: View {
    let value: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.line)
                Capsule()
                    .fill(color)
                    .frame(width: max(4, geo.size.width * min(max(value, 0), 100) / 100))
            }
        }
        .frame(height: 6)
    }
}

struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct InfoCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.accent)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }
}

struct PrimaryActionButton: View {
    let title: String
    let icon: String
    var color: Color = .accent
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(enabled ? .appBg : .muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(enabled ? color : Color.panel2)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(enabled ? Color.clear : Color.line, lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 38))
                .foregroundColor(.muted)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.textPrimary)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Большая иллюстрация

struct ArtBanner: View {
    let model: ScooterModel
    var plate: String? = nil
    var height: CGFloat = 96

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x161C27), Color(hex: 0x0D1117)],
                startPoint: .top,
                endPoint: .bottom
            )
            ScooterArt(model: model, plate: plate)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.line, lineWidth: 1)
        )
    }
}

// MARK: - Плитка статистики

struct StatTile: View {
    let icon: String
    let title: String
    let value: String
    var color: Color = .textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(.muted)
                    .lineLimit(1)
            }
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.panel2)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Тост

extension View {
    func toast(_ text: String?) -> some View {
        overlay(alignment: .bottom) {
            if let text = text {
                Text(text)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.appBg)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Color.accent)
                    .clipShape(Capsule())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 78)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: text)
    }
}
