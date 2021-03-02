//
//  XCTestCase+FailableInsertionFeedStoreSpecs.swift
//  AwesomeFeedTests
//
//  Created by Edgar Hirama on 02/03/21.
//

import XCTest
import AwesomeFeed

 extension FailableInsertionFeedStoreSpecs where Self: XCTestCase {
     func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         let insertionError = insert((uniqueImageFeed().local, Date()), to: sut)

         XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error", file: file, line: line)
     }

     func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         insert((uniqueImageFeed().local, Date()), to: sut)

         expect(sut, toRetrieve: .empty, file: file, line: line)
     }
 }
