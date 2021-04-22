//
//  Dictionary+Util.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 4/2/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

extension Dictionary {

    mutating func updateOptionalValue(_ value: Value?, forKey key: Key) {
        if let unwrappedValue = value {
            self.updateValue(unwrappedValue, forKey: key)
        }
    }

    mutating func union(_ other: [Key: Value]) {
        for (k, v) in other {
            self.updateValue(v, forKey: k)
        }
    }
}
