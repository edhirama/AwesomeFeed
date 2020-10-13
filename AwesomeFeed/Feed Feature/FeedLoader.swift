//
//  FeedLoader.swift
//  AwesomeFeed
//
//  Created by Edgar Hirama on 04/10/20.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
