// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// ClockTime.swift - the pieces of a date the clock faces draw: hour in the device's 12/24-hour style, padded minutes, date labels.

import Foundation

struct ClockTime {
    let hour: Int      // 0-23
    let minute: Int
    let second: Int
    let uses24Hour: Bool
    private let date: Date

    init(_ date: Date) {
        let parts = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        self.date = date
        hour = parts.hour ?? 0
        minute = parts.minute ?? 0
        second = parts.second ?? 0
        uses24Hour = Self.deviceUses24Hour
    }

    /// Follows Settings › General › Date & Time. Read on every redraw rather than cached, so
    /// flipping the switch shows up on the next tick without restarting the app.
    static var deviceUses24Hour: Bool {
        let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .autoupdatingCurrent) ?? ""
        return !format.contains("a")
    }

    /// 0-23 in 24-hour mode, 1-12 otherwise.
    var displayHour: Int {
        uses24Hour ? hour : (hour % 12 == 0 ? 12 : hour % 12)
    }

    /// The hour as text. 24-hour time is always two digits; 12-hour time pads only when asked.
    func hourText(padded12Hour: Bool = false) -> String {
        uses24Hour || padded12Hour ? String(format: "%02d", displayHour) : String(displayHour)
    }

    var minuteText: String { String(format: "%02d", minute) }

    /// "AM" / "PM", or nil in 24-hour mode.
    var meridiem: String? {
        uses24Hour ? nil : (hour < 12 ? "AM" : "PM")
    }

    /// "09:41" in 24-hour mode, "9:41" in 12-hour mode.
    var digits: String { "\(hourText()):\(minuteText)" }

    /// "SAT 17"
    var shortDate: String { Self.shortDateFormatter.string(from: date).uppercased() }

    /// "Saturday 17 October", or "Sábado, 17 de octubre" in Spanish.
    func longDate(_ language: WordsLanguage = .english) -> String {
        let text = (language == .spanish ? Self.spanishDateFormatter : Self.englishDateFormatter).string(from: date)
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    /// What VoiceOver reads for every face.
    var accessibilityLabel: String {
        date.formatted(date: .omitted, time: .shortened)
    }

    // The faces' labels are drawn as designed (the app is in English), not in the device language.
    private static let shortDateFormatter = formatter("EEE d", locale: "en_US_POSIX")
    private static let englishDateFormatter = formatter("EEEE d MMMM", locale: "en_GB")
    private static let spanishDateFormatter = formatter("EEEE, d 'de' MMMM", locale: "es_ES")

    private static func formatter(_ format: String, locale: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: locale)
        f.dateFormat = format
        return f
    }
}
