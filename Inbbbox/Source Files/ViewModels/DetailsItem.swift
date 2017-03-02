//
//  DetailsItem.swift
//  Inbbbox
//
//  Copyright © 2017 Netguru Sp. z o.o. All rights reserved.
//

import UIKit

class DetailsItem: GroupItem {

    enum Destination {
        case language
        case blockedUsers
    }

    var detailString: String

    var highlighted = false

    var destination: Destination?

    /// Initializes item with title and detailed string.
    ///
    /// - Parameters:
    ///   - title: Title
    ///   - detailString: Detailed string.
    init(title: String, detailString: String) {
        self.detailString = detailString
        super.init(title: title, category: .details)
    }
}
