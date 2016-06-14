//
//  APCManagerUtils.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 6/13/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import UIKit

class APCManagerUtils: NSObject {

    
    class func codFromLocation(location: String)-> Int? {
        let paths = location.componentsSeparatedByString("/")
        if let strCod = paths.last{
            if let cod = Int(strCod){
                return cod
            }
        }
        return nil
    }
}
