//
//  FeedLoader.swift
//  AwesomeFeed
//
//  Created by Edgar Hirama on 04/10/20.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}


