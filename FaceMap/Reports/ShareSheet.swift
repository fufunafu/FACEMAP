import SwiftUI
import UIKit

/// Bridges `UIActivityViewController` into SwiftUI. Used to share the generated
/// treatment-plan PDF — AirDrop, Files, Print, etc. No data leaves the device
/// unless the practitioner picks an outbound share target.
///
/// `onComplete` fires when the activity controller finishes (shared OR cancelled) —
/// callers use it to delete the transient export file.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in
            onComplete?()
        }
        return vc
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

/// A transient PDF item written to a unique temp subdirectory and shared via the
/// share sheet. Exports are written with complete file protection, filenames are
/// sanitized to `[A-Za-z0-9._-]`, and callers must `cleanup()` once the share
/// sheet completes or is dismissed. Leftovers from interrupted sessions are swept
/// on first use.
struct PDFShareItem: Identifiable {
    let id = UUID()
    let url: URL

    enum WriteError: LocalizedError {
        case underlying(Error)

        var errorDescription: String? {
            switch self {
            case .underlying(let error):
                return "Could not write the PDF for sharing: \(error.localizedDescription)"
            }
        }
    }

    /// Directory under tmp that holds all transient exports (one subfolder per item).
    private static let exportsDirectoryName = "FaceMapExports"
    private static var didSweepLeftovers = false

    /// Writes the PDF and surfaces any failure to the caller.
    static func create(_ data: Data, suggestedName: String) throws -> PDFShareItem {
        sweepLeftoversIfNeeded()
        let fm = FileManager.default
        let dir = fm.temporaryDirectory
            .appendingPathComponent(exportsDirectoryName, isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = dir.appendingPathComponent("\(sanitize(suggestedName)).pdf")
        do {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch {
            throw WriteError.underlying(error)
        }
        return PDFShareItem(url: url)
    }

    /// Optional-returning convenience kept for existing call sites. Prefer
    /// `create(_:suggestedName:)`, which surfaces the failure.
    static func write(_ data: Data, suggestedName: String) -> PDFShareItem? {
        try? create(data, suggestedName: suggestedName)
    }

    /// Deletes this export (and its unique containing folder). Call when the share
    /// sheet completes or is dismissed.
    func cleanup() {
        let fm = FileManager.default
        let parent = url.deletingLastPathComponent()
        if parent.lastPathComponent != Self.exportsDirectoryName {
            try? fm.removeItem(at: parent)
        } else {
            try? fm.removeItem(at: url)
        }
    }

    /// Allowlist filename sanitizer: anything outside `[A-Za-z0-9._-]` becomes "_".
    static func sanitize(_ name: String) -> String {
        let allowed = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-")
        let mapped = String(name.map { allowed.contains($0) ? $0 : "_" })
        let trimmed = mapped.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return trimmed.isEmpty ? "FaceMap_Export" : trimmed
    }

    /// Removes exports orphaned by interrupted sessions: the whole exports folder
    /// plus any legacy `FaceMap_*.pdf` written to the tmp root by older builds.
    private static func sweepLeftoversIfNeeded() {
        guard !didSweepLeftovers else { return }
        didSweepLeftovers = true
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory
        try? fm.removeItem(at: tmp.appendingPathComponent(exportsDirectoryName, isDirectory: true))
        if let entries = try? fm.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil) {
            for entry in entries
            where entry.lastPathComponent.hasPrefix("FaceMap_")
                && entry.pathExtension.lowercased() == "pdf" {
                try? fm.removeItem(at: entry)
            }
        }
    }
}
