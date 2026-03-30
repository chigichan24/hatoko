import Foundation
import Testing

@testable import Hatoko

@Suite
struct RateLimiterTests {

    @Test
    func allowsRequestsWithinLimit() async {
        let limiter = RateLimiter(maxRequests: 3, windowSeconds: 60)
        #expect(await limiter.tryAcquire())
        #expect(await limiter.tryAcquire())
        #expect(await limiter.tryAcquire())
    }

    @Test
    func blocksRequestsOverLimit() async {
        let limiter = RateLimiter(maxRequests: 2, windowSeconds: 60)
        #expect(await limiter.tryAcquire())
        #expect(await limiter.tryAcquire())
        #expect(await limiter.tryAcquire() == false)
    }

    @Test
    func allowsRequestsAfterWindowExpires() async throws {
        let limiter = RateLimiter(maxRequests: 1, windowSeconds: 0.1)
        #expect(await limiter.tryAcquire())
        #expect(await limiter.tryAcquire() == false)
        try await Task.sleep(for: .milliseconds(150))
        #expect(await limiter.tryAcquire())
    }
}
