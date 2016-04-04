//
//  APCProfile.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 4/3/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

public class APCProfile: NSObject, JsonConvertable{
    
    private(set) var aditionalFields: [String : AnyObject] = [:]
    //private var profileType: 
    
    
    //MARK:- JsonConvertable
    public required init(dictionary: [String : AnyObject]) {
        
    }
    
    func asDictionary() -> [String : AnyObject] {
        let dictionary : [String : AnyObject] = [:]
        
        return dictionary
    }
    
}


