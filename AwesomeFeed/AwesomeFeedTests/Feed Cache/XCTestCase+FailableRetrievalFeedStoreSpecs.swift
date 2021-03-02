//
//  XCTestCase+FailableRetrievalFeedStoreSpecs.swift
//  AwesomeFeedTests
//
//  Created by Edgar Hirama on 02/03/21.
//

import XCTest
import AwesomeFeed

 extension FailableRetrievalFeedStoreSpecs where Self: XCTestCase {
     func assertThatRetrieveDeliversFailureOnRetrievalError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         expect(sut, toRetrieve: .failure(anyNSError()), file: file, line: line)
     }

     func assertThatRetrieveHasNoSideEffectsOnFailure(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         expect(sut, toRetrieveTwice: .failure(anyNSError()), file: file, line: line)
     }
 }
