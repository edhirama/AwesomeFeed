//
//  XCTestCase+Helpers.swift
//  AwesomeFeedTests
//
//  Created by Edgar Hirama on 29/10/20.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, file: file, line: line)
        }
    }
}
