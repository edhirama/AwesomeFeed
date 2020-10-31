//
//  URLSessionHTTPClient.swift
//  AwesomeFeed
//
//  Created by Edgar Hirama on 31/10/20.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    private struct UnexpectedValuesError: Error {}
    public func get(from url: URL, completion: @escaping (HTTPResult) -> Void) {
        session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(response, data))
            } else {
                completion(.failure(UnexpectedValuesError()))
            }

        }.resume()
    }
}
