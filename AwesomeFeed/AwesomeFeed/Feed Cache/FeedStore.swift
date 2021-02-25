//
//  FeedStore.swift
//  AwesomeFeed
//
//  Created by Edgar Hirama on 25/02/21.
//

import Foundation

public protocol FeedStore {
    func deleteCachedFeed(completion: @escaping (Error?) -> Void)
    func insert(_ items: [LocalFeedItem], timestamp: Date, completion: @escaping (Error?) -> Void)
}

public struct LocalFeedItem: Equatable {
     public let id: UUID
     public let description: String?
     public let location: String?
     public let imageURL: URL

     public init(id: UUID, description: String?, location: String?, imageURL: URL) {
         self.id = id
         self.description = description
         self.location = location
         self.imageURL = imageURL
     }
 }
