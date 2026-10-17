// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// NumeralsClockFace.swift - four huge overlapping numerals (12, 3, 6, 9) with analogue hands on top.

import SwiftUI

struct NumeralsClockFace: View {
    let date: Date
    let colors: NumeralsColors
    let typeface: ClockTypeface
    let options: ClockOptions
    let scale: CGFloat

    var body: some View {
        let s = scale
        let time = ClockTime(date)
        let seconds = options.showSeconds ? Double(time.second) : 0
        let minutes = Double(time.minute) + seconds / 60
        let hours = Double(time.hour % 12) + minutes / 60
        let numeral = ClockFont(size: 470 * s, weight: ClockStyle.numerals.faceWeight, typeface: typeface)

        ZStack {
            // Boxes from the design, by centre. They overlap on purpose, and "12" runs off the top.
            numeralText("12", numeral, tracking: -0.04).designPosition(590, 200, scale: s)
            numeralText("9", numeral).designPosition(300, 410, scale: s)
            numeralText("3", numeral).designPosition(880, 410, scale: s)
            numeralText("6", numeral).designPosition(590, 620, scale: s)

            hand(width: 24, length: 250, neckWidth: 7, angle: hours * 30)
            hand(width: 18, length: 360, neckWidth: 6, angle: minutes * 6)

            if options.showSeconds {
                // 460 long, pivoting 400 from its tip: its centre sits 170 out from the pivot.
                RoundedRectangle(cornerRadius: 2 * s)
                    .fill(colors.pop)
                    .frame(width: 3 * s, height: 460 * s)
                    .offset(y: -170 * s)
                    .rotationEffect(.degrees(Double(time.second) * 6))
                    .designPosition(590, 410, scale: s)
            }

            ZStack {
                Circle().fill(colors.hand).frame(width: 28 * s, height: 28 * s)
                Circle().fill(options.showSeconds ? colors.pop : colors.ground).frame(width: 10 * s, height: 10 * s)
            }
            .shadow(color: .black.opacity(0.25), radius: 6 * s, y: 4 * s)
            .designPosition(590, 410, scale: s)
        }
        .designFrame(scale: s)
        .overlay(alignment: .bottomLeading) {
            if options.showDate {
                let font = ClockFont(size: 34 * s, weight: .bold, typeface: typeface)
                Text(time.shortDate)
                    .font(font.font)
                    .tracking(0.02 * font.size)
                    .foregroundColor(colors.ink)
                    .padding(.leading, 64 * s)
                    .padding(.bottom, 52 * s)
            }
        }
    }

    private func numeralText(_ text: String, _ font: ClockFont, tracking: CGFloat = 0) -> some View {
        Text(text)
            .font(font.font)
            .tracking(tracking * font.size)
            .foregroundColor(colors.ink)
            .fixedSize()
    }

    /// A rounded capsule with a short thin neck at the pivot end, rotated about the canvas centre.
    private func hand(width: CGFloat, length: CGFloat, neckWidth: CGFloat, angle: Double) -> some View {
        let s = scale
        let neck: CGFloat = 46
        return VStack(spacing: 0) {
            Capsule().fill(colors.hand).frame(width: width * s, height: (length - neck) * s)
            Rectangle().fill(colors.hand).frame(width: neckWidth * s, height: neck * s)
        }
        .offset(y: -length * s / 2)
        .rotationEffect(.degrees(angle))
        // After the rotation, so the shadow always falls downwards as if lit from above.
        .shadow(color: .black.opacity(0.28), radius: 11 * s, y: 8 * s)
        .designPosition(590, 410, scale: s)
    }
}
