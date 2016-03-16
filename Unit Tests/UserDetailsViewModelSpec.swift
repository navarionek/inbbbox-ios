//
//  UserDetailsViewModelSpec.swift
//  Inbbbox
//
//  Created by Peter Bruz on 15/03/16.
//  Copyright © 2016 Netguru Sp. z o.o. All rights reserved.
//

import Quick
import Nimble
import PromiseKit
import Dobby

@testable import Inbbbox

class UserDetailsViewModelSpec: QuickSpec {
    
    override func spec() {
        
        var sut: UserDetailsViewModelMock!
        let fixtureImageURL = NSURL(string: "https://fixture.domain/fixture.image.normal.png")
        var connectionsRequesterMock: APIConnectionsRequesterMock!
        
        beforeEach {
            sut = UserDetailsViewModelMock(user: User.fixtureUser())
            connectionsRequesterMock = APIConnectionsRequesterMock()
            sut.connectionsRequester = connectionsRequesterMock
            connectionsRequesterMock.isUserFollowedByMeStub.on(any()) { _ in
                return Promise(true)
            }
            
            connectionsRequesterMock.followUserStub.on(any()) { _ in
                return Promise()
            }
            
            connectionsRequesterMock.unfollowUserStub.on(any()) { _ in
                return Promise()
            }
        }
        
        afterEach {
            sut = nil
        }
        
        describe("when newly initialized") {
            
            it("user should be correctly allocated") {
                expect(sut.user.identifier).to(equal(User.fixtureUser().identifier))
            }
            
            it("should have proper number of shots") {
                expect(sut.itemsCount).to(equal(0))
            }
        }
        
        describe("when downloading initial data") {
            
            beforeEach {
                sut.downloadInitialItems()
            }
            
            it("should have proper number of shots") {
                expect(sut.itemsCount).to(equal(2))
            }
            
            it("should return proper cell data for index path") {
                let indexPath = NSIndexPath(forRow: 0, inSection: 0)
                let cellData = sut.shotCollectionViewCellViewData(indexPath)
                expect(cellData.animated).to(equal(true))
                expect(cellData.imageURL).to(equal(fixtureImageURL))
            }
        }
        
        describe("When downloading data for next page") {
            
            beforeEach {
                sut.downloadItemsForNextPage()
            }
            
            it("should have proper number of shots") {
                expect(sut.itemsCount).to(equal(3))
            }
            
            it("should return proper shot data for index path") {
                let indexPath = NSIndexPath(forRow: 0, inSection: 0)
                let cellData = sut.shotCollectionViewCellViewData(indexPath)
                expect(cellData.animated).to(equal(true))
                expect(cellData.imageURL).to(equal(fixtureImageURL))
            }
        }
        
        describe("when checking if logged user follows an user") {
            
            var didReceiveResponse: Bool?
            
            beforeEach {
                didReceiveResponse = false
                
                waitUntil { done in
                    sut.isUserFollowedByMe().then { result -> Void in
                        didReceiveResponse = true
                        done()
                    }.error { _ in fail("This should not be invoked") }
                }
            }
            
            afterEach {
                didReceiveResponse = nil
            }
            
            it("should be correctly checked") {
                expect(didReceiveResponse).to(beTruthy())
                expect(didReceiveResponse).toNot(beNil())
            }
        }
        
        describe("when following an user") {
            
            var didReceiveResponse: Bool?
            
            beforeEach {
                didReceiveResponse = false
                
                waitUntil { done in
                    sut.followUser().then { result -> Void in
                        didReceiveResponse = true
                        done()
                    }.error { _ in fail("This should not be invoked") }
                }
            }
            
            afterEach {
                didReceiveResponse = nil
            }
            
            it("should be correctly followed") {
                expect(didReceiveResponse).to(beTruthy())
                expect(didReceiveResponse).toNot(beNil())
            }
        }
        
        describe("when unfollowing an user") {
            
            var didReceiveResponse: Bool?
            
            beforeEach {
                didReceiveResponse = false
                
                waitUntil { done in
                    sut.unfollowUser().then { result -> Void in
                        didReceiveResponse = true
                        done()
                    }.error { _ in fail("This should not be invoked") }
                }
            }
            
            afterEach {
                didReceiveResponse = nil
            }
            
            it("should be correctly unfollowed") {
                expect(didReceiveResponse).to(beTruthy())
                expect(didReceiveResponse).toNot(beNil())
            }
        }
    }
}

//Explanation: Create UserDetailsViewModelMock to override methods from BaseCollectionViewViewModel.

private class UserDetailsViewModelMock: UserDetailsViewModel {

    override func downloadInitialItems() {
        let shot = Shot.fixtureShot()
        userShots = [shot, shot]
    }
    
    override func downloadItemsForNextPage() {
        let shot = Shot.fixtureShot()
        userShots = [shot, shot, shot]
    }
}
