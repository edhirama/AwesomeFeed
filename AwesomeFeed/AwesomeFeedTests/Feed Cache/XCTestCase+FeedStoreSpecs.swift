//
//  XCTestCase+FeedStoreSpecs.swift
//  AwesomeFeedTests
//
//  Created by Edgar Hirama on 02/03/21.
//

import XCTest
import AwesomeFeed

extension FeedStoreSpecs where Self: XCTestCase {

    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }

    func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for retrieval")
        sut.retrieve { retrievedResult in
            switch (retrievedResult, expectedResult) {
            case (.empty, .empty),
                 (.failure, .failure):
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

    @discardableResult
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore, file: StaticString = #file, line: UInt = #line) -> Error? {
        let exp = expectation(description: "Wait for retrieval")
        var receivedError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp, completion: { insertionError in
            receivedError = insertionError
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            exp.fulfill()
        })

        wait(for: [exp], timeout: 1.0)
        return receivedError
    }

    @discardableResult
    func delete(from sut: FeedStore, file: StaticString = #file, line: UInt = #line) -> Error? {

        let exp = expectation(description: "Wait for deletion completion")

        var deletionError: Error?
        sut.deleteCachedFeed { error in
            deletionError = error
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        return deletionError
    }

}
