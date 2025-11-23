# Numeric Formatting

[![CI](https://github.com/swift-standards/swift-numeric-formatting-standard/workflows/CI/badge.svg)](https://github.com/swift-standards/swift-numeric-formatting-standard/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Foundation-free numeric formatting for Swift.

## Overview

This package provides comprehensive numeric formatting capabilities for integers and floating-point numbers without requiring Foundation. Built on IEEE 754, ISO 9899, and INCITS 4-1986 standards for robust, standards-compliant formatting.

Pure Swift implementation with no Foundation dependencies, suitable for Swift Embedded and constrained environments.

## Features

- Foundation-compatible fluent API (`.formatted(.number)`)
- BinaryInteger and BinaryFloatingPoint formatting
- Precision control:
  - Fraction length (fixed, ranges, min/max)
  - Significant digits (fixed, ranges, min/max)
  - Integer length with zero-padding
- Notation styles:
  - Automatic (standard notation)
  - Compact name (1K, 1M, 1B)
  - Scientific (1.234E3)
- Sign display strategies (automatic, never, always)
- Grouping separators with customization
- Decimal separator configuration
- Scale transformations (for percentages, unit conversions)
- Rounding rules and increments
- Cross-module inlining via `@inlinable` for zero-cost abstractions
- 390+ tests covering edge cases and standards compliance

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-standards/swift-numeric-formatting-standard.git", from: "0.1.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Numeric Formatting", package: "swift-numeric-formatting-standard")
    ]
)
```

## Quick Start

```swift
import Numeric_Formatting

// Basic formatting
42.formatted(.number)  // "42"
3.14159.formatted(.number.precision(.fractionLength(2)))  // "3.14"

// Grouping
1234567.formatted(.number.grouping(.always))  // "1,234,567"

// Notation styles
1000.formatted(.number.notation(.compactName))  // "1K"
1234.formatted(.number.notation(.scientific))  // "1.234E3"

// Sign display
42.formatted(.number.sign(strategy: .always()))  // "+42"
(-42).formatted(.number.sign(strategy: .never))  // "42"

// Scale transformations (percentages)
0.42.formatted(.number.scale(100).precision(.fractionLength(1)))  // "42.0"

// Complex combinations
1234.5678.formatted(
    .number
        .notation(.automatic)
        .grouping(.automatic)
        .precision(.fractionLength(2))
        .sign(strategy: .always())
        .decimalSeparator(strategy: .always)
)  // "+1,234.57"
```

## Usage Examples

### Basic Number Formatting

```swift
// Integers
42.formatted(.number)  // "42"
1234567.formatted(.number)  // "1234567"

// Floating-point
3.14.formatted(.number)  // "3.14"
100.0.formatted(.number)  // "100"  (trailing zeros removed)

// Negative numbers
(-100).formatted(.number)  // "-100"
```

### Precision Control

#### Fraction Length

```swift
// Fixed fraction length
3.14159.formatted(.number.precision(.fractionLength(2)))  // "3.14"
42.formatted(.number.precision(.fractionLength(2)))  // "42.00"

// Fraction length range
3.1.formatted(.number.precision(.fractionLength(2...4)))  // "3.10"
3.14159.formatted(.number.precision(.fractionLength(2...4)))  // "3.1416"

// Minimum fraction length
42.formatted(.number.precision(.fractionLength(2...)))  // "42.00"

// Maximum fraction length
3.14159.formatted(.number.precision(.fractionLength(...2)))  // "3.14"
100.999.formatted(.number.precision(.fractionLength(...2)))  // "101"  (rounded)
```

#### Significant Digits

```swift
// Fixed significant digits
1234.5678.formatted(.number.precision(.significantDigits(3)))  // "1230"
0.0012345.formatted(.number.precision(.significantDigits(3)))  // "0.00123"
123.formatted(.number.precision(.significantDigits(5)))  // "123.00"

// Significant digits range
1.formatted(.number.precision(.significantDigits(2...4)))  // "1.0"
123.formatted(.number.precision(.significantDigits(2...4)))  // "123"
1234.formatted(.number.precision(.significantDigits(2...4)))  // "1234"

// Minimum significant digits
1.formatted(.number.precision(.significantDigits(3...)))  // "1.00"

// Maximum significant digits
123.456.formatted(.number.precision(.significantDigits(...3)))  // "123"
```

#### Integer Length

```swift
// Fixed integer length (zero-padding)
42.formatted(.number.precision(.integerLength(4)))  // "0042"
1234.formatted(.number.precision(.integerLength(6)))  // "001234"

// Integer length range
1.formatted(.number.precision(.integerLength(2...4)))  // "01"
1234.formatted(.number.precision(.integerLength(2...4)))  // "1234"
```

#### Combined Integer and Fraction Length

```swift
// Fixed lengths
42.5.formatted(.number.precision(.integerAndFractionLength(integer: 4, fraction: 2)))
// "0042.50"

// Range lengths
42.5.formatted(.number.precision(
    .integerAndFractionLength(integerLimits: 2...4, fractionLimits: 1...3)
))  // "42.5"
```

### Notation Styles

```swift
// Compact notation
1000.formatted(.number.notation(.compactName))  // "1K"
1500.formatted(.number.notation(.compactName))  // "1.5K"
1000000.formatted(.number.notation(.compactName))  // "1M"
1000000000.formatted(.number.notation(.compactName))  // "1B"

// Scientific notation
1234.formatted(.number.notation(.scientific))  // "1.234E3"
0.00001.formatted(.number.notation(.scientific))  // "1E-5"
1000000.formatted(.number.notation(.scientific))  // "1E6"

// Compact with precision
1500.formatted(.number.notation(.compactName).precision(.fractionLength(2)))
// "1.50K"

// Scientific with significant digits
1234.5678.formatted(.number.notation(.scientific).precision(.significantDigits(3)))
// "1.23E3"
```

### Sign Display Strategies

```swift
// Automatic (default) - only show minus sign
42.formatted(.number.sign(strategy: .automatic))  // "42"
(-42).formatted(.number.sign(strategy: .automatic))  // "-42"

// Never show sign
(-42).formatted(.number.sign(strategy: .never))  // "42"

// Always show sign
42.formatted(.number.sign(strategy: .always()))  // "+42"
(-42).formatted(.number.sign(strategy: .always()))  // "-42"
0.formatted(.number.sign(strategy: .always()))  // "0"

// Always show sign, including zero
42.formatted(.number.sign(strategy: .always(includingZero: true)))  // "+42"
0.formatted(.number.sign(strategy: .always(includingZero: true)))  // "+0"
```

### Grouping Separators

```swift
// Automatic grouping (thousands separators)
1234567.formatted(.number.grouping(.automatic))  // "1,234,567"

// Never use grouping
1234567.formatted(.number.grouping(.never))  // "1234567"

// Custom separator
1234567.formatted(.number.grouping(.always, separator: "."))  // "1.234.567"
```

### Decimal Separator

```swift
// Custom decimal separator
3.14.formatted(.number.decimalSeparator(","))  // "3,14"

// Decimal separator display strategy
42.formatted(.number.decimalSeparator(strategy: .always))  // "42."
42.5.formatted(.number.decimalSeparator(strategy: .always))  // "42.5"
```

### Scale Transformations

```swift
// Percentage-style formatting
0.5.formatted(.number.scale(100))  // "50"
0.425.formatted(.number.scale(100).precision(.fractionLength(1)))  // "42.5"

// Unit conversions
42.formatted(.number.scale(2))  // "84"
100.formatted(.number.scale(0.01))  // "1"
```

### Rounding Rules

```swift
// Round up
1.4.formatted(.number.rounded(rule: .up))  // "2"
1.1.formatted(.number.rounded(rule: .up))  // "2"

// Round down
1.9.formatted(.number.rounded(rule: .down))  // "1"

// Round toward zero
1.9.formatted(.number.rounded(rule: .towardZero))  // "1"
(-1.9).formatted(.number.rounded(rule: .towardZero))  // "-1"

// Round away from zero
1.1.formatted(.number.rounded(rule: .awayFromZero))  // "2"
(-1.1).formatted(.number.rounded(rule: .awayFromZero))  // "-2"

// Round to nearest or even (banker's rounding)
1.5.formatted(.number.rounded(rule: .toNearestOrEven))  // "2"
2.5.formatted(.number.rounded(rule: .toNearestOrEven))  // "2"

// Rounding with increment
1.23.formatted(.number.rounded(rule: .toNearestOrAwayFromZero, increment: 0.5))
// "1.0"
42.formatted(.number.rounded(rule: .toNearestOrAwayFromZero, increment: 5))
// "40"
```

### All Numeric Types

Works with all Swift numeric types:

```swift
// Signed integers
let int8: Int8 = 42
let int16: Int16 = 1000
let int32: Int32 = 100000
let int64: Int64 = 1000000

int8.formatted(.number)  // "42"
int16.formatted(.number.grouping(.automatic))  // "1,000"
int32.formatted(.number.notation(.compactName))  // "100K"

// Unsigned integers
let uint8: UInt8 = 255
let uint16: UInt16 = 65535

uint8.formatted(.number)  // "255"
uint16.formatted(.number.grouping(.automatic))  // "65,535"

// Floating-point
let float: Float = 3.14159
let double: Double = 2.71828

float.formatted(.number.precision(.fractionLength(2)))  // "3.14"
double.formatted(.number.precision(.significantDigits(3)))  // "2.72"
```

## Standards Compliance

Built on:

- **IEEE 754-2019**: Floating-point arithmetic (via [swift-ieee-754](https://github.com/swift-standards/swift-ieee-754))
  - Binary representation
  - Special value handling (NaN, Infinity)
  - Rounding modes

- **ISO/IEC 9899:2018**: C standard library mathematical functions (via [swift-iso-9899](https://github.com/swift-standards/swift-iso-9899))
  - Mathematical rounding
  - Precision calculations

- **INCITS 4-1986**: ASCII character set (via [swift-incits-4-1986](https://github.com/swift-standards/swift-incits-4-1986))
  - ASCII digit characters
  - Character classification
  - Byte-level operations

## Performance

Foundation-free implementation with optimizations:

- Zero-cost abstractions via `@inlinable`
- Direct byte-level formatting
- Minimal memory allocations
- Efficient significant digits calculation
- Optimized grouping separator insertion

## Testing

Test suite: 390+ tests covering:

- Basic formatting for all numeric types (Int8-Int64, UInt8-UInt64, Float, Double)
- Precision configurations (fraction length, significant digits, integer length)
- Notation styles (automatic, compact, scientific)
- Sign display strategies
- Grouping separators
- Decimal separator strategies
- Scale transformations
- Rounding rules and increments
- Edge cases (NaN, Infinity, special values, zero)
- Complex formatting combinations

Run tests:

```bash
swift test
```

Run specific test suites:

```bash
swift test --filter "Precision"
swift test --filter "Notation Styles"
```

## Requirements

- Swift 6.0 or later
- macOS 15.0+ / iOS 18.0+ / tvOS 18.0+ / watchOS 11.0+
- No Foundation dependencies (Swift Embedded compatible)

## Related Packages

- [swift-standards](https://github.com/swift-standards/swift-standards) - Core standards utilities
- [swift-ieee-754](https://github.com/swift-standards/swift-ieee-754) - IEEE 754 floating-point standard
- [swift-iso-9899](https://github.com/swift-standards/swift-iso-9899) - ISO C standard library
- [swift-incits-4-1986](https://github.com/swift-standards/swift-incits-4-1986) - ASCII standard

## License

This package is licensed under the Apache License 2.0. See [LICENSE.md](LICENSE.md) for details.

## Contributing

Contributions are welcome. Please ensure all tests pass and new features include test coverage.
