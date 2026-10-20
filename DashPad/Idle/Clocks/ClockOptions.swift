// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// ClockOptions.swift - per-face toggles for the themed clock faces, saved as one Codable value.

import Foundation

struct ClockOptions: Codable, Equatable {
    var hourFormat: HourFormat = .system    // every face that shows the hour in digits
    var showDate = true                     // all themed faces
    var showSeconds = true                  // Numerals
    var tileShape: TileShape = .rounded     // Tiles
    var tileSplit = true                    // Tiles: flip-clock line across each tile
    var wordsLanguage: WordsLanguage = .english
    var wordsShowDigits = true              // Words: small time bottom right
    var halvesBleed = true                  // Halves: numbers run off the bottom edge
    var sweepRing: SweepRing = .medium
    var sweepShowMinutes = true             // Sweep: ":41" under the hour
    var sweepShowHourDot = true             // Sweep: orbiting hour marker
    var dotShape: DotShape = .circle
    var dotsShowScale = true                // Dots: 00 10 20... row labels

    init() {}

    /// Every key is optional, so options added in a later release decode from an older save
    /// with their defaults instead of failing and wiping everything the user had set.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ClockOptions()
        hourFormat = (try? c.decodeIfPresent(HourFormat.self, forKey: .hourFormat)) ?? d.hourFormat
        showDate = try c.decodeIfPresent(Bool.self, forKey: .showDate) ?? d.showDate
        showSeconds = try c.decodeIfPresent(Bool.self, forKey: .showSeconds) ?? d.showSeconds
        tileShape = (try? c.decodeIfPresent(TileShape.self, forKey: .tileShape)) ?? d.tileShape
        tileSplit = try c.decodeIfPresent(Bool.self, forKey: .tileSplit) ?? d.tileSplit
        wordsLanguage = (try? c.decodeIfPresent(WordsLanguage.self, forKey: .wordsLanguage)) ?? d.wordsLanguage
        wordsShowDigits = try c.decodeIfPresent(Bool.self, forKey: .wordsShowDigits) ?? d.wordsShowDigits
        halvesBleed = try c.decodeIfPresent(Bool.self, forKey: .halvesBleed) ?? d.halvesBleed
        sweepRing = (try? c.decodeIfPresent(SweepRing.self, forKey: .sweepRing)) ?? d.sweepRing
        sweepShowMinutes = try c.decodeIfPresent(Bool.self, forKey: .sweepShowMinutes) ?? d.sweepShowMinutes
        sweepShowHourDot = try c.decodeIfPresent(Bool.self, forKey: .sweepShowHourDot) ?? d.sweepShowHourDot
        dotShape = (try? c.decodeIfPresent(DotShape.self, forKey: .dotShape)) ?? d.dotShape
        dotsShowScale = try c.decodeIfPresent(Bool.self, forKey: .dotsShowScale) ?? d.dotsShowScale
    }
}

/// 12 or 24-hour time. `system` follows Settings › General › Date & Time.
enum HourFormat: String, CaseIterable, Codable {
    case system, twelveHour, twentyFourHour

    var displayName: String {
        switch self {
        case .system: "System"
        case .twelveHour: "12-hour"
        case .twentyFourHour: "24-hour"
        }
    }

    /// Read on every redraw rather than cached, so flipping the system switch shows up on the
    /// next tick without restarting the app.
    var uses24Hour: Bool {
        switch self {
        case .system:
            let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .autoupdatingCurrent) ?? ""
            return !format.contains("a")
        case .twelveHour: return false
        case .twentyFourHour: return true
        }
    }

    /// "9:41 PM" or "21:41" in the current locale's style.
    func timeText(_ date: Date) -> String {
        switch self {
        case .system: date.formatted(date: .omitted, time: .shortened)
        case .twelveHour: Self.twelveHourFormatter.string(from: date)
        case .twentyFourHour: Self.twentyFourHourFormatter.string(from: date)
        }
    }

    // "h"/"H" in a template force the hour cycle; the locale still picks separators and AM/PM.
    private static let twelveHourFormatter = formatter(template: "hmm")
    private static let twentyFourHourFormatter = formatter(template: "HHmm")

    private static func formatter(template: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate(template)
        return f
    }
}

enum TileShape: String, CaseIterable, Codable {
    case rounded, pill, square

    var displayName: String {
        switch self {
        case .rounded: "Rounded"
        case .pill: "Pill"
        case .square: "Square"
        }
    }
}

enum WordsLanguage: String, CaseIterable, Codable {
    case english, spanish

    var displayName: String {
        switch self {
        case .english: "English"
        case .spanish: "Español"
        }
    }
}

enum SweepRing: String, CaseIterable, Codable {
    case thin, medium, solid

    var displayName: String {
        switch self {
        case .thin: "Thin"
        case .medium: "Medium"
        case .solid: "Solid"
        }
    }

    /// Width of the ring in design points; the inner disc is what's left of the 600 disc.
    var width: CGFloat {
        switch self {
        case .thin: 70
        case .medium: 110
        case .solid: 300
        }
    }
}

enum DotShape: String, CaseIterable, Codable {
    case circle, square, bar

    var displayName: String {
        switch self {
        case .circle: "Circle"
        case .square: "Square"
        case .bar: "Bar"
        }
    }
}
