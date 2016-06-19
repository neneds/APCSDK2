//
//  Array+Utils.swift
//  VerseInk
//
//  Created by Luciano Almeida on 1/26/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

extension CollectionType where Generator.Element : Equatable, Self : _ArrayType{
    
    mutating func removeObject(object: Generator.Element) -> Generator.Element?{
        if let idx = self.indexOf(object) {
           return self.removeAtIndex(idx)
        }
        return nil
    }
    
    mutating func removeObjects(objects: [Generator.Element]) {
        for value in objects {
            self.removeObject(value)
        }
    }
}