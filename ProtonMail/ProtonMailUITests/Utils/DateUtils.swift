//
//  DateUtils.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 12.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import Foundation

extension Date {
 var millisecondsSince1970:Int {
        return Int((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}
