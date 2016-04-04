//
//  JsonConverteble.swift
//  VerseInk
//
//  Created by Luciano Almeida on 12/7/15.
//  Copyright © 2015 Luciano Almeida. All rights reserved.
//

import Foundation

@objc protocol JsonConvertable {
    init(dictionary: [String : AnyObject])
    optional func asDictionary() -> [String : AnyObject]
}