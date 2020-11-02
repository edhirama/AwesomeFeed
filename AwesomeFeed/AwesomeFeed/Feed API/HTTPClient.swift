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
    func get(from url: URL, completion: @escaping (HTTPResult) -> Void)
}
