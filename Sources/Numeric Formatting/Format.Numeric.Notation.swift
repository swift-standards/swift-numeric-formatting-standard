// Format.Numeric.Notation.swift
// Style extension for notation configuration.
// The Notation enum is defined in swift-standards/Sources/Formatting/Format.Numeric.Notation.swift

public import Formatting

// MARK: - Style Extension

extension Format.Numeric.Style {
    /// Configure notation style
    ///
    /// ## Examples
    ///
    /// ```swift
    /// 1000.formatted(.number.notation(.compactName))     // "1K"
    /// 1234.formatted(.number.notation(.scientific))      // "1.234E3"
    /// ```
    public func notation(_ notation: Format.Numeric.Notation) -> Self {
        var copy = self
        copy.notation = notation
        return copy
    }
}
