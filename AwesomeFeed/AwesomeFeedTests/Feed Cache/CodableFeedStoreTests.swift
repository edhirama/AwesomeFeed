//
//  CodableFeedStoreTests.swift
//  AwesomeFeedTests
//
//  Created by Edgar Hirama on 27/02/21.
//

import XCTest
import AwesomeFeed

class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {

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

        expect(sut, toRetrieveTwice: .empty)
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert((feed, timestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }

    func test_retrieve_fromNonEmptyCacheTwice_shouldReturnSameResult() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timestamp), to: sut)
        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }

    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        expect(sut, toRetrieve: .failure(anyNSError()))
    }

    func test_retrieve_twiceDeliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }

    func test_insert_shouldReturnInsertedValues() {
        let sut = makeSUT()
        let feed1 = uniqueImageFeed().local
        let timestamp1 = Date()

        insert((feed1, timestamp1), to: sut)

        expect(sut, toRetrieve: .found(feed: feed1, timestamp: timestamp1))
    }

    func test_insert_twice_shouldNotFailOnOverridingNonEmptyCache() {
        let sut = makeSUT()
        let feed1 = uniqueImageFeed().local
        let timestamp1 = Date()

        insert((feed1, timestamp1), to: sut)

        let feed2 = uniqueImageFeed().local
        let timestamp2 = Date()

        let insertionError2 = insert((feed2, timestamp2), to: sut)
        XCTAssertNil(insertionError2, "Should not fail on overriding non-empty cache")
    }

    func test_insert_twice_shouldOverrideNonEmptyCache() {
        let sut = makeSUT()
        let feed1 = uniqueImageFeed().local
        let timestamp1 = Date()

        insert((feed1, timestamp1), to: sut)

        let feed2 = uniqueImageFeed().local
        let timestamp2 = Date()

        insert((feed2, timestamp2), to: sut)
        expect(sut, toRetrieve: .found(feed: feed2, timestamp: timestamp2))
    }

    func test_insert_deliversFailureOnInsertionError() {
        let invalidStoreURL = URL(string: "invalidURL://store")
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        let exp = expectation(description: "Wait for insertion completion")
        sut.insert(feed, timestamp: timestamp) { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_insert_hasNoSideEffectsOnInsertionError() {
        let invalidStoreURL = URL(string: "invalidURL://store")
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        let exp = expectation(description: "Wait for insertion completion")
        sut.insert(feed, timestamp: timestamp) { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        expect(sut, toRetrieve: .empty)
    }

    func test_delete_emptyCacheShouldNotFail() {
        let sut = makeSUT()

        let deletionError = delete(from: sut)

        XCTAssertNil(deletionError, "Expected empty cache deletion to complete successfully")
    }

    func test_delete_emptyCacheShouldHaveNoSideEffects() {
        let sut = makeSUT()

        delete(from: sut)

        expect(sut, toRetrieve: .empty)
    }


    func test_delete_nonEmptyCacheRemovesPreviouslyInsertedValues() {
        let sut = makeSUT()

        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert((feed, timestamp), to: sut)

        let deletionError = delete(from: sut)
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to complete successfully")
        expect(sut, toRetrieve: .empty)
    }

    func test_delete_deliversFailureWhenDeletionFails() {
        let noDeletionPermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletionPermissionURL)

        let deletionError = delete(from: sut)

        XCTAssertNotNil(deletionError, "Expected cache deletion from location with no permission to fail")
        expect(sut, toRetrieve: .empty)
    }

    func test_delete_hasNoSideEffectsWhenDeletionFails() {
        let noDeletionPermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletionPermissionURL)

        delete(from: sut)

        expect(sut, toRetrieve: .empty)
    }

    func test_operationsShouldRunSerially() {
        let sut = makeSUT()

        var operations = [XCTestExpectation]()

        let op1 = expectation(description: "op1")
        sut.retrieve { _ in
            operations.append(op1)
            op1.fulfill()
        }

        let op2 = expectation(description: "op2")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            operations.append(op2)
            op2.fulfill()
        }

        let op3 = expectation(description: "op3")
        sut.retrieve { _ in
            operations.append(op3)
            op3.fulfill()
        }

        let op4 = expectation(description: "op4")
        sut.deleteCachedFeed { _ in
            operations.append(op4)
            op4.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        XCTAssertEqual(operations, [op1, op2, op3, op4])
    }

    // MARK: - Helpers

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let store = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(store, file: file, line: line)
        return store
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

    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
