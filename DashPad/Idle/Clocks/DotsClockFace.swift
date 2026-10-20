// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// DotsClockFace.swift - a big hour beside a 10 × 6 grid of minute dots, one row per ten minutes.

import SwiftUI

struct DotsClockFace: View {
    let date: Date
    let colors: DotsColors
    let typeface: ClockTypeface
    let options: ClockOptions
    let scale: CGFloat

    var body: some View {
        let s = scale
        let time = ClockTime(date, hourFormat: options.hourFormat)
        let hourFont = ClockFont(size: 360 * s, weight: ClockStyle.dots.faceWeight, typeface: typeface)

        HStack(alignment: .center, spacing: 96 * s) {
            // Two digits are wider than the 340 column; like the design, they overflow to the left.
            VStack(alignment: .trailing, spacing: 0) {
                Text(time.hourText())
                    .font(hourFont.font.monospacedDigit())
                    .tracking(-0.05 * hourFont.size)
                    .fixedSize()
                    .lineBox(hourFont, 0.82)
                if options.showDate {
                    let font = ClockFont(size: 30 * s, weight: .bold, typeface: typeface)
                    Text(time.shortDate)
                        .font(font.font)
                        .tracking(0.04 * font.size)
                        .fixedSize()
                        .padding(.top, 20 * s)
                }
            }
            .frame(width: 340 * s, alignment: .trailing)

            VStack(spacing: 18 * s) {
                ForEach(0..<6, id: \.self) { row in
                    HStack(spacing: 16 * s) {
                        if options.dotsShowScale {
                            Text(String(format: "%02d", row * 10))
                                .font(ClockFont(size: 20 * s, weight: .bold, typeface: typeface).font.monospacedDigit())
                                .fixedSize()
                                .frame(width: 44 * s, alignment: .trailing)
                                .opacity(0.55)
                        }
                        ForEach(0..<10, id: \.self) { column in
                            dot(row * 10 + column, minute: time.minute)
                        }
                    }
                }
            }
        }
        .foregroundColor(colors.ink)
        .designFrame(scale: s)
    }

    private func dot(_ n: Int, minute: Int) -> some View {
        let s = scale
        let (width, radius): (CGFloat, CGFloat) = switch options.dotShape {
        case .circle: (40, 20)
        case .square: (40, 8)
        case .bar: (18, 9)
        }
        let color = n < minute ? colors.lit : (n == minute ? colors.now : colors.track)
        return RoundedRectangle(cornerRadius: radius * s, style: .continuous)
            .fill(color)
            .frame(width: width * s, height: 40 * s)
    }
}
