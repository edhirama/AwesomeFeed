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

    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    private let url: URL
    private let client: HTTPClient

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result  in
            switch result {
            case let .success(response, data):
                if response.statusCode == 200, let root = try? JSONDecoder().decode(Root.self, from: data) {
                    completion(.success(root.items))
                } else {
                    completion(.failure(.invalidData))
                }
            case .failure: completion(.failure(.connectivity))
            }
        }
    }
}

struct Root: Decodable {
    let items: [FeedItem]
}
