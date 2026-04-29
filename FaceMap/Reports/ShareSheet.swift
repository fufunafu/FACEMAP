import SwiftUI
import UIKit

/// Bridges `UIActivityViewController` into SwiftUI. Used to share the generated
/// treatment-plan PDF — AirDrop, Files, Print, etc. No data leaves the device
/// unless the practitioner picks an outbound share target.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

/// A transient PDF item written to the temp directory and shared via the share sheet.
struct PDFShareItem: Identifiable {
    let id = UUID()
    let url: URL

    static func write(_ data: Data, suggestedName: String) -> PDFShareItem? {
        let safe = suggestedName.replacingOccurrences(of: "/", with: "_")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safe).pdf")
        do {
            try data.write(to: url, options: [.atomic])
            return PDFShareItem(url: url)
        } catch {
            return nil
        }
    }
}
