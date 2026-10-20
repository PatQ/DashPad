// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// IdlePhotoPicker.swift - choosing idle screen photos: the system photo picker, the import, and the
// thumbnail grid shared by Settings and onboarding.

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Grid

/// The chosen photos as thumbnails, with an add tile at the end. Long-press a photo to remove it.
struct IdlePhotoGrid: View {
    @EnvironmentObject private var settings: AppSettings
    var thumbnailSize: CGFloat = 84

    @State private var showingPicker = false
    @State private var isImporting = false

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: thumbnailSize, maximum: thumbnailSize * 1.5), spacing: 8)],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(settings.idlePhotos) { photo in
                IdlePhotoThumbnail(photo: photo)
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation { settings.removeIdlePhoto(photo) }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
            }

            if isImporting {
                tile { ProgressView() }
                    .accessibilityLabel("Adding photos")
            } else if settings.remainingIdlePhotoSlots > 0 {
                Button { showingPicker = true } label: {
                    tile {
                        VStack(spacing: 4) {
                            Image(systemName: "plus").font(.title3.weight(.medium))
                            Text("Add").font(.caption.weight(.medium))
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add Photos")
            }
        }
        .sheet(isPresented: $showingPicker) {
            IdlePhotoPicker(limit: settings.remainingIdlePhotoSlots) { providers in
                Task { @MainActor in
                    isImporting = true
                    let photos = await IdlePhotoImporter.importPhotos(from: providers)
                    withAnimation { settings.addIdlePhotos(photos) }
                    isImporting = false
                }
            }
            .ignoresSafeArea()
        }
    }

    private func tile<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.secondary.opacity(0.12))
            .aspectRatio(1, contentMode: .fit)
            .overlay(content())
    }
}

private struct IdlePhotoThumbnail: View {
    let photo: IdlePhoto
    @State private var image: UIImage?

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.secondary.opacity(0.12))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityElement()
            .accessibilityLabel("Photo")
            .task(id: photo) {
                let photo = photo
                image = await Task.detached(priority: .userInitiated) {
                    IdlePhotoStore.thumbnail(for: photo)
                }.value
            }
    }
}

// MARK: - System picker

/// The system photo picker. It runs outside the app and hands back only what was picked, so
/// DashPad needs no photo library permission and never sees the rest of the library.
struct IdlePhotoPicker: UIViewControllerRepresentable {
    let limit: Int
    let onPick: ([NSItemProvider]) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images            // Live Photos come through as stills; no videos
        configuration.selectionLimit = limit
        configuration.selection = .ordered        // numbered, so the slideshow plays in pick order
        configuration.preferredAssetRepresentationMode = .current   // we re-encode anyway
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: PHPickerViewController, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: IdlePhotoPicker

        init(parent: IdlePhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            if !results.isEmpty {
                parent.onPick(results.map(\.itemProvider))
            }
        }
    }
}

// MARK: - Import

nonisolated enum IdlePhotoImporter {
    /// Imports one at a time, in pick order: decoding several large originals at once could
    /// take hundreds of megabytes.
    static func importPhotos(from providers: [NSItemProvider]) async -> [IdlePhoto] {
        var photos: [IdlePhoto] = []
        for provider in providers {
            if let photo = await importPhoto(from: provider) {
                photos.append(photo)
            }
        }
        return photos
    }

    private static func importPhoto(from provider: NSItemProvider) async -> IdlePhoto? {
        let type = UTType.image.identifier
        guard provider.hasItemConformingToTypeIdentifier(type) else { return nil }
        return await withCheckedContinuation { continuation in
            // The file only exists until this handler returns, so the copy is made right here,
            // on the provider's background queue.
            provider.loadFileRepresentation(forTypeIdentifier: type) { url, _ in
                continuation.resume(returning: url.flatMap(IdlePhotoStore.importImage(at:)))
            }
        }
    }
}
