//
//  Array+Utils.swift
//  VerseInk
//
//  Created by Luciano Almeida on 1/26/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {

    @discardableResult
    mutating func removeObject(_ object: Iterator.Element) -> Iterator.Element? {
        if let idx = self.firstIndex(of: object) {
            return self.remove(at: idx)
        }
        return nil
    }

    mutating func removeObjects(_ objects: [Iterator.Element]) {
        for value in objects {
            self.removeObject(value)
        }
    }
}
