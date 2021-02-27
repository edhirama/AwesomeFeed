//
//  ValidateCacheUseCaseTests.swift
//  AwesomeFeedTests
//
//  Created by Edgar Hirama on 26/02/21.
//

import XCTest
import AwesomeFeed

class ValidateCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()

        sut.validateCache()
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }

    func test_validateCache_doesNotDeleteCacheWhenItsAlreadyEmpty() {
            let (sut, store) = makeSUT()

            sut.validateCache()
            store.completeRetrievalWithEmptyCache()

            XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_validateCache_doesNotDeleteNonExpiredCache() {
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = Date.init().minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT { fixedCurrentDate }
        sut.validateCache()
        store.completeRetrieval(with: uniqueImageFeed().local, timestamp: nonExpiredTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_validateCache_deletesCacheOnExpiration() {
        let fixedCurrentDate = Date()
        let expirationTimestamp = Date.init().minusFeedCacheMaxAge()
        let (sut, store) = makeSUT { fixedCurrentDate }
        sut.validateCache()
        store.completeRetrieval(with: uniqueImageFeed().local, timestamp: expirationTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }

    func test_validateCache_deletesMoreThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT { fixedCurrentDate }
        sut.validateCache()
        store.completeRetrieval(with: uniqueImageFeed().local, timestamp: expiredTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }

    func test_validateCache_doesNotDeleteInvalidCacheWhenInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        sut?.validateCache()
        sut = nil
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}
