//
//  FeedCachePolicy.swift
//  AwesomeFeed
//
//  Created by Edgar Hirama on 27/02/21.
//

import Foundation

internal final class FeedCachePolicy {
    private init() {}
    private static var calendar = Calendar.init(identifier: .gregorian)
    private static var maxCacheAgeInDays: Int {
        return 7
    }

    internal static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else { return false }
        return date < maxCacheAge
    }
}
