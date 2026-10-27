// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// WhatsNew.swift - Points users who updated at features that arrived after they started using
// DashPad: a "New" badge in the Settings sidebar and a TipKit tip in the pane it leads to.
// Nothing here is shown to a fresh install - onboarding has just walked them through everything.

import SwiftUI
import TipKit

enum WhatsNew {
    /// The release whose idle screens - the themed clock faces and Photos - are flagged as new.
    static let idleScreensRelease = "1.5"

    /// Owned by `SettingsView`'s `@AppStorage`: set once the user picks a clock face or Photos.
    static let idleScreensTriedKey = "whatsNewIdleScreensTried"

    /// How long the sidebar badge stays up after the update, unless the user tries the new
    /// screens first. Opening the pane alone doesn't clear it - a glance isn't a try.
    private static let badgeDuration: TimeInterval = 14 * 24 * 60 * 60

    private static let firstVersionKey = "firstLaunchedVersion"
    private static let idleScreensUpdateDateKey = "whatsNewIdleScreensUpdateDate"
    /// Stands in for every release before this key existed, so it compares below all of them.
    private static let untrackedVersion = "0"
    /// Owned by `ContentView`'s `@AppStorage`; read here only to tell an update from a fresh install.
    private static let onboardingCompletedKey = "hasCompletedOnboarding"

    private static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? untrackedVersion
    }

    /// Records the version DashPad was first launched on, and hands TipKit whether the idle
    /// screens tip applies. Call once at launch, before any view reads `isUpdate(since:)`.
    static func configure() {
        let ud = UserDefaults.standard
        #if DEBUG
        // TipKit only lets its datastore be reset before `Tips.configure()`, hence the relaunch.
        let resetPending = ud.bool(forKey: resetPendingKey)
        ud.removeObject(forKey: resetPendingKey)
        if resetPending, #available(iOS 17.0, *) {
            try? Tips.resetDatastore()
        }
        #endif

        if ud.string(forKey: firstVersionKey) == nil {
            // No record yet: either a fresh install, or an install from before this key was
            // written. Completed onboarding means the latter - someone who has used DashPad before.
            let updated = ud.bool(forKey: onboardingCompletedKey)
            ud.set(updated ? untrackedVersion : currentVersion, forKey: firstVersionKey)
        }

        // The first launch on the new release starts the badge's clock.
        if isUpdate(since: idleScreensRelease), ud.object(forKey: idleScreensUpdateDateKey) == nil {
            ud.set(Date(), forKey: idleScreensUpdateDateKey)
        }

        if #available(iOS 17.0, *) {
            try? Tips.configure()
            // After `configure()`: parameters live in TipKit's datastore, so one set before it
            // exists - or before a reset wipes it - is lost and the tip never becomes eligible.
            IdleScreensTip.isEligible = isUpdate(since: idleScreensRelease)
        }
    }

    /// Whether this install predates `release`, i.e. the user got its features by updating.
    static func isUpdate(since release: String) -> Bool {
        let first = UserDefaults.standard.string(forKey: firstVersionKey) ?? currentVersion
        return first.compare(release, options: .numeric) == .orderedAscending
    }

    /// Whether the idle screens are still within their badge window after the update.
    static var idleScreensBadgeIsCurrent: Bool {
        guard let updated = UserDefaults.standard.object(forKey: idleScreensUpdateDateKey) as? Date else { return false }
        return Date().timeIntervalSince(updated) < badgeDuration
    }

    #if DEBUG
    private static let resetPendingKey = "whatsNewResetPending"

    /// Makes this install look freshly updated from before the newest release, from the next
    /// launch on - TipKit's datastore can only be reset before `Tips.configure()`.
    static func resetForTesting() {
        let ud = UserDefaults.standard
        ud.set(untrackedVersion, forKey: firstVersionKey)
        ud.set(Date(), forKey: idleScreensUpdateDateKey)
        ud.set(false, forKey: idleScreensTriedKey)
        ud.set(true, forKey: resetPendingKey)
    }
    #endif
}

// MARK: - Tips

/// Shown at the top of Settings → Idle Screen. Goes away for good once dismissed, or once the
/// user picks a clock face or switches to Photos - either way they have found what it points at.
@available(iOS 17.0, *)
struct IdleScreensTip: Tip {
    @Parameter static var isEligible: Bool = false

    var title: Text { Text("New Idle Screens") }

    var message: Text? {
        Text("Choose from six new clock faces, each with its own colour themes, or switch to Photos to show your own pictures while the dashboard is idle.")
    }

    var image: Image? { Image(systemName: "sparkles") }

    var rules: [Rule] {
        #Rule(Self.$isEligible) { $0 }
    }
}
