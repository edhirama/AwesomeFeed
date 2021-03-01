//
//  HTTPClient.swift
//  AwesomeFeed
//
//  Created by Edgar Hirama on 12/10/20.
//

import Foundation

public enum HTTPResult {
    case success(HTTPURLResponse, Data)
    case failure(Error)
}

public protocol HTTPClient {
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func get(from url: URL, completion: @escaping (HTTPResult) -> Void)
}
