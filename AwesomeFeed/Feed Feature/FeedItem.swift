//
//  FeedItem.swift
//  AwesomeFeed
//
//  Created by Edgar Hirama on 04/10/20.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}
