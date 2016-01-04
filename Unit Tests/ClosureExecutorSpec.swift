//
//  ClosureExecutorSpec.swift
//  Inbbbox
//
//  Created by Patryk Kaczmarek on 31/12/15.
//  Copyright © 2015 Netguru Sp. z o.o. All rights reserved.
//

import Quick
import Nimble

@testable import Inbbbox

class ClosureExecutorSpec: QuickSpec {
    override func spec() {
        
        var sut: ClosureExecutor!
        
        beforeEach {
            sut = ClosureExecutor()
        }
        
        afterEach {
            sut = nil
        }
        
        describe("when executing closure after delay") {
            
            var didExecuteClosure = false
            
            beforeEach {
                
                waitUntil { done in
                    sut.executeClosureOnMainThread(delay: 0.1, closure: {
                        didExecuteClosure = true
                        done()
                    })
                }
                
            }
            
            it("closure should be executed") {
                expect(didExecuteClosure).to(beTruthy())
            }
        }
    }
}