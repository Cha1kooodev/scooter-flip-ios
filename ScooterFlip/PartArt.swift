import SwiftUI

/// Рисованные «фото» запчастей и апгрейдов.
struct PartArt: View {
    let key: String

    var body: some View {
        Canvas { ctx, size in
            let unit = min(size.width, size.height) / 64
            guard unit > 0 else { return }
            ctx.translateBy(x: (size.width - 64 * unit) / 2,
                            y: (size.height - 64 * unit) / 2)
            ctx.scaleBy(x: unit, y: unit)
            draw(ctx: &ctx)
        }
        .accessibilityHidden(true)
    }

    private func draw(ctx: inout GraphicsContext) {
        let dark = Color(hex: 0x15181F)
        let metal = Color(hex: 0x8E96A3)

        switch key {
        case "tire", "tiresUp":
            ctx.fill(Path(ellipseIn: CGRect(x: 10, y: 10, width: 44, height: 44)),
                     with: .color(dark))
            if key == "tiresUp" {
                for index in 0..<14 {
                    let angle = Double(index) / 14 * Double.pi * 2
                    let x = 32 + CGFloat(cos(angle)) * 20
                    let y = 32 + CGFloat(sin(angle)) * 20
                    ctx.fill(Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6)),
                             with: .color(Color(hex: 0x2C313C)))
                }
            }
            ctx.stroke(Path(ellipseIn: CGRect(x: 12, y: 12, width: 40, height: 40)),
                       with: .color(Color(hex: 0x30353F)),
                       style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
            ctx.stroke(Path(ellipseIn: CGRect(x: 22, y: 22, width: 20, height: 20)),
                       with: .color(metal), lineWidth: 2.2)
            ctx.fill(Path(ellipseIn: CGRect(x: 29, y: 29, width: 6, height: 6)),
                     with: .color(.accent))

        case "pads":
            ctx.fill(Path(roundedRect: CGRect(x: 12, y: 14, width: 40, height: 11), cornerRadius: 3),
                     with: .color(metal))
            ctx.fill(Path(roundedRect: CGRect(x: 14, y: 25, width: 36, height: 9), cornerRadius: 2),
                     with: .color(Color(hex: 0x6B4A2A)))
            ctx.fill(Path(roundedRect: CGRect(x: 16, y: 38, width: 32, height: 10), cornerRadius: 2),
                     with: .color(Color(hex: 0x553A21)))
            ctx.stroke(Path(roundedRect: CGRect(x: 16, y: 38, width: 32, height: 10), cornerRadius: 2),
                       with: .color(.white.opacity(0.12)), lineWidth: 1)

        case "controller":
            ctx.fill(Path(roundedRect: CGRect(x: 10, y: 18, width: 44, height: 26), cornerRadius: 4),
                     with: .color(Color(hex: 0x22262E)))
            for index in 0..<6 {
                let x = 14 + CGFloat(index) * 6.4
                ctx.fill(Path(roundedRect: CGRect(x: x, y: 21, width: 2.4, height: 20), cornerRadius: 1),
                         with: .color(Color(hex: 0x3A404D)))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: 40, y: 25, width: 8, height: 8)),
                     with: .color(.accent))
            let wireColors: [Color] = [Color(hex: 0xEF4444), Color(hex: 0x22C55E), Color(hex: 0x38BDF8)]
            for index in 0..<3 {
                let x = 16 + CGFloat(index) * 8
                var wire = Path()
                wire.move(to: CGPoint(x: x, y: 44))
                wire.addCurve(to: CGPoint(x: x + 3, y: 56),
                              control1: CGPoint(x: x - 4, y: 49),
                              control2: CGPoint(x: x + 7, y: 51))
                ctx.stroke(wire, with: .color(wireColors[index]), lineWidth: 2)
            }

        case "battery", "batteryUp":
            let bodyRect = CGRect(x: 8, y: 18, width: 48, height: 27)
            ctx.fill(Path(roundedRect: bodyRect, cornerRadius: 4),
                     with: .color(Color(hex: 0x1B2430)))
            ctx.stroke(Path(roundedRect: bodyRect, cornerRadius: 4),
                       with: .color(Color(hex: 0x2E3A4C)), lineWidth: 1.5)
            for index in 0..<5 {
                let x = 12 + CGFloat(index) * 8.4
                ctx.fill(Path(roundedRect: CGRect(x: x, y: 22, width: 5.6, height: 15), cornerRadius: 1.6),
                         with: .color(Color(hex: 0x3FA7FF).opacity(0.75)))
            }
            ctx.fill(Path(roundedRect: CGRect(x: 12, y: 39, width: 40, height: 3), cornerRadius: 1),
                     with: .color(Color(hex: 0x2E3A4C)))
            ctx.fill(Path(roundedRect: CGRect(x: 12, y: 14, width: 6, height: 5), cornerRadius: 1),
                     with: .color(.accent))
            ctx.fill(Path(roundedRect: CGRect(x: 46, y: 14, width: 6, height: 5), cornerRadius: 1),
                     with: .color(metal))
            if key == "batteryUp" {
                ctx.stroke(Path(roundedRect: bodyRect.insetBy(dx: -2, dy: -2), cornerRadius: 6),
                           with: .color(.accent.opacity(0.5)), lineWidth: 1.5)
            }

        case "motor":
            let center = CGPoint(x: 32, y: 30)
            ctx.fill(Path(ellipseIn: CGRect(x: 8, y: 6, width: 48, height: 48)),
                     with: .color(dark))
            ctx.stroke(Path(ellipseIn: CGRect(x: 8, y: 6, width: 48, height: 48)),
                       with: .color(Color(hex: 0x3A404D)), lineWidth: 2)
            for index in 0..<12 {
                let angle = Double(index) / 12 * Double.pi * 2
                var spoke = Path()
                spoke.move(to: center)
                spoke.addLine(to: CGPoint(x: center.x + CGFloat(cos(angle)) * 20,
                                          y: center.y + CGFloat(sin(angle)) * 20))
                ctx.stroke(spoke, with: .color(metal.opacity(0.55)), lineWidth: 1.6)
            }
            ctx.fill(Path(ellipseIn: CGRect(x: 26, y: 24, width: 12, height: 12)),
                     with: .color(.accent))
            var cable = Path()
            cable.move(to: CGPoint(x: 44, y: 52))
            cable.addCurve(to: CGPoint(x: 58, y: 58),
                           control1: CGPoint(x: 40, y: 60),
                           control2: CGPoint(x: 54, y: 50))
            ctx.stroke(cable, with: .color(Color(hex: 0x2C313C)), lineWidth: 3)

        case "bearing":
            ctx.stroke(Path(ellipseIn: CGRect(x: 12, y: 12, width: 40, height: 40)),
                       with: .color(metal), lineWidth: 6)
            ctx.stroke(Path(ellipseIn: CGRect(x: 20, y: 20, width: 24, height: 24)),
                       with: .color(Color(hex: 0x30353F)), lineWidth: 1.5)
            for index in 0..<8 {
                let angle = Double(index) / 8 * Double.pi * 2
                let x = 32 + CGFloat(cos(angle)) * 13
                let y = 32 + CGFloat(sin(angle)) * 13
                ctx.fill(Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6)),
                         with: .color(.accent))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: 27, y: 27, width: 10, height: 10)),
                     with: .color(dark))

        case "disc":
            ctx.stroke(Path(ellipseIn: CGRect(x: 12, y: 12, width: 40, height: 40)),
                       with: .color(metal), lineWidth: 4)
            for index in 0..<10 {
                let angle = Double(index) / 10 * Double.pi * 2
                let x = 32 + CGFloat(cos(angle)) * 16
                let y = 32 + CGFloat(sin(angle)) * 16
                ctx.fill(Path(ellipseIn: CGRect(x: x - 1.6, y: y - 1.6, width: 3.2, height: 3.2)),
                         with: .color(Color(hex: 0x0B0E13)))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: 26, y: 26, width: 12, height: 12)),
                     with: .color(Color(hex: 0x30353F)))
            var caliper = Path()
            caliper.addArc(center: CGPoint(x: 32, y: 32), radius: 22,
                           startAngle: .degrees(-30), endAngle: .degrees(28),
                           clockwise: false)
            ctx.stroke(caliper, with: .color(Color(hex: 0xEF4444)),
                       style: StrokeStyle(lineWidth: 7, lineCap: .round))

        case "vesc":
            ctx.fill(Path(roundedRect: CGRect(x: 8, y: 20, width: 48, height: 26), cornerRadius: 3),
                     with: .color(Color(hex: 0x1E5E3A)))
            ctx.fill(Path(roundedRect: CGRect(x: 14, y: 26, width: 12, height: 10), cornerRadius: 1.5),
                     with: .color(Color(hex: 0x101318)))
            ctx.fill(Path(roundedRect: CGRect(x: 30, y: 26, width: 8, height: 10), cornerRadius: 1.5),
                     with: .color(Color(hex: 0x101318)))
            for index in 0..<2 {
                let x = 42 + CGFloat(index) * 7
                ctx.fill(Path(roundedRect: CGRect(x: x, y: 24, width: 4, height: 12), cornerRadius: 2),
                         with: .color(Color(hex: 0xC8CDD6)))
            }
            for index in 0..<4 {
                ctx.fill(Path(roundedRect: CGRect(x: 12 + CGFloat(index) * 6, y: 40, width: 3.5, height: 4), cornerRadius: 1),
                         with: .color(.accent))
            }
            var wire = Path()
            wire.move(to: CGPoint(x: 52, y: 46))
            wire.addCurve(to: CGPoint(x: 58, y: 58),
                          control1: CGPoint(x: 58, y: 48),
                          control2: CGPoint(x: 52, y: 54))
            ctx.stroke(wire, with: .color(Color(hex: 0xEF4444)), lineWidth: 2)

        case "suspension":
            ctx.fill(Path(roundedRect: CGRect(x: 22, y: 6, width: 20, height: 5), cornerRadius: 2),
                     with: .color(metal))
            ctx.fill(Path(roundedRect: CGRect(x: 22, y: 53, width: 20, height: 5), cornerRadius: 2),
                     with: .color(metal))
            var spring = Path()
            spring.move(to: CGPoint(x: 32, y: 11))
            for index in 0..<9 {
                let y = 11 + CGFloat(index + 1) * 4.6
                let x: CGFloat = index % 2 == 0 ? 22 : 42
                spring.addLine(to: CGPoint(x: x, y: y))
            }
            ctx.stroke(spring, with: .color(.accent),
                       style: StrokeStyle(lineWidth: 3, lineCap: .round))
            var rod = Path()
            rod.move(to: CGPoint(x: 32, y: 11))
            rod.addLine(to: CGPoint(x: 32, y: 53))
            ctx.stroke(rod, with: .color(Color(hex: 0x30353F)), lineWidth: 2)

        default:
            break
        }
    }
}
