// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// ClockTypeface.swift - typeface setting for the themed faces, each face's default design and weight,
// and ClockFont, which builds the system font for a face.

import CoreText
import SwiftUI
import UIKit

enum ClockTypeface: String, CaseIterable, Codable {
    case automatic, sans, rounded, serif, mono

    var displayName: String {
        switch self {
        case .automatic: "Automatic"
        case .sans: "Sans"
        case .rounded: "Rounded"
        case .serif: "Serif"
        case .mono: "Mono"
        }
    }

    /// The design a face is drawn in: this setting, or the face's own default for Automatic.
    func resolved(for style: ClockStyle) -> ClockTypeface {
        self == .automatic ? style.defaultTypeface : self
    }

    fileprivate var systemDesign: UIFontDescriptor.SystemDesign {
        switch self {
        case .automatic, .sans: .default
        case .rounded: .rounded
        case .serif: .serif
        case .mono: .monospaced
        }
    }
}

extension ClockStyle {
    /// The typeface Automatic stands for on this face.
    var defaultTypeface: ClockTypeface {
        switch self {
        case .digital, .analog, .numerals, .halves: .sans
        case .tiles, .sweep: .rounded
        case .words: .serif
        case .dots: .mono
        }
    }

    /// Weight of the face's main figures. Fixed per face; dates and labels set their own.
    var faceWeight: UIFont.Weight {
        switch self {
        case .digital, .analog, .numerals: .regular
        case .tiles: .bold
        case .words, .dots: .medium
        case .halves, .sweep: .heavy
        }
    }
}

/// A system font in one of the four clock designs. Built through UIFont rather than
/// `Font.system` so a face can read the font's real line height, which it needs to reproduce
/// the tight CSS line heights the faces were designed with (see `lineBox(_:_:)`).
struct ClockFont {
    let uiFont: UIFont

    init(size: CGFloat, weight: UIFont.Weight, typeface: ClockTypeface, monospacedDigits: Bool = false) {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        var descriptor = base.fontDescriptor.withDesign(typeface.systemDesign) ?? base.fontDescriptor
        if monospacedDigits {
            // Set on the font itself rather than with SwiftUI's `monospacedDigit()`, so that
            // `fitting(_:tracking:width:)` measures the same glyphs that get drawn.
            descriptor = descriptor.addingAttributes([.featureSettings: [[
                UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector,
            ]]])
        }
        uiFont = UIFont(descriptor: descriptor, size: size)
    }

    private init(uiFont: UIFont) {
        self.uiFont = uiFont
    }

    var font: Font { Font(uiFont as CTFont) }
    var size: CGFloat { uiFont.pointSize }

    /// This font, made smaller if `text` would otherwise be wider than `width`. The faces were
    /// sized for the mockups' web fonts, and some SF designs and weights set digits wider.
    func fitting(_ text: String, tracking: CGFloat, width: CGFloat) -> ClockFont {
        let measured = (text as NSString).size(withAttributes: [.font: uiFont, .kern: tracking]).width
        guard measured > width, measured > 0 else { return self }
        return ClockFont(uiFont: uiFont.withSize(size * width / measured))
    }
}

extension View {
    /// Gives a single line of text a CSS-style line box: `factor` times the font size tall,
    /// centred on the glyphs, which overflow it as they do in the browser. Apply to text that
    /// has already been given `fixedSize()`.
    func lineBox(_ font: ClockFont, _ factor: CGFloat) -> some View {
        padding(.vertical, (font.size * factor - font.uiFont.lineHeight) / 2)
    }
}
