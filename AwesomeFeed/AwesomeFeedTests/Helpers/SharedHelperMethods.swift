//
//  SharedHelperMethods.swift
//  AwesomeFeedTests
//
//  Created by Edgar Hirama on 26/02/21.
//

import Foundation
import AwesomeFeed

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

func anyURL() -> URL {
    URL(string: "http://any-url.com")!
}
