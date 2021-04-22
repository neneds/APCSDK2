//
//  String+Utils.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 6/28/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

extension String {
    
    static func concatStringsWithSeparator(strings: [String], separator: String) -> String? {
        if strings.isEmpty {
            return nil
        }
        var ret : String = ""
        for str in strings {
            ret.append(str)
            ret.append(separator)
        }
        
        if !ret.isEmpty {
            ret.remove(at: ret.endIndex)
        }
        
        return ret
    }
}

