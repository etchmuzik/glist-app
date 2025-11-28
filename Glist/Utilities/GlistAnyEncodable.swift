import Foundation

/// A type-erased box for values that are both Encodable and Sendable.
/// The conformance to Encodable is explicitly nonisolated so it can be used
/// across concurrency domains where `Sendable` is required by generic APIs.
public struct GlistAnyEncodable: Sendable, Encodable {
    private let _encode: @Sendable (Encoder) throws -> Void

    public init<T: Encodable & Sendable>(_ value: T) {
        self._encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    // Mark the requirement nonisolated to prevent isolated conformance diagnostics
    public nonisolated func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
