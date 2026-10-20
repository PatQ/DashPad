// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// SweepClockFace.swift - a ring that fills up over the hour, with the hour in the middle.

import SwiftUI

struct SweepClockFace: View {
    let date: Date
    let colors: SweepColors
    let typeface: ClockTypeface
    let options: ClockOptions
    let scale: CGFloat

    var body: some View {
        let s = scale
        let time = ClockTime(date, hourFormat: options.hourFormat)
        let minutes = Double(time.minute) + Double(time.second) / 60
        let hours = Double(time.hour % 12) + minutes / 60
        let inner = 600 - 2 * options.sweepRing.width
        let showMinutes = options.sweepShowMinutes && inner >= 200

        ZStack {
            ZStack {
                Circle().fill(colors.track)
                SweepSector(degrees: minutes * 6).fill(colors.fill)
                if inner > 0 {
                    Circle().fill(colors.ground).frame(width: inner * s, height: inner * s)
                }
                VStack(spacing: 0) {
                    if inner >= 110 {
                        let font = ClockFont(size: inner * (showMinutes ? 0.46 : 0.56) * s,
                                             weight: ClockStyle.sweep.faceWeight, typeface: typeface)
                        Text(time.hourText())
                            .font(font.font)
                            .tracking(-0.04 * font.size)
                            .fixedSize()
                            .lineBox(font, 0.9)
                    }
                    if showMinutes {
                        let font = ClockFont(size: inner * 0.12 * s, weight: .semibold, typeface: typeface)
                        Text(":" + time.minuteText)
                            .font(font.font.monospacedDigit())
                            .fixedSize()
                            .lineBox(font, 1.2)
                            .opacity(0.6)
                    }
                }
                .foregroundColor(colors.ink)
            }
            .frame(width: 600 * s, height: 600 * s)
            .designPosition(590, 410, scale: s)

            if options.sweepShowHourDot {
                // The design draws the dot at the top of a 700 box, so its centre orbits at 335.
                Circle()
                    .fill(colors.dot)
                    .frame(width: 30 * s, height: 30 * s)
                    .offset(y: -335 * s)
                    .rotationEffect(.degrees(hours * 30))
                    .designPosition(590, 410, scale: s)
            }
        }
        .designFrame(scale: s)
        .overlay(alignment: .bottomLeading) {
            if options.showDate {
                let font = ClockFont(size: 32 * s, weight: .bold, typeface: typeface)
                Text(time.shortDate)
                    .font(font.font)
                    .tracking(0.02 * font.size)
                    .foregroundColor(colors.ink)
                    .padding(.leading, 64 * s)
                    .padding(.bottom, 52 * s)
            }
        }
    }
}

/// A pie slice from 12 o'clock, clockwise through `degrees`.
private struct SweepSector: Shape {
    var degrees: Double

    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.move(to: centre)
        // `clockwise: false` because SwiftUI's y axis points down, which flips the arc direction.
        path.addArc(center: centre, radius: min(rect.width, rect.height) / 2,
                    startAngle: .degrees(-90), endAngle: .degrees(-90 + degrees), clockwise: false)
        path.closeSubpath()
        return path
    }
}
