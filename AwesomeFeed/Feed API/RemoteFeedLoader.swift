//
//  RemoteFeedLoader.swift
//  AwesomeFeed
//
//  Created by Edgar Hirama on 05/10/20.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    public typealias Result = LoadFeedResult
    private let url: URL
    private let client: HTTPClient

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case let .success(response, data):
                completion(FeedItemsMapper.map(data, response))
            case .failure: completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }
}
