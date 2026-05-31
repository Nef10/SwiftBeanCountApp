//
//  PayeeDuplicateDetector.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-12-20.
//

import Foundation

/// Represents a pair of payees that are potential duplicates
struct PayeeDuplicate: Identifiable {
    /// Unique identifier
    let id = UUID()
    /// First payee name
    let payee1: String
    /// Second payee name
    let payee2: String
    /// Confidence score from 0.0 to 1.0
    let confidence: Double
    /// Human-readable explanation of why the pair is flagged
    let reason: String
}

/// Detects potential duplicate payees using various strategies
enum PayeeDuplicateDetector {

    /// Finds potential duplicate payees from a list of payee names
    /// - Parameter payees: Array of payee names
    /// - Returns: Array of potential duplicates sorted by confidence (highest first)
    static func findDuplicates(in payees: [String]) -> [PayeeDuplicate] {
        var duplicates = [PayeeDuplicate]()
        let payeeList = payees.sorted()

        for i in 0..<payeeList.count {
            for j in (i + 1)..<payeeList.count {
                let payee1 = payeeList[i]
                let payee2 = payeeList[j]

                if let duplicate = detectDuplicate(payee1, payee2) {
                    duplicates.append(duplicate)
                }
            }
        }

        return duplicates.sorted { $0.confidence > $1.confidence }
    }

    /// Checks two payees against all detection strategies and returns the highest confidence match
    private static func detectDuplicate(_ payee1: String, _ payee2: String) -> PayeeDuplicate? {
        let checks: [(Double, String)?] = [
            checkCapitalization(payee1, payee2),
            checkMarkings(payee1, payee2),
            checkMinorDifferences(payee1, payee2),
            checkMissingParts(payee1, payee2),
            checkTypos(payee1, payee2)
        ]

        guard let best = checks.compactMap(\.self).max(by: { $0.0 < $1.0 }) else {
            return nil
        }

        return PayeeDuplicate(payee1: payee1, payee2: payee2, confidence: best.0, reason: best.1)
    }

    // MARK: - Detection Strategies

    /// Detects duplicates that differ only in capitalization
    /// e.g. "Save-On-Foods" vs "save-on-foods"
    private static func checkCapitalization(_ a: String, _ b: String) -> (Double, String)? {
        guard a != b, a.lowercased() == b.lowercased() else {
            return nil
        }
        return (1.0, "Different capitalization")
    }

    /// Detects duplicates that differ in word separators/markings
    /// e.g. "Save-on-Foods" vs "SaveOnFoods" vs "Save On Foods"
    private static func checkMarkings(_ a: String, _ b: String) -> (Double, String)? {
        let normalizedA = normalizeMarkings(a)
        let normalizedB = normalizeMarkings(b)

        guard a != b, normalizedA == normalizedB else {
            return nil
        }
        return (0.95, "Different word separators")
    }

    /// Detects duplicates with minor differences (e.g. pluralization)
    /// e.g. "McDonald" vs "McDonalds"
    private static func checkMinorDifferences(_ a: String, _ b: String) -> (Double, String)? {
        guard a != b else {
            return nil
        }

        let lowA = a.lowercased()
        let lowB = b.lowercased()

        // Check if one is just the other with "s" or "'s" appended
        if lowA + "s" == lowB || lowB + "s" == lowA {
            return (0.9, "Possible plural variation")
        }
        if lowA + "'s" == lowB || lowB + "'s" == lowA {
            return (0.9, "Possible possessive variation")
        }

        return nil
    }

    /// Detects duplicates where one is a substring/prefix of the other with common suffixes
    /// e.g. "ABCD" vs "ABCD Canada" or "ABCD Inc."
    private static func checkMissingParts(_ a: String, _ b: String) -> (Double, String)? {
        guard a != b else {
            return nil
        }

        let lowA = a.lowercased()
        let lowB = b.lowercased()

        let (shorter, longer) = lowA.count <= lowB.count ? (lowA, lowB) : (lowB, lowA)

        // The shorter string must be at least 4 characters to avoid false positives
        guard shorter.count >= 4, longer.hasPrefix(shorter) else {
            return nil
        }

        let suffix = String(longer.dropFirst(shorter.count)).trimmingCharacters(in: .whitespaces)
        guard !suffix.isEmpty else {
            return nil
        }

        return evaluateSuffix(suffix, shorterLength: shorter.count, longerLength: longer.count)
    }

    private static func evaluateSuffix(_ suffix: String, shorterLength: Int, longerLength: Int) -> (Double, String)? {
        let commonSuffixes = [
            "inc", "inc.", "ltd", "ltd.", "llc", "corp", "corp.",
            "co", "co.", "canada", "us", "usa", "uk", "online",
            "store", "shop", "group", "international", "intl"
        ]

        if commonSuffixes.contains(suffix.lowercased()) {
            return (0.85, "Missing business suffix")
        }

        let ratio = Double(shorterLength) / Double(longerLength)
        if ratio >= 0.7 {
            return (0.7, "Possible missing part")
        }

        return nil
    }

    /// Detects duplicates based on edit distance (typos)
    /// Uses Levenshtein distance
    private static func checkTypos(_ a: String, _ b: String) -> (Double, String)? {
        guard a != b else {
            return nil
        }

        let lowA = a.lowercased()
        let lowB = b.lowercased()

        // Skip if already caught by other methods
        guard lowA != lowB else {
            return nil
        }

        let distance = levenshteinDistance(lowA, lowB)
        let maxLength = max(lowA.count, lowB.count)

        // Only consider as typo if the strings are reasonably long and the distance is small
        guard maxLength >= 5 else {
            return nil
        }

        let ratio = 1.0 - (Double(distance) / Double(maxLength))

        if distance == 1 && maxLength >= 5 {
            return (0.8, "Possible typo (1 character difference)")
        }
        if distance == 2 && maxLength >= 8 {
            return (0.6, "Possible typo (2 character differences)")
        }
        if ratio >= 0.85 && maxLength >= 10 {
            return (0.5, "Similar names")
        }

        return nil
    }

    // MARK: - Helpers

    /// Normalizes a string by removing separators and lowercasing
    private static func normalizeMarkings(_ string: String) -> String {
        string
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ".", with: "")
            .lowercased()
    }

    /// Computes the Levenshtein edit distance between two strings
    private static func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        let aCount = aChars.count
        let bCount = bChars.count

        if aCount == 0 {
            return bCount
        }
        if bCount == 0 {
            return aCount
        }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: bCount + 1), count: aCount + 1)

        for i in 0...aCount { matrix[i][0] = i }
        for j in 0...bCount { matrix[0][j] = j }

        for i in 1...aCount {
            for j in 1...bCount {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }

        return matrix[aCount][bCount]
    }
}
