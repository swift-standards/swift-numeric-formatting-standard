//
//  Format.Numeric.Style.swift
//  swift-numeric-formatting-standard
//
//  Fluent API for numeric formatting
//

public import Formatting
import ISO_9899

extension Format.Numeric {
    /// Fluent numeric format style with builder pattern
    ///
    /// Provides a chainable API for configuring numeric formatting,
    /// matching Foundation's FormatStyle pattern.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// 42.formatted(.number)  // "42"
    /// 3.14159.formatted(.number.precision(.fractionLength(2)))  // "3.14"
    /// 1234567.formatted(.number.grouping(.always))  // "1,234,567"
    /// ```
    public struct Style: Sendable {
        internal var maximumFractionDigits: Int?
        internal var minimumFractionDigits: Int?
        internal var groupingSeparator: String?
        internal var decimalSeparator: String
        internal var notation: Format.Numeric.Notation
        internal var signDisplayStrategy: Format.Numeric.SignDisplayStrategy
        internal var roundingRule: FloatingPointRoundingRule?
        internal var roundingIncrement: Double?
        internal var decimalSeparatorStrategy: Format.Numeric.DecimalSeparatorStrategy
        internal var scale: Double
        internal var significantDigits: (min: Int?, max: Int?)?
        internal var integerLength: (min: Int?, max: Int?)?

        internal init(
            maximumFractionDigits: Int? = nil,
            minimumFractionDigits: Int? = nil,
            groupingSeparator: String? = nil,
            decimalSeparator: String = ".",
            notation: Format.Numeric.Notation = .automatic,
            signDisplayStrategy: Format.Numeric.SignDisplayStrategy = .automatic,
            roundingRule: FloatingPointRoundingRule? = nil,
            roundingIncrement: Double? = nil,
            decimalSeparatorStrategy: Format.Numeric.DecimalSeparatorStrategy = .automatic,
            scale: Double = 1.0,
            significantDigits: (min: Int?, max: Int?)? = nil,
            integerLength: (min: Int?, max: Int?)? = nil
        ) {
            self.maximumFractionDigits = maximumFractionDigits
            self.minimumFractionDigits = minimumFractionDigits
            self.groupingSeparator = groupingSeparator
            self.decimalSeparator = decimalSeparator
            self.notation = notation
            self.signDisplayStrategy = signDisplayStrategy
            self.roundingRule = roundingRule
            self.roundingIncrement = roundingIncrement
            self.decimalSeparatorStrategy = decimalSeparatorStrategy
            self.scale = scale
            self.significantDigits = significantDigits
            self.integerLength = integerLength
        }
    }
}

// MARK: - Static Entry Point

extension Format.Numeric.Style {
    /// Default numeric style
    ///
    /// Entry point for fluent numeric formatting.
    ///
    /// ## Example
    ///
    /// ```swift
    /// 42.formatted(.number)  // "42"
    /// 100.0.formatted(.number)  // "100"
    /// ```
    public static var number: Format.Numeric.Style {
        Format.Numeric.Style()
    }
}

// MARK: - Precision

// Note: Precision struct and extensions are defined in Format.Numeric.Precision+Extensions.swift

extension Format.Numeric.Style {
    /// Configure precision
    ///
    /// ## Examples
    ///
    /// ```swift
    /// 3.14159.formatted(.number.precision(.fractionLength(2)))      // "3.14"
    /// 42.0.formatted(.number.precision(.fractionLength(2...)))      // "42.00"
    /// 3.14159.formatted(.number.precision(.fractionLength(2...4)))  // "3.1416"
    /// 1234.formatted(.number.precision(.significantDigits(3)))     // "1230"
    /// 42.formatted(.number.precision(.integerLength(4)))            // "0042"
    /// ```
    public func precision(_ precision: Precision) -> Self {
        var copy = self
        copy.minimumFractionDigits = precision.min
        copy.maximumFractionDigits = precision.max
        copy.significantDigits = precision.significantDigits
        copy.integerLength = precision.integerLength
        return copy
    }
}

// MARK: - Grouping

extension Format.Numeric.Style {
    /// Grouping policy for thousands separators
    public enum Grouping {
        /// Automatic grouping (same as always for now)
        case automatic

        /// Always use grouping separator
        case always

        /// Never use grouping separator
        case never
    }

    /// Configure grouping separator
    ///
    /// ## Examples
    ///
    /// ```swift
    /// 1234567.formatted(.number.grouping(.always))                      // "1,234,567"
    /// 1234567.formatted(.number.grouping(.always, separator: "."))     // "1.234.567"
    /// ```
    public func grouping(_ policy: Grouping, separator: String = ",") -> Self {
        var copy = self
        switch policy {
        case .automatic, .always:
            copy.groupingSeparator = separator
        case .never:
            copy.groupingSeparator = nil
        }
        return copy
    }
}

// MARK: - Decimal Separator Character

extension Format.Numeric.Style {
    /// Configure decimal separator character
    ///
    /// ## Example
    ///
    /// ```swift
    /// 3.14.formatted(.number.decimalSeparator(","))  // "3,14"
    /// ```
    public func decimalSeparator(_ separator: String) -> Self {
        var copy = self
        copy.decimalSeparator = separator
        return copy
    }
}

// MARK: - Formatting Implementation

extension Format.Numeric.Style {
    /// Format a floating-point value
    internal func format<Value: BinaryFloatingPoint>(_ value: Value) -> String {
        var doubleValue = Double(value)

        // Apply scale first
        doubleValue *= scale

        // Apply rounding if specified
        // Track minimum fraction digits needed from increment
        var incrementMinFrac: Int? = nil

        if let rule = roundingRule {
            if let increment = roundingIncrement {
                // Round to increment
                doubleValue = (doubleValue / increment).rounded(rule) * increment

                // Determine decimal places in increment
                // Only set minimum if increment has fractional part
                if ISO_9899.Math.fabs(increment - Double(Int64(increment))) > 1e-10 {
                    var tempInc = increment
                    var decimalPlaces = 0
                    while (tempInc - Double(Int64(tempInc))).c.abs > 1e-10 && decimalPlaces < 15 {
                        tempInc *= 10
                        decimalPlaces += 1
                    }
                    incrementMinFrac = decimalPlaces
                }
            } else {
                // Round to whole number
                doubleValue = doubleValue.rounded(rule)
            }
        }

        // Handle special cases
        if doubleValue.isNaN { return "NaN" }
        if doubleValue.isInfinite { return doubleValue > 0 ? "Infinity" : "-Infinity" }

        // Apply notation formatting
        if notation != .automatic {
            return formatWithNotation(doubleValue)
        }

        // Handle significant digits if specified
        if let (minSig, maxSig) = significantDigits {
            return formatWithSignificantDigits(doubleValue, min: minSig, max: maxSig)
        }

        let isNegative = doubleValue < 0
        let absoluteValue = doubleValue.c.abs

        // Apply minimum if specified
        var effectiveMinFrac = minimumFractionDigits
        if let incMin = incrementMinFrac {
            effectiveMinFrac = max(effectiveMinFrac ?? 0, incMin)
        }

        // When no precision constraints are specified, use String(value) for shortest representation
        // This avoids floating-point precision artifacts (e.g., 33.3 → "33.299999999999997")
        // However, only use this for values that String represents in decimal (not scientific notation)
        if maximumFractionDigits == nil && effectiveMinFrac == nil {
            // Use Swift's built-in shortest decimal representation
            let shortestRep = String(absoluteValue)

            // Check if String used scientific notation (contains 'e' or 'E')
            // If so, fall back to the old method
            if !shortestRep.contains("e") && !shortestRep.contains("E") {
                // Parse the string to extract integer and fractional parts
                let parts = shortestRep.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
                let integerPartString = String(parts[0])
                var fractionalPartString = parts.count > 1 ? String(parts[1]) : ""

                // Remove trailing ".0" - check if fractional part is just zeros
                if fractionalPartString.allSatisfy({ $0 == "0" }) {
                    fractionalPartString = ""
                }

                // Convert integer part string to Int64 for formatting with grouping
                let integerPart = Int64(integerPartString) ?? 0
                let integerString = formatIntegerPart(integerPart)

                // Build result
                var result = integerString
                if !fractionalPartString.isEmpty {
                    result += decimalSeparator + fractionalPartString
                } else if case .always = decimalSeparatorStrategy {
                    result += decimalSeparator
                }

                return applySign(result, isNegative: isNegative, value: doubleValue)
            }
        }

        // Determine fraction digits to use for rounding
        var fractionDigits: Int
        if let max = maximumFractionDigits {
            fractionDigits = max
        } else {
            fractionDigits = 15  // Double precision
        }

        if let min = effectiveMinFrac {
            fractionDigits = max(fractionDigits, min)
        }

        // Round the entire value if we have a max fraction limit
        var roundedValue = absoluteValue
        if let max = maximumFractionDigits {
            let multiplier = ISO_9899.Math.pow(10.0, Double(max))
            roundedValue = (absoluteValue * multiplier).rounded() / multiplier
        }

        // Split into integer and fractional parts
        let integerPart = Int64(roundedValue)
        let fractionalPart = roundedValue - Double(integerPart)

        // Format integer part
        let integerString = formatIntegerPart(integerPart)

        // Handle fractional part
        if fractionalPart.c.abs < 1e-10 && effectiveMinFrac == nil {
            // Whole number with no minimum fraction digits
            var result = integerString
            if case .always = decimalSeparatorStrategy {
                result += decimalSeparator
            }
            return applySign(result, isNegative: isNegative, value: doubleValue)
        }

        // Format fractional part
        var fractionalString = ""
        if fractionDigits > 0 {
            let multiplier = ISO_9899.Math.pow(10.0, Double(fractionDigits))

            // Don't round again here - already rounded the whole value above
            // Just add a tiny epsilon to handle floating point errors, then truncate
            var fracValue = Int64((fractionalPart * multiplier) + 0.0000001)
            var digits: [Character] = []

            for _ in 0..<fractionDigits {
                digits.append(Character(String(fracValue % 10)))
                fracValue /= 10
            }

            fractionalString = String(digits.reversed())

            // Remove trailing zeros unless minimumFractionDigits is set
            if effectiveMinFrac == nil {
                while fractionalString.last == "0" {
                    fractionalString.removeLast()
                }
            } else if let min = effectiveMinFrac {
                while fractionalString.count > min && fractionalString.last == "0" {
                    fractionalString.removeLast()
                }
            }
        }

        // Combine parts
        var result = integerString
        if !fractionalString.isEmpty {
            result += decimalSeparator + fractionalString
        } else if case .always = decimalSeparatorStrategy {
            result += decimalSeparator
        }

        return applySign(result, isNegative: isNegative, value: doubleValue)
    }

    /// Format an integer value
    internal func format<Value: BinaryInteger>(_ value: Value) -> String {
        let intValue = Int64(value)

        // If any of these features are needed, convert to Double for proper handling
        if scale != 1.0 || notation != .automatic || roundingRule != nil || significantDigits != nil
            || minimumFractionDigits != nil || decimalSeparatorStrategy == .always {
            return format(Double(intValue))
        }

        let isNegative = intValue < 0
        let absoluteValue = intValue < 0 ? -intValue : intValue

        // Format integer part
        let integerString = formatIntegerPart(absoluteValue)

        return applySign(integerString, isNegative: isNegative, value: Double(intValue))
    }

    // MARK: - Helper Methods

    private func formatIntegerPart<T: BinaryInteger>(_ value: T) -> String {
        var integerString = String(value)

        // Apply integer length padding if specified
        if let (minLen, _) = integerLength {
            if let min = minLen, integerString.count < min {
                integerString = String(repeating: "0", count: min - integerString.count) + integerString
            }
        }

        // Add grouping separator if needed
        if let separator = groupingSeparator, integerString.count > 3 {
            integerString = addGroupingSeparator(to: integerString, separator: separator)
        }

        return integerString
    }

    private func addGroupingSeparator(to string: String, separator: String) -> String {
        var result = ""
        let chars = Array(string)
        for (index, char) in chars.enumerated() {
            if index > 0 && (chars.count - index) % 3 == 0 {
                result.append(separator)
            }
            result.append(char)
        }
        return result
    }

    private func applySign(_ string: String, isNegative: Bool, value: Double) -> String {
        switch signDisplayStrategy {
        case .automatic:
            return isNegative ? "-\(string)" : string
        case .never:
            return string
        case .always(let includingZero):
            if isNegative {
                return "-\(string)"
            } else if value == 0 && !includingZero {
                return string
            } else {
                return "+\(string)"
            }
        }
    }

    private func formatWithNotation(_ value: Double) -> String {
        let isNegative = value < 0
        let absoluteValue = value.c.abs

        switch notation {
        case .automatic:
            fatalError("Should not reach here")

        case .compactName:
            let compactResult: String
            if absoluteValue >= 1_000_000_000 {
                let scaled = absoluteValue / 1_000_000_000
                compactResult = formatCompactValue(scaled) + "B"
            } else if absoluteValue >= 1_000_000 {
                let scaled = absoluteValue / 1_000_000
                compactResult = formatCompactValue(scaled) + "M"
            } else if absoluteValue >= 1_000 {
                let scaled = absoluteValue / 1_000
                compactResult = formatCompactValue(scaled) + "K"
            } else {
                return applySign(String(Int64(absoluteValue)), isNegative: isNegative, value: value)
            }
            return applySign(compactResult, isNegative: isNegative, value: value)

        case .scientific:
            if absoluteValue == 0 {
                return applySign("0E0", isNegative: isNegative, value: value)
            }

            // Use log10 for O(1) exponent calculation instead of O(log n) loop
            let exponent = Int(ISO_9899.Math.floor(ISO_9899.Math.log10(absoluteValue)))
            let mantissa = absoluteValue / ISO_9899.Math.pow(10.0, Double(exponent))

            let mantissaString = formatScientificMantissa(mantissa)
            let result = "\(mantissaString)E\(exponent)"
            return applySign(result, isNegative: isNegative, value: value)
        }
    }

    private func formatCompactValue(_ value: Double) -> String {
        // Use precision if specified
        if let max = maximumFractionDigits {
            let multiplier = ISO_9899.Math.pow(10.0, Double(max))
            let rounded = (value * multiplier).rounded() / multiplier

            let intPart = Int64(rounded)
            let fracPart = rounded - Double(intPart)

            var fracString = ""
            if max > 0 {
                // Add epsilon to handle floating point errors, then truncate
                let fracValue = Int64((fracPart * multiplier) + 0.0000001)
                var tempValue = fracValue
                var digits: [Character] = []

                for _ in 0..<max {
                    digits.append(Character(String(tempValue % 10)))
                    tempValue /= 10
                }

                fracString = String(digits.reversed())

                // Apply minimum fraction digits
                if let min = minimumFractionDigits {
                    while fracString.count > min && fracString.last == "0" {
                        fracString.removeLast()
                    }
                } else {
                    while fracString.last == "0" {
                        fracString.removeLast()
                    }
                }
            }

            if !fracString.isEmpty {
                return "\(intPart).\(fracString)"
            } else if let min = minimumFractionDigits, min > 0 {
                // Need to add zeros for minimum
                return "\(intPart).\(String(repeating: "0", count: min))"
            } else {
                return String(intPart)
            }
        }

        // Default: round to 1 decimal place for better readability
        let rounded = (value * 10).rounded() / 10

        // Check if value is a whole number (Foundation-free floor check)
        if rounded == Double(Int64(rounded)) {
            return String(Int64(rounded))
        }

        let intPart = Int64(rounded)
        let fracPart = rounded - Double(intPart)

        if fracPart == 0 {
            return String(intPart)
        }

        // Extract one decimal place
        let fracValue = Int64((fracPart * 10) + 0.0000001)

        return "\(intPart).\(fracValue)"
    }

    private func formatScientificMantissa(_ value: Double) -> String {
        // If significant digits specified, use them for the mantissa
        if let (_, max) = significantDigits {
            let targetDigits = max ?? 3
            // Mantissa is always 1.xxx, so we need targetDigits - 1 decimal places
            let decimalPlaces = targetDigits - 1

            if decimalPlaces <= 0 {
                return String(Int64(value.rounded()))
            }

            let multiplier = ISO_9899.Math.pow(10.0, Double(decimalPlaces))
            let rounded = (value * multiplier).rounded() / multiplier

            let intPart = Int64(rounded)
            let fracPart = rounded - Double(intPart)

            if fracPart.c.abs < 1e-10 {
                return String(intPart)
            }

            var fracString = ""
            var fracValue = fracPart
            for _ in 0..<decimalPlaces {
                fracValue *= 10
                fracString.append(String(Int(fracValue.truncatingRemainder(dividingBy: 10))))
            }

            while fracString.last == "0" {
                fracString.removeLast()
            }

            if fracString.isEmpty {
                return String(intPart)
            }

            return "\(intPart).\(fracString)"
        }

        // Check if value is a whole number (Foundation-free)
        if value == Double(Int64(value)) {
            return String(Int64(value))
        }

        // Format mantissa with trailing zeros removed
        let rounded = (value * 1_000_000).rounded() / 1_000_000
        let intPart = Int64(rounded)
        let fracPart = rounded - Double(intPart)

        if fracPart.c.abs < 1e-10 {
            return String(intPart)
        }

        var fracString = ""
        var fracValue = fracPart
        for _ in 0..<6 {
            fracValue *= 10
            fracString.append(String(Int(fracValue.truncatingRemainder(dividingBy: 10))))
        }

        while fracString.last == "0" {
            fracString.removeLast()
        }

        return "\(intPart).\(fracString)"
    }

    private func formatWithSignificantDigits(_ value: Double, min: Int?, max: Int?) -> String {
        let isNegative = value < 0
        let absoluteValue = value.c.abs

        if absoluteValue == 0 {
            let minDigits = min ?? 1
            if minDigits == 1 {
                return applySign("0", isNegative: isNegative, value: value)
            } else {
                let zeros = String(repeating: "0", count: minDigits - 1)
                return applySign("0.\(zeros)", isNegative: isNegative, value: value)
            }
        }

        // Determine significant digits to use
        // For a range, use the natural count if it's within range
        let targetDigits: Int
        if let minSig = min, let maxSig = max {
            // Count natural significant digits in the value
            let valueStr = String(absoluteValue)
            let naturalCount = valueStr.filter { $0.isNumber && $0 != "0" }.count

            if naturalCount < minSig {
                targetDigits = minSig
            } else if naturalCount > maxSig {
                targetDigits = maxSig
            } else {
                targetDigits = naturalCount
            }
        } else {
            targetDigits = max ?? min ?? 3
        }

        // Find the magnitude (order of magnitude) of the number using O(1) log10
        let magnitude: Int
        if absoluteValue >= 1 {
            magnitude = Int(ISO_9899.Math.floor(ISO_9899.Math.log10(absoluteValue)))
        } else {
            // For values < 1, we need ceiling - 1
            magnitude = Int(ISO_9899.Math.ceil(ISO_9899.Math.log10(absoluteValue))) - 1
        }

        // Calculate how many decimal places we need
        // magnitude = 3 for 1234 means we need targetDigits - 4 decimal places
        let decimalPlaces = targetDigits - (magnitude + 1)

        // Round to the appropriate number of decimal places
        let roundedValue: Double
        if decimalPlaces >= 0 {
            let multiplier = ISO_9899.Math.pow(10.0, Double(decimalPlaces))
            roundedValue = (absoluteValue * multiplier).rounded() / multiplier
        } else {
            // Need to round to nearest 10, 100, etc.
            let divisor = ISO_9899.Math.pow(10.0, Double(-decimalPlaces))
            roundedValue = (absoluteValue / divisor).rounded() * divisor
        }

        // Format the result
        if roundedValue >= 1 || decimalPlaces <= 0 {
            // Integer part exists
            let intPart = Int64(roundedValue)
            var result = String(intPart)

            if decimalPlaces > 0 {
                let fracPart = roundedValue - Double(intPart)
                if fracPart > 0 || min != nil {
                    var fracString = ""
                    var fracValue = fracPart
                    for _ in 0..<decimalPlaces {
                        fracValue *= 10
                        let digit = Int(fracValue.truncatingRemainder(dividingBy: 10))
                        fracString.append(String(digit))
                    }

                    // Trim trailing zeros if no minimum specified
                    if min == nil || (min == max) {
                        while fracString.last == "0" {
                            fracString.removeLast()
                        }
                    }

                    if !fracString.isEmpty {
                        result += ".\(fracString)"
                    } else if let min = min, min > result.count {
                        // Need to add zeros to meet minimum
                        let zerosNeeded = min - result.count
                        result += ".\(String(repeating: "0", count: zerosNeeded))"
                    }
                }
            }

            // Ensure minimum significant digits
            if let min = min {
                let currentDigits = result.filter { $0.isNumber }.count
                if currentDigits < min {
                    let zerosNeeded = min - currentDigits
                    if result.contains(".") {
                        result += String(repeating: "0", count: zerosNeeded)
                    } else {
                        result += "." + String(repeating: "0", count: zerosNeeded)
                    }
                }
            }

            return applySign(result, isNegative: isNegative, value: value)
        } else {
            // Number is < 1, all significant digits in fractional part
            var result = "0."

            // Add leading zeros (these don't count as significant digits)
            let leadingZeros = -magnitude - 1
            result += String(repeating: "0", count: leadingZeros)

            // Extract the significant digits by removing leading zeros
            // Scale up to get the significant part as an integer
            let scaleFactor = ISO_9899.Math.pow(10.0, Double(-magnitude + targetDigits - 1))
            let scaledUp = (roundedValue * scaleFactor).rounded()

            // Convert to string and extract digits
            var digitsStr = String(Int64(scaledUp))

            // Trim to exactly targetDigits
            if digitsStr.count > targetDigits {
                digitsStr = String(digitsStr.prefix(targetDigits))
            }

            result += digitsStr

            // Trim trailing zeros unless minimum specified
            if min == nil || (min == max) {
                while result.last == "0" && result.count > leadingZeros + 3 {
                    result.removeLast()
                }
            }

            // Ensure minimum significant digits
            if let min = min {
                // Count non-zero digits (significant digits)
                let sigDigitCount = digitsStr.filter { $0 != "0" }.count
                if sigDigitCount < min && result.filter({ $0.isNumber && $0 != "0" }).count < min {
                    let zerosNeeded = min - result.filter({ $0.isNumber }).count + leadingZeros
                    if zerosNeeded > 0 {
                        result += String(repeating: "0", count: zerosNeeded)
                    }
                }
            }

            return applySign(result, isNegative: isNegative, value: value)
        }
    }
}

// MARK: - Value Extensions
