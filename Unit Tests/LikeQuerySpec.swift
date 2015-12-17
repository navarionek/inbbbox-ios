//
//  LikeQuerySpec.swift
//  Inbbbox
//
//  Created by Radoslaw Szeja on 17/12/15.
//  Copyright © 2015 Netguru Sp. z o.o. All rights reserved.
//

import Quick
import Nimble

import Inbbbox

@testable import Inbbbox

class LikeQuerySpec: QuickSpec {
    override func spec() {
        
        describe("when newly initialized with shot identifier") {
            
            var sut: LikeQuery!
            
            beforeEach {
                sut = LikeQuery(shotID: "fixture.identifier")
            }
            
            it("should have post method") {
                expect(sut.method.rawValue).to(equal(Method.POST.rawValue))
            }
            
            it("should have path with identifier") {
                expect(sut.path).to(equal("/shots/fixture.identifier/like"))
            }
            
            it("should have dribbble service") {
                expect(sut.service is DribbbleNetworkService).to(beTrue())
            }
            
            it("should have parameters with URL encoding") {
                expect(sut.parameters.encoding).to(equal(Parameters.Encoding.URL))
            }
            
            it("should have empty parameters") {
                expect(sut.parameters.queryItems).to(beEmpty())
            }
            
        }
        
    }
}
