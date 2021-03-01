//
//  CodableFeedStore.swift
//  AwesomeFeedTests
//
//  Created by Edgar Hirama on 01/03/21.
//

import Foundation
import AwesomeFeed

public class CodableFeedStore: FeedStore {

    private struct CodableFeedImage: Codable {
        public let id: UUID
        public let description: String?
        public let location: String?
        public let url: URL

        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }

        var local: LocalFeedImage {
            return  LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }

    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date

        var localFeed: [LocalFeedImage] {
            feed.map { $0.local }
        }
    }

    private let storeURL: URL

    private let queue = DispatchQueue(label: "\(CodableFeedStore.self)Queue", qos: .userInitiated, attributes: .concurrent)

    public init(storeURL: URL) {
        self.storeURL = storeURL
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping (Error?) -> Void) {
        queue.async(flags: .barrier) { [storeURL] in
            do {
                let encodedValues = try JSONEncoder().encode(Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp))
                try encodedValues.write(to: storeURL)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    public func retrieve(completion: @escaping (RetrieveCachedFeedResult) -> Void) {
        queue.async { [storeURL] in
            guard let data = try? Data(contentsOf: storeURL) else {
                return completion(.empty)
            }

            let decoder = JSONDecoder()
            do {
                let cache = try decoder.decode(Cache.self, from: data)
                completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func deleteCachedFeed(completion: @escaping (Error?) -> Void) {
        queue.async(flags: .barrier) { [storeURL] in
            guard FileManager.default.fileExists(atPath: storeURL.path) else {
                return completion(nil)
            }
            do {
                try FileManager.default.removeItem(at: storeURL)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}
