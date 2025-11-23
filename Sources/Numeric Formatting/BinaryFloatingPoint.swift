//
//  File.swift
//  swift-numeric-formatting-standard
//
//  Created by Coen ten Thije Boonkkamp on 23/11/2025.
//

public import Formatting

extension BinaryFloatingPoint {
    /// Formats this floating-point value using the numeric format style.
    ///
    /// - Parameter style: The format style to use
    /// - Returns: A formatted string representation
    ///
    /// ## Example
    ///
    /// ```swift
    /// 3.14159.formatted(.number)  // "3.14159"
    /// 100.0.formatted(.number)    // "100"
    /// ```
    public func formatted(_ style: Format.Numeric.Style) -> String {
        style.format(self)
    }
}
