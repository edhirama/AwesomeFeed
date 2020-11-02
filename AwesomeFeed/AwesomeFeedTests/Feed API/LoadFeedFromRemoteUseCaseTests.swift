//
//  RemoteFeedLoaderTests.swift
//  AwesomeFeedTests
//
//  Created by Edgar Hirama on 04/10/20.
//

import XCTest
import AwesomeFeed

class LoadFeedFromRemoteUseCaseTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssertNil(client.requestedURLs.first)
    }

    func test_load_requestDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadsTwice_requestsDataTwiceFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }
        sut.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()

        [199, 201, 300, 400, 500].enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData), when: {
                let jsonData = makeJSONWithItems(items: [])
                client.complete(with: code, data: jsonData, at: index)
            })
        }

    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidData() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: failure(.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(with: 200, data: invalidJSON)
        })
    }

    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: .success([]), when: {
            let emptyJSONData = makeJSONWithItems(items: [])
            client.complete(with: 200, data: emptyJSONData)
        })
    }

    func test_load_deliversItemsOn200HTTPResponseWithNonEmptyJSONList() {
        let item1 = makeItem(uuid: UUID(),
                             description: nil,
                             location: nil,
                             imageURL: URL(string: "http://a-url.com")!)


        let item2 = makeItem(uuid: UUID(),
                             description: "A description",
                             location: "A location",
                             imageURL: URL(string: "http://another-url.com")!)

        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: .success([item1.model, item2.model]), when: {
            client.complete(with: 200, data: makeJSONWithItems(items: [item1.json, item2.json]))
        })
    }

    func test_load_doesNotDeliverResultAfterSUTBeingDeallocated() {

        let url = URL(string: "http://any-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)

        var capturedResults: [RemoteFeedLoader.Result] = []
        sut?.load { capturedResults.append($0) }

        sut = nil
        client.complete(with: 200, data: makeJSONWithItems(items: []))
        XCTAssertEqual(capturedResults.count, 0)

    }
    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(client, file:  file, line: line)
        trackForMemoryLeaks(sut)
        return (sut, client)
    }

    private func makeItem(uuid: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let model = FeedItem(id: uuid, description: description, location: location, imageURL: imageURL)

        let json = ["id": uuid.uuidString,
                    "description": description,
                    "location": location,
        "image": imageURL.absoluteString].filter { $0.value?.isEmpty == false } as [String: Any]
        return (model, json)
    }

    private func makeJSONWithItems(items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        .failure(error)
    }

    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: RemoteFeedLoader.Result, when: () -> Void, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
        let loadExpectation = expectation(description: "Wait for load completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case let(.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result: \(expectedResult), received \(receivedResult) instead", file: file, line: line)
            }
            loadExpectation.fulfill()
        }
        when()
        wait(for: [loadExpectation], timeout: 1.0)
    }

    private class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        private var messages: [(url: URL, completion: (HTTPResult) -> Void)] = []

        func get(from url: URL, completion: @escaping (HTTPResult) -> Void) {
            messages.append((url, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }

        func complete(with statusCode: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index],
                                           statusCode: statusCode,
                                           httpVersion: nil,
                                           headerFields: nil)!
            messages[index].completion(.success(response, data))
        }
    }

}
