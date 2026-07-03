import Foundation

/// Phase 5 backend client. Stub for v0.1 — exists so wiring the real client later doesn't
/// require restructuring call sites.
struct APIClient {
    let baseURL: URL
    let session: URLSession
    /// JWT obtained via Sign in with Apple → backend exchange.
    let token: String?

    init(baseURL: URL, session: URLSession = .shared, token: String? = nil) {
        self.baseURL = baseURL
        self.session = session
        self.token = token
    }
}
