//
//  PeagableProvider.swift
//  Inbbbox
//
//  Created by Patryk Kaczmarek on 04/02/16.
//  Copyright © 2016 Netguru Sp. z o.o. All rights reserved.
//

import Foundation
import PromiseKit

enum PageableProviderError: ErrorType {
    case PageableBehaviourUndefined
}

class PageableProvider {
  
    private var nextPageableComponents = [PageableComponent]()
    private var previousPageableComponents = [PageableComponent]()
    
    func firstPageForQueries<T: Mappable>(queries: [Query]) -> Promise<[T]?> {
        return pageWithQueries(queries)
    }
    
    func nextPageFor<T: Mappable>(type: T.Type) -> Promise<[T]?> {
        return Promise<[T]?> { fulfill, reject in
            
            let queries = nextPageableComponents.map {
                PageableQuery(path: $0.path, queryItems: $0.queryItems)
            } as [Query]
            
            pageWithQueries(queries).then(fulfill).error(reject)
        }
    }
    
    func previousPageFor<T: Mappable>(type: T.Type) -> Promise<[T]?> {
        return Promise<[T]?> { fulfill, reject in
            
            let queries = previousPageableComponents.map {
                PageableQuery(path: $0.path, queryItems: $0.queryItems)
            } as [Query]
            
            pageWithQueries(queries).then(fulfill).error(reject)
        }
    }
    
    func resetPages() {
        nextPageableComponents = []
        previousPageableComponents = []
    }
}

private extension PageableProvider {
    
    func pageWithQueries<T: Mappable>(queries: [Query]) -> Promise<[T]?> {
        return Promise<[T]?> { fulfill, reject in
            
            let requests = queries.map { PageRequest(query: $0) }
            
            firstly {
                when(requests.map { $0.resume() })
            }.then { responses -> Void in
                
                self.nextPageableComponents = responses.filter { $0.pages.next != nil }.map { $0.pages.next! }
                self.previousPageableComponents = responses.filter { $0.pages.previous != nil }.map { $0.pages.previous! }
                
                let result = responses
                    .map { $0.json?.arrayValue.map { T.map($0) } }
                    .flatMap { $0 }
                    .flatMap { $0 }
                
                fulfill(result)
                
            }.error { _error in
                reject(_error)
            }
        }
    }
}
