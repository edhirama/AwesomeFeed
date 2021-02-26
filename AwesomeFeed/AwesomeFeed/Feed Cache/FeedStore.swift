//
//  FeedStore.swift
//  AwesomeFeed
//
//  Created by Edgar Hirama on 25/02/21.
//

import Foundation

public protocol FeedStore {
    func deleteCachedFeed(completion: @escaping (Error?) -> Void)
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping (Error?) -> Void)
    func retrieve()
}
