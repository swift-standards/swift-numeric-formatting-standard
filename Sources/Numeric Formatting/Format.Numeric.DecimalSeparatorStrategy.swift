// Format.Numeric.DecimalSeparatorStrategy.swift
// Style extension for decimal separator configuration.
// The DecimalSeparatorStrategy enum is defined in swift-standards/Sources/Formatting/Format.Numeric.DecimalSeparatorStrategy.swift

public import Formatting

// MARK: - Style Extension

extension Format.Numeric.Style {
    /// Configure decimal separator display strategy
    ///
    /// ## Example
    ///
    /// ```swift
    /// 42.formatted(.number.decimalSeparator(strategy: .always))    // "42."
    /// 42.5.formatted(.number.decimalSeparator(strategy: .always))  // "42.5"
    /// ```
    public func decimalSeparator(strategy: Format.Numeric.DecimalSeparatorStrategy) -> Self {
        var copy = self
        copy.decimalSeparatorStrategy = strategy
        return copy
    }
}
