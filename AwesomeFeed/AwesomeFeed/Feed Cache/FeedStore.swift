//
//  FeedStore.swift
//  AwesomeFeed
//
//  Created by Edgar Hirama on 25/02/21.
//

import Foundation

public protocol FeedStore {
    func deleteCachedFeed(completion: @escaping (Error?) -> Void)
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping (Error?) -> Void)
}
