//
//  String+Utils.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 6/28/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

extension String {
    
    static func concatStringsWithSeparator(strings strings: [String], separator: String) -> String? {
        if strings.isEmpty {
            return nil
        }
        var ret : String = ""
        for str in strings {
            ret.appendContentsOf(str)
            ret.appendContentsOf(separator)
        }
        
        if !ret.isEmpty {
            ret.removeAtIndex(ret.characters.endIndex)
        }
        
        return ret
    }
}

