// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// HalvesClockFace.swift - the screen split in two: hours on the left, minutes on the right.

import SwiftUI

struct HalvesClockFace: View {
    let date: Date
    let colors: HalvesColors
    let typeface: ClockTypeface
    let options: ClockOptions
    let scale: CGFloat

    var body: some View {
        let s = scale
        let time = ClockTime(date, hourFormat: options.hourFormat)

        HStack(spacing: 0) {
            panel(time.hourText(), background: colors.a, ink: colors.aInk)
                .overlay(alignment: .topLeading) {
                    if options.showDate {
                        label(time.shortDate, weight: .bold, tracking: 0.04, color: colors.aInk)
                            .padding(.leading, 56 * s)
                            .padding(.top, 52 * s)
                    }
                }
            panel(time.minuteText, background: colors.b, ink: colors.bInk)
                .overlay(alignment: .topTrailing) {
                    if let meridiem = time.meridiem {
                        label(meridiem, weight: .heavy, tracking: 0.08, color: colors.bInk)
                            .padding(.trailing, 56 * s)
                            .padding(.top, 52 * s)
                    }
                }
        }
        .designFrame(scale: s)
    }

    private func panel(_ number: String, background: Color, ink: Color) -> some View {
        let s = scale
        let tracking = -0.06 * 500 * s
        // Sized for the design's web font; SF's heavier designs set two digits wider than the
        // panel, so they shrink to leave a 20-point margin each side instead of being clipped.
        let font = ClockFont(size: 500 * s, weight: ClockStyle.halves.faceWeight, typeface: typeface,
                             monospacedDigits: true)
            .fitting(number, tracking: tracking, width: 550 * s)
        // With bleed, the design's 0.74 line box sits 34 below the panel's bottom edge, which
        // puts the middle of the digits at y 669 and runs their feet off the screen.
        let centreY: CGFloat = options.halvesBleed ? 669 : 410
        return ZStack {
            background
            Text(number)
                .font(font.font)
                .tracking(tracking)
                .foregroundColor(ink)
                .fixedSize()
                // Tracking also follows the last digit, which pushes the visible glyphs right
                // of centre by half of it; shift them back.
                .position(x: 295 * s + tracking / 2, y: centreY * s)
        }
        .frame(width: 590 * s, height: 820 * s)
        .clipped()
    }

    private func label(_ text: String, weight: UIFont.Weight, tracking: CGFloat, color: Color) -> some View {
        let font = ClockFont(size: 30 * scale, weight: weight, typeface: typeface)
        return Text(text)
            .font(font.font)
            .tracking(tracking * font.size)
            .foregroundColor(color)
    }
}
