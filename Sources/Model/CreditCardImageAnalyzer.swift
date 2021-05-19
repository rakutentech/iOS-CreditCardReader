//
//  CreditCardImageAnalyzer.swift
//  CreditCardReader
//
//  Created by Wong, Kevin a on 2021/04/19.
//

import Foundation
import Vision
import UIKit

@available(iOS 13, *)
class CreditCardImageAnalyzer {
    // MARK: - Pattern matching
    // All regex strings have an extra \ to escape the \ symbol
    
    private let cardNumberRegex: NSRegularExpression? = try? NSRegularExpression(pattern: "(?:\\d[ ]*?){13,16}")
    private let visaQuickReadNumberRegex: NSRegularExpression? = try? NSRegularExpression(pattern: "^[\\/\\[\\]\\|\\\\]?(\\d{4})")
    private let visaQuickReadBoundaryChars: Set<String> = ["\\", "/", "[", "]", "|"]
    
    /// Regex for month/year with 1 capture group for each component
    private let expirationDateRegex: NSRegularExpression? = try? NSRegularExpression(pattern: "(0[1-9]|1[0-2])\\/(\\d{4}|\\d{2})")
    
    // MARK: - Functions
    
    /// Returns a credit card by reading the provided image.
    func analyze(image: CGImage, onSuccess: @escaping (CreditCard) -> Void, onFailure: ((Error?) -> Void)? = nil) {
        let request = VNRecognizeTextRequest { [weak self] request, error in
            self?.analyze(request: request, onSuccess: onSuccess, onFailure: onFailure)
        }
        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: image,
                                            orientation: .up,
                                            options: [:])
        do {
            try handler.perform([request])
        } catch {
            onFailure?(error)
        }
    }
    
    // MARK: - Private functions
    
    private func analyze(request: VNRequest, onSuccess: (CreditCard) -> Void, onFailure: ((Error?) -> Void)?) {
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            onFailure?(nil)
            return
        }
        
        var cardNumber: String?
        var visaQuickReadNumbers = [String]()
        var cardExpirationDate: (month: Int, year: Int)?
        for result in results {
            guard let candidate = result.topCandidates(1).first,
                  candidate.confidence > 0.3 else {
                continue
            }
            let recognizedText = candidate.string
            
            // Always match the first found card number
            if cardNumber == nil,
               let numberMatch = cardNumberMatch(recognizedText) {
                cardNumber = numberMatch
            } else if let visaQuickReadNumber = visaQuickReadNumberMatch(recognizedText) {
                visaQuickReadNumbers.append(visaQuickReadNumber)
            } else if let expirationDateMatch = cardExpirationDateMatch(recognizedText) {
                if cardExpirationDate != nil {
                    // If card detects multiple dates (e.g. from and to) separately,
                    // we don't return expiration date as we can't determine which one
                    // is the expiration one.
                    cardExpirationDate = nil
                } else {
                    cardExpirationDate = expirationDateMatch
                }
            }
        }
        
        // First priority goes to detected traditional card number
        if let cardNumber = cardNumber {
            onSuccess(CreditCard(
                cardNumber: cardNumber,
                expirationYear: cardExpirationDate?.year,
                expirationMonth: cardExpirationDate?.month))
        // Second priority goes to VISA quick read number
        } else if visaQuickReadNumbers.count == 4{
            onSuccess(CreditCard(
                cardNumber: visaQuickReadNumbers.joined(),
                expirationYear: cardExpirationDate?.year,
                expirationMonth: cardExpirationDate?.month))
        } else {
            onFailure?(nil)
        }
    }
    
    private func cardNumberMatch(_ text: String) -> String? {
        guard let expression = cardNumberRegex,
              let match = expression.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
              let range = Range(match.range, in: text)
              else {
            return nil
        }
        
        return String(text[range])
            .replacingOccurrences(of: " ", with: "")
    }
    
    private func visaQuickReadNumberMatch(_ text: String) -> String? {
        let textRange = NSRange(location: 0, length: text.count)
        guard let expression = visaQuickReadNumberRegex,
              let match = expression.matches(in: text, options: [], range: textRange).last,
              // Range 0 is the whole text
              match.numberOfRanges == 2,
              // Get number from capture group
              let range = Range(match.range(at: 1), in: text)
              else {
            return nil
        }
        
        if text.count == 4 {
            return String(text[range])
        } else {
            let firstIndex = text.index(text.startIndex, offsetBy: 0)
            let fifthIndex = text.index(text.startIndex, offsetBy: 4)
            
            if visaQuickReadBoundaryChars.contains(String(text[firstIndex])) {
                return String(text[range])
            } else if visaQuickReadBoundaryChars.contains(String(text[fifthIndex])) {
                return String(text[range])
            } else if text.count > 5 {
                let sixthIndex = text.index(text.startIndex, offsetBy: 5)
                if visaQuickReadBoundaryChars.contains(String(text[sixthIndex])) {
                    return String(text[range])
                }
            }
        }
        
        return nil
    }
    
    private func cardExpirationDateMatch(_ text: String) -> (month: Int, year: Int)? {
        let textRange = NSRange(location: 0, length: text.count)
        guard let expression = expirationDateRegex,
              // If there are 2 dates, usually expire date is to the right
              let match = expression.matches(in: text, options: [], range: textRange).last,
              // Range 0 is the whole text
              match.numberOfRanges == 3,
              // First capture group
              let monthRange = Range(match.range(at: 1), in: text),
              // Second capture group
              let yearRange = Range(match.range(at: 2), in: text)
              else {
            return nil
        }
        
        let monthString = String(text[monthRange])
        var yearString = String(text[yearRange])
        if yearString.count == 2 {
            yearString = "20\(yearString)"
        }
        if let monthInt = Int(monthString),
           let yearInt = Int(yearString) {
            return (month: monthInt, year: yearInt)
        }
        
        return nil
    }
}
