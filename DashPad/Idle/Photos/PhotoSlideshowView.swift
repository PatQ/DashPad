// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// PhotoSlideshowView.swift - the Photos idle screen: one photo, or several crossfading in a loop,
// drifting slowly against burn-in, with an optional clock in the corner.

import SwiftUI
import UIKit

struct PhotoSlideshowView: View {
    let photos: [IdlePhoto]
    let options: PhotoOptions

    @State private var slide: PreparedSlide?

    /// One photo just stays up; two or more loop. The count decides, not a setting.
    private var isCarousel: Bool { photos.count > 1 }

    /// Remembered across idle periods (not across launches), so each one picks up where the
    /// last left off instead of always starting from the first photo.
    @MainActor private static var lastShown: IdlePhoto?

    var body: some View {
        ZStack {
            SlideshowRepresentable(
                slide: slide,
                fillsScreen: options.fillScreen,
                // A carousel photo drifts one way for as long as it's up; a lone photo drifts
                // back and forth, a full sweep every 90 seconds.
                motion: isCarousel
                    ? .once(duration: options.interval.seconds + SlideshowUIView.fadeDuration)
                    : .backAndForth(duration: 90)
            )
            if options.showClock {
                PhotoClockOverlay()
            }
        }
        .ignoresSafeArea()
        .task(id: Playback(photos: photos, options: options)) { await play() }
    }

    private struct Playback: Equatable {
        let photos: [IdlePhoto]
        let options: PhotoOptions
    }

    @MainActor
    private func play() async {
        var order = options.shuffle ? photos.shuffled() : photos
        var index = order.firstIndex { $0 == Self.lastShown }.map { $0 + 1 } ?? 0
        var failures = 0

        while !Task.isCancelled, !order.isEmpty {
            if index >= order.count {
                index = 0
                if options.shuffle {
                    order.shuffle()
                    // Don't show the same photo twice in a row across the reshuffle.
                    if order.count > 1, order[0] == Self.lastShown { order.swapAt(0, order.count - 1) }
                }
            }
            let photo = order[index]
            let withBackdrop = !options.fillScreen
            // Decoding a screen-sized photo takes long enough to drop frames on the main thread.
            let prepared = await Task.detached(priority: .utility) {
                IdlePhotoStore.prepareSlide(photo, withBackdrop: withBackdrop)
            }.value
            guard !Task.isCancelled else { return }

            guard let prepared else {
                // A missing or unreadable file: skip it, unless none of them can be read.
                failures += 1
                if failures >= order.count { return }
                index += 1
                continue
            }
            failures = 0
            slide = prepared
            Self.lastShown = photo

            guard isCarousel else { return }
            try? await Task.sleep(nanoseconds: UInt64(options.interval.seconds * 1_000_000_000))
            index += 1
        }
    }
}

// MARK: - UIKit slideshow

/// How a photo drifts while it's on screen.
enum SlideMotion: Equatable {
    case once(duration: TimeInterval)
    case backAndForth(duration: TimeInterval)
}

private struct SlideshowRepresentable: UIViewRepresentable {
    let slide: PreparedSlide?
    let fillsScreen: Bool
    let motion: SlideMotion

    func makeUIView(context: Context) -> SlideshowUIView { SlideshowUIView() }

    func updateUIView(_ view: SlideshowUIView, context: Context) {
        if let slide {
            view.show(slide, fillsScreen: fillsScreen, motion: motion)
        }
    }
}

/// The crossfade and the slow zoom and pan are UIKit animations rather than SwiftUI ones.
/// Core Animation runs them in the render server, so the app sits idle between photo changes;
/// a SwiftUI animation would redraw in the app on every frame, all day.
final class SlideshowUIView: UIView {
    static let fadeDuration: TimeInterval = 1.5

    private var current: SlideContentView?
    private var shownToken: UUID?
    private var motion: SlideMotion = .backAndForth(duration: 90)

    init() {
        super.init(frame: .zero)
        backgroundColor = .black
        clipsToBounds = true
        isUserInteractionEnabled = false
        // Animations are dropped while the app is in the background; start the drift again.
        NotificationCenter.default.addObserver(
            self, selector: #selector(restartMotion),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func show(_ slide: PreparedSlide, fillsScreen: Bool, motion: SlideMotion) {
        guard slide.token != shownToken else { return }
        shownToken = slide.token
        self.motion = motion

        let incoming = SlideContentView(slide: slide, fillsScreen: fillsScreen)
        incoming.frame = bounds
        incoming.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(incoming)
        incoming.startMotion(motion)

        let outgoing = current
        current = incoming
        guard let outgoing else { return }

        incoming.alpha = 0
        UIView.animate(withDuration: Self.fadeDuration, delay: 0, options: [.curveEaseInOut]) {
            incoming.alpha = 1
        } completion: { _ in
            outgoing.removeFromSuperview()
        }
    }

    @objc private func restartMotion() {
        current?.startMotion(motion)
    }
}

/// One photo: filling the screen, or fitted over a blurred copy of itself.
private final class SlideContentView: UIView {
    private let photoView = UIImageView()
    private let fillsScreen: Bool
    private let seed: Int
    private var pendingMotion: SlideMotion?

    init(slide: PreparedSlide, fillsScreen: Bool) {
        self.fillsScreen = fillsScreen
        seed = slide.motionSeed
        super.init(frame: .zero)
        clipsToBounds = true
        backgroundColor = .black

        if !fillsScreen, let backdrop = slide.backdrop {
            let backdropView = UIImageView(image: backdrop)
            backdropView.contentMode = .scaleAspectFill
            backdropView.frame = bounds
            backdropView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(backdropView)
        }

        photoView.image = slide.image
        photoView.contentMode = fillsScreen ? .scaleAspectFill : .scaleAspectFit
        photoView.frame = bounds
        photoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(photoView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Deferred until the view has a size, because the pan distance depends on it.
    func startMotion(_ motion: SlideMotion) {
        pendingMotion = motion
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let motion = pendingMotion, !bounds.isEmpty {
            pendingMotion = nil
            run(motion)
        }
    }

    /// A slow zoom with a slight pan, in a direction picked by the seed. Filled photos stay zoomed
    /// in past 1.0 throughout, so the pan never uncovers an edge; fitted ones move less, over
    /// their backdrop.
    private func run(_ motion: SlideMotion) {
        let zooms: (CGFloat, CGFloat) = fillsScreen ? (1.06, 1.12) : (1.0, 1.04)
        let (startScale, endScale) = seed.isMultiple(of: 2) ? zooms : (zooms.1, zooms.0)
        let angle = Double(seed % 8) * .pi / 4
        let travel = min(bounds.width, bounds.height) * (fillsScreen ? 0.02 : 0.01)
        let dx = CGFloat(cos(angle)) * travel / 2
        let dy = CGFloat(sin(angle)) * travel / 2

        photoView.layer.removeAllAnimations()
        photoView.transform = CGAffineTransform(translationX: -dx, y: -dy).scaledBy(x: startScale, y: startScale)

        let duration: TimeInterval
        let options: UIView.AnimationOptions
        switch motion {
        case .once(let d):
            duration = d
            options = [.curveLinear]
        case .backAndForth(let d):
            duration = d / 2
            options = [.curveEaseInOut, .repeat, .autoreverse]
        }
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.photoView.transform = CGAffineTransform(translationX: dx, y: dy).scaledBy(x: endScale, y: endScale)
        }
    }
}

// MARK: - Clock overlay

/// A small time and date in the bottom-left corner, over a soft shade so it reads on any photo.
private struct PhotoClockOverlay: View {
    var body: some View {
        TimelineView(.everyMinute) { context in
            // Static text over a photo for hours is a burn-in risk too; it moves with the clocks.
            let shift = ClockDesign.burnInShift(at: context.date)
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .bottom, endPoint: .center)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.date, format: .dateTime.hour().minute())
                        .font(.system(size: 76, weight: .light))
                        .monospacedDigit()
                    Text(context.date, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.title3.weight(.medium))
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 10, y: 2)
                .padding(.leading, 48)
                .padding(.bottom, 44)
                .offset(x: shift.width * 2, y: shift.height * 2)
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }
}
