//
//  ShotDetailsViewModel.swift
//  Inbbbox
//
//  Created by Peter Bruz on 18/02/16.
//  Copyright © 2016 Netguru Sp. z o.o. All rights reserved.
//

import Foundation
import PromiseKit

final class ShotDetailsViewModel {
    
    let shot: ShotType
    
    var commentsProvider = APICommentsProvider(page: 1, pagination: 20)
    var commentsRequester = APICommentsRequester()
    var bucketsRequester = APIBucketsRequester()
    var shotsRequester =  ShotsRequester()
    
    var itemsCount: Int {
        
        var counter = Int(1) //for ShotDetailsOperationCollectionViewCell
        if let description = shot.attributedDescription where description.string.characters.count > 0 {
            counter++
        }
        if hasCommentsToFetch {
            counter += comments.count
        }
        
        return counter
    }
    
    private var comments = [CommentType]()
    private var userBucketsForShot = [BucketType]()
    private var isShotLikedByMe: Bool?
    private var userBucketsForShotCount: Int?
    
    init(shot: ShotType) {
        self.shot = shot
    }
    
    func isDescriptionIndex(index: Int) -> Bool {
        if let description = shot.attributedDescription where description.length > 0 && index == 1 {
            return true
        }
        return false
    }
    
    func isShotOperationIndex(index: Int) -> Bool {
        return index == 0
    }
    
    func isCurrentUserOwnerOfCommentAtIndex(index: Int) -> Bool {
        
        let comment = comments[indexInCommentArrayBasedOnItemIndex(index)]
        return UserStorage.currentUser?.identifier == comment.user.identifier
    }
}

// MARK: Data formatting
extension ShotDetailsViewModel {
    
    var attributedShotTitleForHeader: NSAttributedString {
        return ShotDetailsFormatter.attributedStringForHeaderFromShot(shot)
    }
    
    var attributedShotDescription: NSAttributedString? {
        return ShotDetailsFormatter.attributedShotDescriptionFromShot(shot)
    }
    
    func displayableDataForCommentAtIndex(index: Int) -> (author: String, comment: NSAttributedString?, date: String, avatarURLString: String) {
        
        let comment = comments[indexInCommentArrayBasedOnItemIndex(index)]
        
        return (
            author: comment.user.name ?? comment.user.username,
            comment: ShotDetailsFormatter.attributedCommentBodyForComment(comment),
            date: ShotDetailsFormatter.commentDateForComment(comment),
            avatarURLString: comment.user.avatarString ?? ""
        )
    }
}

// MARK: Likes handling
extension ShotDetailsViewModel {
    
    func performLikeOperation() -> Promise<Bool> {
        return Promise<Bool> { fulfill, reject in
            
            let like = !isShotLikedByMe!
            
            firstly {
                like ? shotsRequester.likeShot(shot) : shotsRequester.unlikeShot(shot)
            }.then { _ -> Void in
                self.isShotLikedByMe = like
                fulfill(like)
            }.error(reject)
        }
    }
    
    func checkLikeStatusOfShot() -> Promise<Bool> {
        
        if let isShotLikedByMe = isShotLikedByMe {
            return Promise(isShotLikedByMe)
        }
        
        return Promise<Bool> { fulfill, reject in
            
            firstly {
                shotsRequester.isShotLikedByMe(shot)
            }.then { isShotLikedByMe -> Void in
                self.isShotLikedByMe = isShotLikedByMe
                fulfill(isShotLikedByMe)
            }.error(reject)
        }
    }
}

// MARK: Buckets handling
extension ShotDetailsViewModel {
    
    func checkShotAffiliationToUserBuckets() -> Promise<Bool> {
        return Promise<Bool> { fulfill, reject in

            firstly {
                checkNumberOfUserBucketsForShot()
            }.then { number -> Void in
                fulfill(Bool(number))
            }.error(reject)
        }
    }
    
    func checkNumberOfUserBucketsForShot() -> Promise<Int> {
        
        if let userBucketsForShotCount = userBucketsForShotCount {
            return Promise(userBucketsForShotCount)
        }
        
        return Promise<Int> { fulfill, reject in
            
            firstly {
                shotsRequester.userBucketsForShot(shot)
            }.then { buckets -> Void in
                self.userBucketsForShot = buckets
                self.userBucketsForShotCount = self.userBucketsForShot.count
                fulfill(self.userBucketsForShotCount!)
            }.error(reject)
        }
    }
    
    func clearBucketsData() {
        userBucketsForShotCount = nil
        userBucketsForShot = []
    }
    
    func removeShotFromBucketIfExistsInExactlyOneBucket() -> Promise<(removed: Bool, bucketsNumber: Int?)> {
        return Promise<(removed: Bool, bucketsNumber: Int?)> { fulfill, reject in
            
            var numberOfBuckets: Int?
            
            firstly {
                checkNumberOfUserBucketsForShot()
            }.then { number -> Void in
                numberOfBuckets = number
                if numberOfBuckets == 1 {
                    self.bucketsRequester.removeShot(self.shot, fromBucket: self.userBucketsForShot[0])
                }
            }.then { () -> Void in
                if numberOfBuckets == 1 {
                    self.clearBucketsData()
                    fulfill((removed: true, bucketsNumber: nil))
                } else {
                    fulfill((removed: false, bucketsNumber: numberOfBuckets))
                }
            }.error(reject)
        }
    }
}

// MARK: Comments handling
extension ShotDetailsViewModel {
    
    private var commentsCount: Int {
        return comments.count
    }
    
    private var hasCommentsToFetch: Bool {
        return shot.commentsCount != 0
    }
    
    var isCommentingAvailable: Bool {
        if let accountType = UserStorage.currentUser?.accountType {
            return accountType == .Player || accountType == .Team
        }
        return  false
    }

    func loadComments() -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            
            if comments.count == 0 {
                firstly {
                    commentsProvider.provideCommentsForShot(shot)
                }.then { comments -> Void in
                    self.comments = comments ?? []
                }.then(fulfill).error(reject)
                
            } else {
                
                firstly {
                    commentsProvider.nextPage()
                }.then { comments -> Void in
                    if let comments = comments {
                        self.appendCommentsAndUpdateCollectionView(comments)
                    }
                }.then(fulfill).error(reject)
            }
        }
    }
    
    func postComment(message: String) -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            
            firstly {
                commentsRequester.postCommentForShot(shot, withText: message)
            }.then { comment in
                self.comments.append(comment)
            }.then(fulfill).error(reject)
        }
    }
    
    func deleteCommentAtIndex(index: Int) -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            
            let comment = comments[indexInCommentArrayBasedOnItemIndex(index)]
            
            firstly {
                commentsRequester.deleteComment(comment, forShot: shot)
            }.then { comment in
                self.comments.removeAtIndex(self.indexInCommentArrayBasedOnItemIndex(index))
            }.then { _ in
                fulfill()
            }.error(reject)
        }
    }
}

private extension ShotDetailsViewModel {
    
    // Comments methods
    func appendCommentsAndUpdateCollectionView(comments: [CommentType]) {
        
        let currentCommentCount = self.comments.count
        let possibleLoadMoreCellIndexPath:NSIndexPath? =  {
            if commentsCount < itemsCount {
                return NSIndexPath(forItem: currentCommentCount, inSection: 0)
            } else {
                return nil
            }
        }()
        
        var indexPathsToInsert = [NSIndexPath]()
        var indexPathsToReload = [NSIndexPath]()
        var indexPathsToDelete = [NSIndexPath]()
        
        self.comments.appendContentsOf(comments)
        
        for i in currentCommentCount..<self.comments.count {
            indexPathsToInsert.append(NSIndexPath(forItem: i, inSection: 0))
        }
        if let loadMoreCellIndexPath = possibleLoadMoreCellIndexPath {
            if self.comments.count < Int(shot.commentsCount) {
                indexPathsToReload.append(loadMoreCellIndexPath)
            } else {
                indexPathsToDelete.append(loadMoreCellIndexPath)
            }
        }
    }
    
    func indexInCommentArrayBasedOnItemIndex(index: Int) -> Int {
        return comments.count - itemsCount + index
    }
}
