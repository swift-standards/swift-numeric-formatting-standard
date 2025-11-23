//
//  File.swift
//  swift-numeric-formatting-standard
//
//  Created by Coen ten Thije Boonkkamp on 23/11/2025.
//

public import Formatting

extension BinaryInteger {
    /// Formats this integer value using the numeric format style.
    ///
    /// - Parameter style: The format style to use
    /// - Returns: A formatted string representation
    ///
    /// ## Example
    ///
    /// ```swift
    /// 42.formatted(.number)  // "42"
    /// 1234567.formatted(.number.grouping(.always))  // "1,234,567"
    /// ```
    public func formatted(_ style: Format.Numeric.Style) -> String {
        style.format(self)
    }
}
