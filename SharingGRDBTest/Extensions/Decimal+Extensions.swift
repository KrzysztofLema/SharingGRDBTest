import Foundation

extension Decimal {
    var cents: Int {
        // Convert to NSDecimalNumber and use intValue for rounding
        let decimalNumber = NSDecimalNumber(decimal: self * Decimal(100))
        return decimalNumber.intValue
    }
    
    init(cents: Int) {
        self = Decimal(cents) / Decimal(100)
    }
    
    // MARK: - Currency Formatting
    
    /// Format as currency using NumberFormatter (recommended for currency)
    func formattedCurrency(currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }
    
    /// Format with specific decimal places using string interpolation
    func formatted(decimalPlaces: Int = 2) -> String {
        return String(format: "%.\(decimalPlaces)f", NSDecimalNumber(decimal: self).doubleValue)
    }
    
    /// Format as positive/negative currency (useful for transactions)
    func formattedSignedCurrency(currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.positiveFormat = "+$#,##0.00"
        formatter.negativeFormat = "-$#,##0.00"
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }
}
