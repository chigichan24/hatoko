import Foundation

/// Sliding-window rate limiter for LLM API calls.
///
/// Uses actor isolation for thread safety under Swift 6 strict concurrency.
actor RateLimiter {

    private let maxRequests: Int
    private let windowSeconds: TimeInterval
    private var timestamps: [Date] = []

    init(maxRequests: Int = 10, windowSeconds: TimeInterval = 60) {
        self.maxRequests = maxRequests
        self.windowSeconds = windowSeconds
    }

    /// Returns `true` if the request is allowed, `false` if rate-limited.
    func tryAcquire() -> Bool {
        let now = Date()
        let cutoff = now.addingTimeInterval(-windowSeconds)
        timestamps.removeAll { $0 < cutoff }
        guard timestamps.count < maxRequests else {
            return false
        }
        timestamps.append(now)
        return true
    }
}
