//
//  Array+Utils.swift
//  VerseInk
//
//  Created by Luciano Almeida on 1/26/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

extension Collection where Iterator.Element : Equatable, Self : _ArrayType{
    
    mutating func removeObject(_ object: Iterator.Element) -> Iterator.Element?{
        if let idx = self.index(of: object) {
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
