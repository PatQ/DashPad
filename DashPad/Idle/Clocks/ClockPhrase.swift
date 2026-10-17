// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// ClockPhrase.swift - the time in words for the Words face, rounded to five minutes, in English or Spanish.

import Foundation

enum ClockPhrase {
    struct Word: Equatable {
        let text: String
        /// The hour word and the minute number word are highlighted; linking words are not.
        let isStrong: Bool
    }

    /// "It's almost twenty-five to ten." as individually styled words.
    static func words(hour: Int, minute: Int, language: WordsLanguage) -> [Word] {
        let rem = minute % 5
        var base = minute - rem
        var hedge = Hedge.none
        if rem >= 3 {
            base += 5
            hedge = .almost
        } else if rem > 0 {
            hedge = .justAfter
        }
        var hour = hour
        if base > 30 { hour += 1 }
        if base == 60 { base = 0 }
        let h12 = hour % 12 == 0 ? 12 : hour % 12

        var out: [Word] = []
        func add(_ text: String, strong: Bool = false) {
            out += text.split(separator: " ").map { Word(text: String($0), isStrong: strong) }
        }

        switch language {
        case .english:
            add("It’s")
            if hedge == .almost { add("almost") }
            if hedge == .justAfter { add("just after") }
            if base == 0 {
                add(englishHours[h12], strong: true)
                add("o’clock")
            } else {
                add(englishMinutes[base]!, strong: true)
                add(base <= 30 ? "past" : "to")
                add(englishHours[h12], strong: true)
            }

        case .spanish:
            let one = h12 == 1
            add(one ? "Es" : "Son")
            if hedge == .almost { add("casi") }
            if hedge == .justAfter { add("poco más de") }
            add(one ? "la" : "las")
            add(spanishHours[h12], strong: true)
            if base == 0 {
                if hedge == .none { add("en punto") }
            } else {
                let (link, number) = spanishMinutes[base]!
                add(link)
                add(number, strong: true)
            }
        }

        let last = out.removeLast()
        out.append(Word(text: last.text + ".", isStrong: last.isStrong))
        return out
    }

    /// The whole sentence as plain text, for VoiceOver and tests.
    static func sentence(hour: Int, minute: Int, language: WordsLanguage) -> String {
        words(hour: hour, minute: minute, language: language).map(\.text).joined(separator: " ")
    }

    private enum Hedge { case none, almost, justAfter }

    private static let englishHours = ["", "one", "two", "three", "four", "five", "six",
                                       "seven", "eight", "nine", "ten", "eleven", "twelve"]
    private static let englishMinutes = [5: "five", 10: "ten", 15: "quarter", 20: "twenty",
                                         25: "twenty-five", 30: "half", 35: "twenty-five",
                                         40: "twenty", 45: "quarter", 50: "ten", 55: "five"]
    private static let spanishHours = ["", "una", "dos", "tres", "cuatro", "cinco", "seis",
                                       "siete", "ocho", "nueve", "diez", "once", "doce"]
    private static let spanishMinutes = [5: ("y", "cinco"), 10: ("y", "diez"), 15: ("y", "cuarto"),
                                         20: ("y", "veinte"), 25: ("y", "veinticinco"), 30: ("y", "media"),
                                         35: ("menos", "veinticinco"), 40: ("menos", "veinte"),
                                         45: ("menos", "cuarto"), 50: ("menos", "diez"), 55: ("menos", "cinco")]
}
