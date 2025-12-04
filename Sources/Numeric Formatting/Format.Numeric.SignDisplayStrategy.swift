// Format.Numeric.SignDisplayStrategy.swift
// Style extension for sign display configuration.
// The SignDisplayStrategy enum is defined in swift-standards/Sources/Formatting/Format.Numeric.SignDisplayStrategy.swift

public import Formatting

// MARK: - Style Extension

extension Format.Numeric.Style {
    /// Configure sign display
    ///
    /// ## Examples
    ///
    /// ```swift
    /// 42.formatted(.number.sign(strategy: .always()))                      // "+42"
    /// (-42).formatted(.number.sign(strategy: .always()))                   // "-42"
    /// 0.formatted(.number.sign(strategy: .always(includingZero: true)))    // "+0"
    /// ```
    public func sign(strategy: Format.Numeric.SignDisplayStrategy) -> Self {
        var copy = self
        copy.signDisplayStrategy = strategy
        return copy
    }
}
