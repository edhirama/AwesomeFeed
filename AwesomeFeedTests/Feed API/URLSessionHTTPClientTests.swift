//
//  HTTPURLClientTests.swift
//  AwesomeFeedTests
//
//  Created by Edgar Hirama on 14/10/20.
//

import XCTest

class URLSessionHTTPClient {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func get(from url: URL) {
        session.dataTask(with: url) { (_, _, _) in }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {

    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "http://any-url.com")!
        let session = URLSessionSpy()
        let dataTask = URLSessionDataTaskSpy()
        session.stub(url, with: dataTask)
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url)
        XCTAssertEqual(dataTask.resumeCallCount, 1)
    }

    // MARK: - Helpers

    private class URLSessionSpy: URLSession {
        var stubs: [URL: URLSessionDataTask] = [:]

        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            return stubs[url] ?? FakeURLSessionDataTask()
        }

        func stub(_ url: URL, with dataTask: URLSessionDataTask) {
            stubs[url] = dataTask
        }
    }

    private class FakeURLSessionDataTask: URLSessionDataTask {}
    private class URLSessionDataTaskSpy: URLSessionDataTask {
        var resumeCallCount: Int = 0

        override func resume() {
            resumeCallCount += 1
        }
    }
}


