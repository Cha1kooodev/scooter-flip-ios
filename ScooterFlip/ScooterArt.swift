import SwiftUI

/// Рисованный вид самоката сбоку. Масштабируется под любой размер.
struct ScooterArt: View {
    let model: ScooterModel
    var plate: String? = nil

    var body: some View {
        Canvas { ctx, size in
            let unit = min(size.width / 120, size.height / 70)
            guard unit > 0 else { return }
            ctx.translateBy(x: (size.width - 120 * unit) / 2,
                            y: (size.height - 70 * unit) / 2)
            ctx.scaleBy(x: unit, y: unit)
            draw(ctx: &ctx)
        }
        .accessibilityHidden(true)
    }

    private func draw(ctx: inout GraphicsContext) {
        let body = Color(hex: model.style.bodyHex)
        let accent = Color(hex: model.style.accentHex)
        let dark = Color(hex: 0x11141A)
        let rubber = Color(hex: 0x15181F)
        let metal = Color(hex: 0x8E96A3)

        // тень на полу
        ctx.fill(
            Path(ellipseIn: CGRect(x: 14, y: 57, width: 92, height: 7)),
            with: .color(.black.opacity(0.35))
        )

        let radius: CGFloat = model.style.bigWheels ? 12 : 10
        let rear = CGPoint(x: 28, y: 48)
        let front = CGPoint(x: 94, y: 48)

        drawWheel(ctx: &ctx, center: rear, radius: radius,
                  accent: accent, rubber: rubber, metal: metal)
        drawWheel(ctx: &ctx, center: front, radius: radius,
                  accent: accent, rubber: rubber, metal: metal)

        // крылья над колёсами
        for center in [rear, front] {
            var fender = Path()
            fender.addArc(center: center, radius: radius + 2.4,
                          startAngle: .degrees(203), endAngle: .degrees(337),
                          clockwise: false)
            ctx.stroke(fender, with: .color(body),
                       style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }

        // дека
        ctx.fill(
            Path(roundedRect: CGRect(x: 33, y: 43, width: 49, height: 5.6), cornerRadius: 2.6),
            with: .color(body)
        )
        ctx.fill(
            Path(roundedRect: CGRect(x: 36, y: 43.3, width: 42, height: 1.7), cornerRadius: 0.9),
            with: .color(dark)
        )

        // батарейный отсек
        let boxRect = CGRect(x: 41, y: 48.4, width: 32, height: 5.6)
        ctx.fill(Path(roundedRect: boxRect, cornerRadius: 2), with: .color(dark.opacity(0.9)))
        ctx.stroke(Path(roundedRect: boxRect, cornerRadius: 2),
                   with: .color(body.opacity(0.55)), lineWidth: 0.8)

        // рулевая стойка
        var stem = Path()
        stem.move(to: CGPoint(x: 84, y: 46.5))
        stem.addLine(to: CGPoint(x: 90.5, y: 20))
        ctx.stroke(stem, with: .color(body),
                   style: StrokeStyle(lineWidth: 5, lineCap: .round))
        ctx.stroke(stem, with: .color(accent.opacity(0.55)),
                   style: StrokeStyle(lineWidth: 1.1, lineCap: .round))

        // руль
        var bar = Path()
        bar.move(to: CGPoint(x: 82, y: 18.5))
        bar.addLine(to: CGPoint(x: 105, y: 18.5))
        ctx.stroke(bar, with: .color(body),
                   style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
        ctx.stroke(Path { p in
            p.move(to: CGPoint(x: 82.4, y: 18.5))
            p.addLine(to: CGPoint(x: 86.6, y: 18.5))
        }, with: .color(dark), style: StrokeStyle(lineWidth: 4.4, lineCap: .round))
        ctx.stroke(Path { p in
            p.move(to: CGPoint(x: 100.4, y: 18.5))
            p.addLine(to: CGPoint(x: 104.6, y: 18.5))
        }, with: .color(dark), style: StrokeStyle(lineWidth: 4.4, lineCap: .round))

        // дисплей
        ctx.fill(
            Path(roundedRect: CGRect(x: 88, y: 13.4, width: 7.6, height: 5), cornerRadius: 1.2),
            with: .color(dark)
        )
        ctx.fill(
            Path(roundedRect: CGRect(x: 89.2, y: 14.5, width: 5.2, height: 2.8), cornerRadius: 0.8),
            with: .color(accent.opacity(0.85))
        )

        // сиденье
        if model.style.seat {
            ctx.fill(
                Path(roundedRect: CGRect(x: 36, y: 35.5, width: 17, height: 4.6), cornerRadius: 2.3),
                with: .color(dark)
            )
            var post = Path()
            post.move(to: CGPoint(x: 44, y: 40))
            post.addLine(to: CGPoint(x: 44, y: 43))
            ctx.stroke(post, with: .color(metal), lineWidth: 1.6)
        }

        // подвеска
        if model.style.suspension {
            var spring = Path()
            spring.move(to: CGPoint(x: 85.5, y: 29))
            for index in 0..<7 {
                let y = 29 + CGFloat(index + 1) * 2.2
                let x: CGFloat = index % 2 == 0 ? 82.8 : 88.2
                spring.addLine(to: CGPoint(x: x, y: y))
            }
            ctx.stroke(spring, with: .color(metal),
                       style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
        }

        // бейдж «два мотора»
        if model.style.dual {
            ctx.fill(
                Path(roundedRect: CGRect(x: 71, y: 40.4, width: 6.5, height: 2.3), cornerRadius: 1.2),
                with: .color(accent)
            )
        }

        // номерной знак
        let code = plate ?? (model.kind == .sharing ? "—" : nil)
        if let code = code {
            let plateRect = CGRect(x: 44, y: 55, width: 30, height: 7.4)
            ctx.fill(Path(roundedRect: plateRect, cornerRadius: 1.4),
                     with: .color(Color(hex: 0xFFD400)))
            ctx.stroke(Path(roundedRect: plateRect, cornerRadius: 1.4),
                       with: .color(.black.opacity(0.35)), lineWidth: 0.6)
            let fontSize: CGFloat = code.count > 5 ? 3.6 : 4.6
            ctx.draw(
                Text(code)
                    .font(.system(size: fontSize, weight: .heavy, design: .monospaced))
                    .foregroundColor(.black),
                at: CGPoint(x: plateRect.midX, y: plateRect.midY)
            )
        }
    }

    private func drawWheel(ctx: inout GraphicsContext,
                           center: CGPoint,
                           radius: CGFloat,
                           accent: Color,
                           rubber: Color,
                           metal: Color) {
        let tireRect = CGRect(x: center.x - radius, y: center.y - radius,
                              width: radius * 2, height: radius * 2)

        ctx.fill(Path(ellipseIn: tireRect), with: .color(rubber))
        ctx.stroke(Path(ellipseIn: tireRect.insetBy(dx: 1.1, dy: 1.1)),
                   with: .color(Color(hex: 0x2C313C)), lineWidth: 1.5)

        if model.style.offroad {
            ctx.stroke(Path(ellipseIn: tireRect.insetBy(dx: 2.2, dy: 2.2)),
                       with: .color(Color(hex: 0x3A404D)),
                       style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [2.2, 2.6]))
        }

        let rim = radius * 0.58
        let rimRect = CGRect(x: center.x - rim, y: center.y - rim,
                             width: rim * 2, height: rim * 2)
        ctx.stroke(Path(ellipseIn: rimRect),
                   with: .color(metal.opacity(0.75)), lineWidth: 1.6)

        for index in 0..<5 {
            let angle = Double(index) / 5 * Double.pi * 2
            var spoke = Path()
            spoke.move(to: center)
            spoke.addLine(to: CGPoint(x: center.x + CGFloat(cos(angle)) * rim,
                                      y: center.y + CGFloat(sin(angle)) * rim))
            ctx.stroke(spoke, with: .color(metal.opacity(0.45)), lineWidth: 0.9)
        }

        ctx.fill(Path(ellipseIn: CGRect(x: center.x - 2.2, y: center.y - 2.2,
                                        width: 4.4, height: 4.4)),
                 with: .color(accent))
    }
}
