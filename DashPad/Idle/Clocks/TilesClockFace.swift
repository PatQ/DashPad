// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// TilesClockFace.swift - four flip-clock digit tiles, HH : MM, with the date underneath.

import SwiftUI

struct TilesClockFace: View {
    let date: Date
    let colors: TilesColors
    let typeface: ClockTypeface
    let options: ClockOptions
    let scale: CGFloat

    var body: some View {
        let s = scale
        let time = ClockTime(date, hourFormat: options.hourFormat)
        // The hour always fills two tiles; in 12-hour time a leading zero is drawn faintly.
        let hh = Array(time.hourText(padded12Hour: true))
        let mm = Array(time.minuteText)
        let fadeLeadingZero = !time.uses24Hour && hh[0] == "0"

        VStack(spacing: 48 * s) {
            HStack(spacing: 36 * s) {
                HStack(spacing: 20 * s) {
                    tile(hh[0], fill: colors.tileA, ink: colors.digitA, opacity: fadeLeadingZero ? 0.3 : 1)
                    tile(hh[1], fill: colors.tileA, ink: colors.digitA)
                }
                VStack(spacing: 72 * s) {
                    Circle().fill(colors.sub).frame(width: 22 * s, height: 22 * s)
                    Circle().fill(colors.sub).frame(width: 22 * s, height: 22 * s)
                }
                HStack(spacing: 20 * s) {
                    tile(mm[0], fill: colors.tileB, ink: colors.digitB)
                    tile(mm[1], fill: colors.tileB, ink: colors.digitB)
                }
            }

            // AM/PM stays visible with the date hidden: it's part of the time, not the date.
            if options.showDate || time.meridiem != nil {
                HStack(alignment: .firstTextBaseline, spacing: 18 * s) {
                    if options.showDate {
                        Text(time.longDate())
                            .font(ClockFont(size: 34 * s, weight: .semibold, typeface: typeface).font)
                    }
                    if let meridiem = time.meridiem {
                        Text(meridiem)
                            .font(ClockFont(size: 34 * s, weight: .heavy, typeface: typeface).font)
                            .tracking(0.06 * 34 * s)
                    }
                }
                .foregroundColor(colors.sub)
                .fixedSize()
            }
        }
        .designFrame(scale: s)
    }

    private var cornerRadius: CGFloat {
        switch options.tileShape {
        case .rounded: 44
        case .pill: 115
        case .square: 10
        }
    }

    private func tile(_ digit: Character, fill: Color, ink: Color, opacity: Double = 1) -> some View {
        let s = scale
        return ZStack {
            Text(String(digit))
                .font(ClockFont(size: 330 * s, weight: ClockStyle.tiles.faceWeight, typeface: typeface).font)
                .foregroundColor(ink.opacity(opacity))
                .fixedSize()
            if options.tileSplit {
                // A 4-point band across the middle of the tile, in the background colour.
                Rectangle().fill(colors.bg).frame(height: 4 * s)
            }
        }
        .frame(width: 230 * s, height: 400 * s)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius * s, style: .continuous))
    }
}
