// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// ClockCanvas.swift - the 1180×820 design space every clock face is drawn in, scaled to fit any
// screen, preview or thumbnail, with the face's background filling the rest.

import SwiftUI

/// Faces are designed on a fixed iPad-landscape canvas. Rather than shrinking a full-size
/// layout with `scaleEffect`, which renders text at design size and resamples it (soft on the
/// larger iPads, where the scale goes above 1), the canvas hands the face its scale and the face
/// multiplies every dimension by it, so glyphs are drawn at the size they appear on screen.
struct ClockCanvas<Background: View, Content: View>: View {
    /// Set on the idle screen only: the date that picks this 10-minute slot's burn-in shift.
    var burnInDate: Date? = nil
    let accessibilityLabel: String
    let background: Background
    let content: (CGFloat) -> Content

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / ClockDesign.width, geo.size.height / ClockDesign.height)
            let shift = burnInDate.map(Self.burnInShift) ?? .zero
            ZStack {
                // Overscanned so the edges stay covered when the burn-in shift moves everything.
                background.padding(-12 * scale)
                content(scale)
                    .designFrame(scale: scale)
                    .clipped()
            }
            .offset(x: shift.width * scale, y: shift.height * scale)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    /// Up to ±6 design points in each direction, changing every 10 minutes. Derived from the
    /// time slot so it is stable between redraws, and jumps rather than animates.
    static func burnInShift(at date: Date) -> CGSize {
        let slot = UInt64(max(0, date.timeIntervalSinceReferenceDate / 600))
        // SplitMix64: spreads consecutive slots into unrelated offsets.
        var x = slot &+ 0x9E37_79B9_7F4A_7C15
        x = (x ^ (x >> 30)) &* 0xBF58_476D_1CE4_E5B9
        x = (x ^ (x >> 27)) &* 0x94D0_49BB_1331_11EB
        x ^= x >> 31
        return CGSize(width: CGFloat(Int(x % 13) - 6), height: CGFloat(Int((x >> 32) % 13) - 6))
    }
}

/// The design space: iPad landscape, origin top left. Mockup pixels are design points.
enum ClockDesign {
    static let width: CGFloat = 1180
    static let height: CGFloat = 820
    static let aspectRatio = width / height
}

extension View {
    /// Sizes the view to the whole design canvas at `scale`.
    func designFrame(scale s: CGFloat) -> some View {
        frame(width: ClockDesign.width * s, height: ClockDesign.height * s)
    }

    /// Centres the view at a point given in design coordinates.
    func designPosition(_ x: CGFloat, _ y: CGFloat, scale s: CGFloat) -> some View {
        position(x: x * s, y: y * s)
    }
}
