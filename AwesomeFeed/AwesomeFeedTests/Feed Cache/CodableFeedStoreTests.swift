//
//  CodableFeedStoreTests.swift
//  AwesomeFeedTests
//
//  Created by Edgar Hirama on 27/02/21.
//

import XCTest
import AwesomeFeed

class CodableFeedStore {
    private struct Cache: Codable {
        let feed: [LocalFeedImage]
        let timestamp: Date
    }

    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping (Error?) -> Void) {
        let encodedValues = try! JSONEncoder().encode(Cache(feed: feed, timestamp: timestamp))
        try! encodedValues.write(to: storeURL)
        completion(nil)
    }

    func retrieve(completion: @escaping (RetrieveCachedFeedResult) -> Void) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }

        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.feed, timestamp: cache.timestamp))
    }
}

class CodableFeedStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    override func tearDown() {
        super.tearDown()
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    func test_retrieve_fromEmptyCacheReturnsEmptyCache() {
        let store = CodableFeedStore()
        let exp = expectation(description: "Wait for retrieval")
        store.retrieve { result in
            switch result {
            case .empty:
                break
            default: XCTFail("Expected empty result, got \(result) instead")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieveTwiceFromEmptyCache_returnsEmptyResultTwice() {
        let store = CodableFeedStore()
        let exp = expectation(description: "Wait for retrieval")
        store.retrieve { firstResult in
            store.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default: XCTFail("Expected empty result, got \(secondResult) instead")
                }
                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieveAfterInsertingToEmptyCacheReturnsInsertedValues() {
        let store = CodableFeedStore()
        let feed = uniqueImageFeed()
        let timestamp = Date()
        let exp = expectation(description: "Wait for retrieval")
        store.insert(feed.local, timestamp: timestamp, completion: { error in
            store.retrieve { result in
                switch result {
                case .found(let retrievedFeed, let retrievedTimestamp):
                    XCTAssertEqual(feed.local, retrievedFeed)
                    XCTAssertEqual(retrievedTimestamp, timestamp)
                    break
                default: XCTFail("Expected found result, got \(result) instead")
                }
                exp.fulfill()
            }
        })
        wait(for: [exp], timeout: 1.0)
    }

}
