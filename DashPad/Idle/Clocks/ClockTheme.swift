// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// ClockTheme.swift - colour themes for the themed clock faces: one hand-tuned table per face.

import SwiftUI

/// Themes are data: each face reads its colours from its own table below, so adding a theme
/// means adding a case here and one row per table, with no layout code.
enum ClockTheme: String, CaseIterable, Codable {
    case fern, clay, sky, butter, night, ink, paper

    var displayName: String { rawValue.capitalized }
}

extension ClockStyle {
    /// The theme each face was designed in, used until the user picks another for it.
    var defaultTheme: ClockTheme {
        switch self {
        case .digital, .analog, .numerals, .dots: .fern
        case .tiles: .night
        case .words: .clay
        case .halves: .sky
        case .sweep: .butter
        }
    }
}

/// The theme chosen for each face. Each face remembers its own, so restyling one leaves the
/// others as they were; a face nobody has restyled keeps its designed `defaultTheme`.
struct ClockThemes: Codable, Equatable {
    /// Keyed by `ClockStyle.rawValue`, which is what's persisted.
    private var chosen: [String: ClockTheme] = [:]

    subscript(style: ClockStyle) -> ClockTheme {
        get { chosen[style.rawValue] ?? style.defaultTheme }
        set { chosen[style.rawValue] = newValue }
    }
}

// The tables keep the designer's hex strings verbatim, read by `Color(hex:)` (AnimatedBlobGradient.swift).

// MARK: - Numerals

/// `ground` background · `ink` numerals and date · `hand` hour/minute hands and centre cap ·
/// `pop` seconds hand and the dot in the centre cap.
struct NumeralsColors {
    let ground, ink, hand, pop: Color

    static func `for`(_ theme: ClockTheme) -> NumeralsColors {
        switch theme {
        case .fern:   .init("#5B9462", "#0F1D12", "#FFFFFF", "#FFB547")
        case .clay:   .init("#E2774A", "#2B1006", "#FFF4EC", "#2B1006")
        case .sky:    .init("#9DC3EC", "#0C1C33", "#FFFFFF", "#FF5A36")
        case .butter: .init("#F4D46A", "#2A2208", "#FFFFFF", "#E2552E")
        case .night:  .init("#000000", "#26262B", "#E8E8E8", "#FF9F0A")
        case .ink:    .init("#0E0E10", "#F2F2F2", "#FF5A36", "#FF5A36")
        case .paper:  .init("#F2EFE8", "#1A1A1A", "#E2552E", "#1A1A1A")
        }
    }

    private init(_ ground: String, _ ink: String, _ hand: String, _ pop: String) {
        (self.ground, self.ink, self.hand, self.pop) = (Color(hex: ground), Color(hex: ink), Color(hex: hand), Color(hex: pop))
    }
}

// MARK: - Tiles

/// `bg` background and tile split line · `tileA`/`digitA` hour tiles · `tileB`/`digitB` minute
/// tiles · `sub` colon dots, date, AM/PM.
struct TilesColors {
    let bg, tileA, digitA, tileB, digitB, sub: Color

    static func `for`(_ theme: ClockTheme) -> TilesColors {
        switch theme {
        case .fern:   .init("#5B9462", "#0F1D12", "#F4EBD0", "#F4EBD0", "#0F1D12", "#0F1D12")
        case .clay:   .init("#E2774A", "#2B1006", "#FFE7D6", "#FFE7D6", "#2B1006", "#2B1006")
        case .sky:    .init("#9DC3EC", "#0C1C33", "#FFFFFF", "#FFFFFF", "#0C1C33", "#0C1C33")
        case .butter: .init("#F4D46A", "#2A2208", "#F4D46A", "#2A2208", "#FF8A5C", "#2A2208")
        case .night:  .init("#000000", "#1C1C1F", "#E8E8E8", "#1C1C1F", "#FF9F0A", "#8A8A90")
        case .ink:    .init("#000000", "#F2F2F2", "#000000", "#F2F2F2", "#000000", "#8A8A90")
        case .paper:  .init("#F2EFE8", "#1A1A1A", "#F2EFE8", "#FFFFFF", "#1A1A1A", "#1A1A1A")
        }
    }

    private init(_ bg: String, _ tileA: String, _ digitA: String, _ tileB: String, _ digitB: String, _ sub: String) {
        self.bg = Color(hex: bg)
        self.tileA = Color(hex: tileA)
        self.digitA = Color(hex: digitA)
        self.tileB = Color(hex: tileB)
        self.digitB = Color(hex: digitB)
        self.sub = Color(hex: sub)
    }
}

// MARK: - Words

/// `bg` background · `strong` highlighted words and the top-left dot · `rest` linking words ·
/// `soft` date and digits.
struct WordsColors {
    let bg, strong, rest, soft: Color

    static func `for`(_ theme: ClockTheme) -> WordsColors {
        switch theme {
        case .fern:   .init("#5B9462", "#FFFFFF", "#0F1D12", "#0F1D12")
        case .clay:   .init("#E2774A", "#FFF4EC", "#2B1006", "#2B1006")
        case .sky:    .init("#9DC3EC", "#0C1C33", "#2D5C90", "#0C1C33")
        case .butter: .init("#F4D46A", "#2A2208", "#806310", "#2A2208")
        case .night:  .init("#000000", "#ECECEC", "#5C5C63", "#7A7A80")
        case .ink:    .init("#000000", "#FFFFFF", "#6A6A70", "#8A8A90")
        case .paper:  .init("#F2EFE8", "#1A1A1A", "#8C8780", "#1A1A1A")
        }
    }

    private init(_ bg: String, _ strong: String, _ rest: String, _ soft: String) {
        (self.bg, self.strong, self.rest, self.soft) = (Color(hex: bg), Color(hex: strong), Color(hex: rest), Color(hex: soft))
    }
}

// MARK: - Halves

/// `a`/`aInk` left panel and its digits and date · `b`/`bInk` right panel and its digits and AM/PM.
struct HalvesColors {
    let a, aInk, b, bInk: Color

    static func `for`(_ theme: ClockTheme) -> HalvesColors {
        switch theme {
        case .fern:   .init("#0F1D12", "#5B9462", "#5B9462", "#0F1D12")
        case .clay:   .init("#2B1006", "#E2774A", "#E2774A", "#2B1006")
        case .sky:    .init("#0C1C33", "#9DC3EC", "#9DC3EC", "#0C1C33")
        case .butter: .init("#2A2208", "#F4D46A", "#F4D46A", "#2A2208")
        case .night:  .init("#000000", "#E8E8E8", "#111113", "#FF9F0A")
        case .ink:    .init("#000000", "#F2F2F2", "#F2F2F2", "#000000")
        case .paper:  .init("#1A1A1A", "#F2EFE8", "#F2EFE8", "#E2552E")
        }
    }

    private init(_ a: String, _ aInk: String, _ b: String, _ bInk: String) {
        (self.a, self.aInk, self.b, self.bInk) = (Color(hex: a), Color(hex: aInk), Color(hex: b), Color(hex: bInk))
    }
}

// MARK: - Sweep

/// `ground` background and inner disc · `track` empty part of the ring · `fill` filled part ·
/// `ink` numeral, minutes and date · `dot` hour marker.
struct SweepColors {
    let ground, track, fill, ink, dot: Color

    static func `for`(_ theme: ClockTheme) -> SweepColors {
        switch theme {
        case .fern:   .init("#5B9462", "#4C7F53", "#F4EBD0", "#0F1D12", "#0F1D12")
        case .clay:   .init("#E2774A", "#CC6538", "#2B1006", "#2B1006", "#FFF4EC")
        case .sky:    .init("#9DC3EC", "#86AFDB", "#0C1C33", "#0C1C33", "#FF5A36")
        case .butter: .init("#F4D46A", "#E5C254", "#E2552E", "#2A2208", "#2A2208")
        case .night:  .init("#000000", "#1A1A1D", "#FF9F0A", "#E8E8E8", "#E8E8E8")
        case .ink:    .init("#000000", "#1E1E21", "#F2F2F2", "#F2F2F2", "#FF5A36")
        case .paper:  .init("#F2EFE8", "#E2DED5", "#1A1A1A", "#1A1A1A", "#E2552E")
        }
    }

    private init(_ ground: String, _ track: String, _ fill: String, _ ink: String, _ dot: String) {
        self.ground = Color(hex: ground)
        self.track = Color(hex: track)
        self.fill = Color(hex: fill)
        self.ink = Color(hex: ink)
        self.dot = Color(hex: dot)
    }
}

// MARK: - Dots

/// `ground` background · `ink` hour numeral, date and row labels · `lit` elapsed minutes ·
/// `track` minutes still to come · `now` the current minute.
struct DotsColors {
    let ground, ink, lit, track, now: Color

    static func `for`(_ theme: ClockTheme) -> DotsColors {
        switch theme {
        case .fern:   .init("#5B9462", "#0F1D12", "#0F1D12", "#4E8455", "#FFE7A8")
        case .clay:   .init("#E2774A", "#2B1006", "#2B1006", "#CF6A3E", "#FFF4EC")
        case .sky:    .init("#9DC3EC", "#0C1C33", "#0C1C33", "#88B1DC", "#FF5A36")
        case .butter: .init("#F4D46A", "#2A2208", "#2A2208", "#E6C556", "#E2552E")
        case .night:  .init("#000000", "#E8E8E8", "#9A9AA0", "#1C1C1F", "#FF9F0A")
        case .ink:    .init("#000000", "#F2F2F2", "#F2F2F2", "#1C1C1F", "#FF5A36")
        case .paper:  .init("#F2EFE8", "#1A1A1A", "#1A1A1A", "#E0DCD3", "#E2552E")
        }
    }

    private init(_ ground: String, _ ink: String, _ lit: String, _ track: String, _ now: String) {
        self.ground = Color(hex: ground)
        self.ink = Color(hex: ink)
        self.lit = Color(hex: lit)
        self.track = Color(hex: track)
        self.now = Color(hex: now)
    }
}

// MARK: - Swatches

extension ClockTheme {
    /// The two colours of this theme's swatch for `style`: the face's background and its most
    /// prominent foreground: the first two columns of the face's table, except Sweep, whose
    /// `track` is a near-match for its background, so its `fill` stands in. Nil for the classic
    /// faces, which are always black and white.
    func swatch(for style: ClockStyle) -> (background: Color, foreground: Color)? {
        switch style {
        case .digital, .analog: return nil
        case .numerals: let c = NumeralsColors.for(self); return (c.ground, c.ink)
        case .tiles: let c = TilesColors.for(self); return (c.bg, c.tileA)
        case .words: let c = WordsColors.for(self); return (c.bg, c.strong)
        case .halves: let c = HalvesColors.for(self); return (c.a, c.aInk)
        case .sweep: let c = SweepColors.for(self); return (c.ground, c.fill)
        case .dots: let c = DotsColors.for(self); return (c.ground, c.ink)
        }
    }
}
