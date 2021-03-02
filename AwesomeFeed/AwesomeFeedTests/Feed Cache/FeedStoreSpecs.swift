//
//  FeedStoreSpecs.swift
//  AwesomeFeedTests
//
//  Created by Edgar Hirama on 02/03/21.
//

import Foundation

protocol FeedStoreSpecs {
    func test_retrieve_fromEmptyCacheReturnsEmptyCache()

    func test_retrieveTwiceFromEmptyCache_returnsEmptyResultTwice()

    func test_retrieve_deliversFoundValuesOnNonEmptyCache()

    func test_retrieve_fromNonEmptyCacheTwice_shouldReturnSameResult()

    func test_insert_shouldReturnInsertedValues()
    func test_insert_twice_shouldNotFailOnOverridingNonEmptyCache()
    func test_insert_twice_shouldOverrideNonEmptyCache()


    func test_delete_emptyCacheShouldNotFail()
    func test_delete_emptyCacheShouldHaveNoSideEffects()
    func test_delete_nonEmptyCacheRemovesPreviouslyInsertedValues()

    func test_operationsShouldRunSerially()
}

protocol FailableRetrievalFeedStoreSpecs: FeedStoreSpecs {
    func test_retrieve_deliversFailureOnRetrievalError()
    func test_retrieve_twiceDeliversFailureOnRetrievalError()
}

protocol FailableInsertionFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_deliversFailureOnInsertionError()
    func test_insert_hasNoSideEffectsOnInsertionError()
}

protocol FailableDeletionFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_deliversFailureWhenDeletionFails()
    func test_delete_hasNoSideEffectsWhenDeletionFails()
}

typealias FailableFeedStoreSpecs = FailableRetrievalFeedStoreSpecs & FailableInsertionFeedStoreSpecs & FailableDeletionFeedStoreSpecs
