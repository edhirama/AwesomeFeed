//
//  RemoteFeedLoader.swift
//  AwesomeFeed
//
//  Created by Edgar Hirama on 05/10/20.
//

import Foundation

public enum HTTPResult {
    case success(HTTPURLResponse, Data)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPResult) -> Void)
}


public final class RemoteFeedLoader {

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    private let url: URL
    private let client: HTTPClient

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Error) -> Void) {
        client.get(from: url) { result  in
            switch result {
            case .success: completion(.invalidData)
            case .failure: completion(.connectivity)
            }
        }
    }
}
