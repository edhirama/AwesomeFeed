//
//  CodableFeedStoreTests.swift
//  AwesomeFeedTests
//
//  Created by Edgar Hirama on 27/02/21.
//

import XCTest
import AwesomeFeed

class CodableFeedStore {

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

    init(storeURL: URL) {
        self.storeURL = storeURL
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping (Error?) -> Void) {
        let encodedValues = try! JSONEncoder().encode(Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp))
        try! encodedValues.write(to: storeURL)
        completion(nil)
    }

    func retrieve(completion: @escaping (RetrieveCachedFeedResult) -> Void) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }

        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
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
        let store = makeSUT()
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
        let store = makeSUT()
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
        let store = makeSUT()
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

    // MARK: - Helpers

    func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let store = CodableFeedStore(storeURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store"))
        trackForMemoryLeaks(store, file: file, line: line)
        return store
    }

}
