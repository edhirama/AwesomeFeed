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
        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }

    func test_retrieve_fromEmptyCacheReturnsEmptyCache() {
        let sut = makeSUT()
        expect(sut, toRetrieve: .empty)
    }

    func test_retrieveTwiceFromEmptyCache_returnsEmptyResultTwice() {
        let sut = makeSUT()

        expect(sut, toRetrieve: .empty)
        expect(sut, toRetrieve: .empty)
    }

    func test_retrieveAfterInsertingToEmptyCacheReturnsInsertedValues() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        let exp = expectation(description: "Wait for retrieval")
        sut.insert(feed, timestamp: timestamp, completion: { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            exp.fulfill()

        })
        wait(for: [exp], timeout: 1.0)

        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }

    func test_retrieve_fromNonEmptyCacheTwice_shouldReturnSameResult() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        let exp = expectation(description: "Wait for retrieval")
        sut.insert(feed, timestamp: timestamp, completion: { error in

                    exp.fulfill()

        })

        wait(for: [exp], timeout: 1.0)

        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let store = CodableFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(store, file: file, line: line)
        return store
    }

    private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for retrieval")
        sut.retrieve { retrievedResult in
            switch (retrievedResult, expectedResult) {
            case (.empty, .empty):
                break
            case let (.found(retrievedFeed, retrievedTimestamp), .found(expectedFeed, expectedTimestamp)):
                XCTAssertEqual(retrievedFeed, expectedFeed, file: file, line: line)
                XCTAssertEqual(retrievedTimestamp, expectedTimestamp, file: file, line: line)
            default: XCTFail("Expected \(expectedResult) result, got \(retrievedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }

    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }

    private func testSpecificStoreURL() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}
