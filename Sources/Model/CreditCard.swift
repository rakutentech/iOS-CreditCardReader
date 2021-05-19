//
//  CreditCard.swift
//  CreditCardReader
//
//  Created by Wong, Kevin a on 2021/04/19.
//

import Foundation

/// A structure containing credit card information
public struct CreditCard: Hashable {
    /// The number of the card
    public var cardNumber: String
    
    /// The year of expiration of the card
    public var expirationYear: Int?
    
    /// The month of expiration of the card
    public var expirationMonth: Int?
    
    public init(cardNumber: String,
        expirationYear: Int?,
        expirationMonth: Int?) {
        self.cardNumber = cardNumber
        self.expirationYear = expirationYear
        self.expirationMonth = expirationMonth
    }
    
    /// Returns the year of expiration as a 2 digit string
    public var expirationYearString: String? {
        guard let expirationYear = expirationYear else {
            return nil
        }
        return String("\(expirationYear)".suffix(2))
    }
    
    /// Returns the year of expiration as a 4 digit string
    public var expirationYearStringFull: String? {
        guard let expirationYear = expirationYear else {
            return nil
        }
        return String("\(expirationYear)")
    }
    
    /// Returns the month of expiration as string. This string
    /// always has 2 digits. If a month number has less than 2
    /// digits, a `0` character will be prefixed.
    ///
    /// Output examples:
    /// - 09 // September
    /// - 12 // December
    public var expirationMonthString: String? {
        guard let expirationMonth = expirationMonth else {
            return nil
        }
        if expirationMonth > 9 {
            return "\(expirationMonth)"
        } else {
            return "0\(expirationMonth)"
        }
    }
    
    /// Returns the expiration date containing month and year in
    /// display format.
    ///
    /// Output examples:
    /// - 09/25
    /// - 12/25
    public var expirationDateDisplayString: String? {
        guard let yearString = expirationYearString,
              let monthString = expirationMonthString else {
            return nil
        }
        return "\(monthString)/\(yearString)"
    }
    
    /// Returns the card number formatted for display, with a space
    /// character every 4 digits
    public var cardNumberDisplayString: String {
        var string = cardNumber
        string.insert(" ", at: string.index(string.startIndex, offsetBy: 12))
        string.insert(" ", at: string.index(string.startIndex, offsetBy: 8))
        string.insert(" ", at: string.index(string.startIndex, offsetBy: 4))
        return string
    }
}
