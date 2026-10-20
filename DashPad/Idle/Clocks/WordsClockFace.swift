// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// WordsClockFace.swift - the time as a sentence, rounded to five minutes, with the key words highlighted.

import SwiftUI

struct WordsClockFace: View {
    let date: Date
    let colors: WordsColors
    let typeface: ClockTypeface
    let options: ClockOptions
    let scale: CGFloat

    var body: some View {
        let s = scale
        let time = ClockTime(date, hourFormat: options.hourFormat)
        let sentenceFont = ClockFont(size: 122 * s, weight: ClockStyle.words.faceWeight, typeface: typeface)
        let footerFont = ClockFont(size: 30 * s, weight: .semibold, typeface: typeface)

        VStack(alignment: .leading, spacing: 0) {
            Circle().fill(colors.strong).frame(width: 18 * s, height: 18 * s)

            Spacer(minLength: 0)

            Text(sentence(time))
                .font(sentenceFont.font)
                .tracking(-0.02 * sentenceFont.size)
                // Five lines only happen with a large typeface and a long Spanish phrase; shrink
                // rather than push the footer off the canvas.
                .minimumScaleFactor(0.7)
                .frame(maxWidth: 960 * s, alignment: .leading)

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline) {
                if options.showDate {
                    Text(time.longDate(options.wordsLanguage))
                }
                Spacer(minLength: 0)
                if options.wordsShowDigits {
                    Text(time.digits).monospacedDigit()
                }
            }
            .font(footerFont.font)
            .foregroundColor(colors.soft)
        }
        .padding(.top, 88 * s)
        .padding(.horizontal, 104 * s)
        .padding(.bottom, 72 * s)
        .designFrame(scale: s)
    }

    /// One run of text with each word coloured on its own, so it still wraps like a sentence.
    private func sentence(_ time: ClockTime) -> AttributedString {
        let words = ClockPhrase.words(hour: time.hour, minute: time.minute, language: options.wordsLanguage)
        var result = AttributedString()
        for (index, word) in words.enumerated() {
            var run = AttributedString(index == 0 ? word.text : " " + word.text)
            run.foregroundColor = word.isStrong ? colors.strong : colors.rest
            result += run
        }
        return result
    }
}
