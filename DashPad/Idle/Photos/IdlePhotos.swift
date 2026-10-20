// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// IdlePhotos.swift - the Photos idle screen's settings: which photos, in what order, and how they play.

import Foundation

/// One photo copied into DashPad. Only the ID is persisted in settings; the image itself is a
/// file owned by `IdlePhotoStore`.
nonisolated struct IdlePhoto: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
}

struct PhotoOptions: Codable, Equatable {
    /// Crop to fill the screen. Off fits the whole photo, over a blurred copy of itself.
    var fillScreen = true
    var showClock = true
    /// Only used with two or more photos.
    var interval: PhotoInterval = .oneMinute
    var shuffle = false

    init() {}

    /// Every key is optional, so options added later decode from an older save with their
    /// defaults rather than failing and resetting everything.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PhotoOptions()
        fillScreen = try c.decodeIfPresent(Bool.self, forKey: .fillScreen) ?? d.fillScreen
        showClock = try c.decodeIfPresent(Bool.self, forKey: .showClock) ?? d.showClock
        interval = (try? c.decodeIfPresent(PhotoInterval.self, forKey: .interval)) ?? d.interval
        shuffle = try c.decodeIfPresent(Bool.self, forKey: .shuffle) ?? d.shuffle
    }
}

enum PhotoInterval: Int, CaseIterable, Codable {
    case tenSeconds = 10
    case thirtySeconds = 30
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case oneHour = 3600

    var seconds: TimeInterval { TimeInterval(rawValue) }

    var displayName: String {
        switch self {
        case .tenSeconds: "10 seconds"
        case .thirtySeconds: "30 seconds"
        case .oneMinute: "1 minute"
        case .fiveMinutes: "5 minutes"
        case .fifteenMinutes: "15 minutes"
        case .oneHour: "1 hour"
        }
    }
}

extension AppSettings {
    /// Enough for a varied slideshow while keeping the copies to roughly 50 MB.
    static let maxIdlePhotos = 50

    var remainingIdlePhotoSlots: Int { max(0, Self.maxIdlePhotos - idlePhotos.count) }

    /// Appends newly imported photos, in the order they were picked. Any past the limit are
    /// deleted rather than left as orphaned files.
    func addIdlePhotos(_ photos: [IdlePhoto]) {
        let room = remainingIdlePhotoSlots
        idlePhotos += photos.prefix(room)
        photos.dropFirst(room).forEach(IdlePhotoStore.delete)
    }

    func removeIdlePhoto(_ photo: IdlePhoto) {
        idlePhotos.removeAll { $0 == photo }
        IdlePhotoStore.delete(photo)
    }

    func removeAllIdlePhotos() {
        let removed = idlePhotos
        idlePhotos = []
        removed.forEach(IdlePhotoStore.delete)
    }
}
