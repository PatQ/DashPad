// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// IdlePhotoPicker.swift - choosing idle screen photos: the system photo picker, the import, and the
// thumbnail grid shared by Settings and onboarding.

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Grid

/// The chosen photos as thumbnails, with an add tile at the end. Select switches to a selection
/// mode for removing one or more photos. A per-photo context menu can't do this: inside a Form row
/// it lifts the whole grid, and the row only keeps the first photo's menu.
struct IdlePhotoGrid: View {
    @EnvironmentObject private var settings: AppSettings
    var thumbnailSize: CGFloat = 84

    @State private var showingPicker = false
    @State private var isImporting = false
    @State private var isSelecting = false
    @State private var selection: Set<IdlePhoto> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !settings.idlePhotos.isEmpty {
                header
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: thumbnailSize, maximum: thumbnailSize * 1.5), spacing: 8)],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(settings.idlePhotos) { photo in
                    if isSelecting {
                        Button { toggleSelection(photo) } label: {
                            IdlePhotoThumbnail(photo: photo, isSelected: selection.contains(photo))
                        }
                        .buttonStyle(.plain)
                    } else {
                        IdlePhotoThumbnail(photo: photo)
                    }
                }

                if isImporting {
                    tile { ProgressView() }
                        .accessibilityLabel("Adding photos")
                } else if !isSelecting, settings.remainingIdlePhotoSlots > 0 {
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
        .onChangeCompat(of: settings.idlePhotos) { photos in
            // Photos can also go via Remove All Photos; drop them from the selection too.
            selection.formIntersection(photos)
            if photos.isEmpty { isSelecting = false }
        }
    }

    /// Borderless buttons, because a plain Button in a Form row makes the whole row its tap target.
    private var header: some View {
        HStack {
            Text(headerTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if isSelecting {
                Button("Remove", role: .destructive) {
                    let removed = selection
                    withAnimation {
                        settings.removeIdlePhotos(removed)
                        selection = []
                        isSelecting = false
                    }
                }
                .disabled(selection.isEmpty)
                .padding(.trailing, 12)
            }
            Button(isSelecting ? "Done" : "Select") {
                withAnimation {
                    isSelecting.toggle()
                    selection = []
                }
            }
        }
        .buttonStyle(.borderless)
    }

    private var headerTitle: String {
        if isSelecting {
            return selection.isEmpty ? "Select Photos" : "\(selection.count) Selected"
        }
        let count = settings.idlePhotos.count
        return count == 1 ? "1 Photo" : "\(count) Photos"
    }

    private func toggleSelection(_ photo: IdlePhoto) {
        if selection.contains(photo) {
            selection.remove(photo)
        } else {
            selection.insert(photo)
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
    /// nil outside selection mode, so no checkmark is drawn.
    var isSelected: Bool?
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
            .overlay(alignment: .bottomTrailing) {
                if let isSelected {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, isSelected ? Color.accentColor : .clear)
                        .shadow(color: .black.opacity(0.35), radius: 2)
                        .padding(6)
                }
            }
            .opacity(isSelected == false ? 0.75 : 1)
            .accessibilityElement()
            .accessibilityLabel("Photo")
            .accessibilityAddTraits(isSelected == true ? .isSelected : [])
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
