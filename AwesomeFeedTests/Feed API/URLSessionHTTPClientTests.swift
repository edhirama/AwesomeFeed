//
//  HTTPURLClientTests.swift
//  AwesomeFeedTests
//
//  Created by Edgar Hirama on 14/10/20.
//

import XCTest
import AwesomeFeed

class URLSessionHTTPClientTests: XCTestCase {

    override func setUp() {
        URLProtocolStub.startIntercepting()
    }

    override func tearDown() {
        URLProtocolStub.stopIntercepting()
    }

    func test_getFromURL_performsGETRequestWithCorrectURL() {
        let url = anyURL()

        let exp = expectation(description: "wait for request")
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }

        makeSUT().get(from: url) { _ in }

        wait(for: [exp], timeout: 1.0)
    }

    func test_getFromURL_failsOnRequestError() {
        let requestError = anyNSError()
        let receivedError = requestErrorFor(data: nil, response: nil, error: requestError)
       XCTAssertEqual(receivedError as NSError?, requestError)
    }

    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(requestErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(requestErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(requestErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(requestErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(requestErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(requestErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(requestErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(requestErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(requestErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }

    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let response = anyHTTPURLResponse()
        let data = anyData()
        let receivedValues = requestValuesFor(data: data, response: response, error: nil)

        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)

    }

    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse()
        let receivedValues = requestValuesFor(data: nil, response: response, error: nil)
        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func anyData() -> Data {
        return Data("any data".utf8)
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }

    private func requestValuesFor(data: Data?, response: URLResponse?, error: Error?) -> (data: Data, response: HTTPURLResponse)? {
        let result = requestResultFor(data: data, response: response, error: error)
        switch result {
            case let .success(response, data):
                return (data, response)
            default: return nil
        }
    }

    private func requestErrorFor(data: Data?, response: URLResponse?, error: Error?) -> Error? {
        let result = requestResultFor(data: data, response: response, error: error)
        switch result {
        case let .failure(receivedError as NSError):
            return receivedError
        default: return nil
        }
    }

    private func requestResultFor(data: Data?, response: URLResponse?, error: Error?) -> HTTPResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let exp = expectation(description: "Wait for completion")
        var capturedResult: HTTPResult!
        makeSUT().get(from: anyURL()) { result in
            capturedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        return capturedResult
    }


    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }

    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?

        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }

        static func observeRequest(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }

        static func startIntercepting() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopIntercepting() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }

        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            guard let stub = URLProtocolStub.stub else { return }

            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}


