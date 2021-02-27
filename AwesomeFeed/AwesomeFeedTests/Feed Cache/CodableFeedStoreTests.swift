//
//  CodableFeedStoreTests.swift
//  AwesomeFeedTests
//
//  Created by Edgar Hirama on 27/02/21.
//

import XCTest
import AwesomeFeed

class CodableFeedStore {
    func retrieve(completion: @escaping (RetrieveCachedFeedResult) -> Void) {
        completion(.empty)
    }
}

class CodableFeedStoreTests: XCTestCase {

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

}
