//
//  APCUserSession.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 4/2/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import UIKit


public class APCUserSession: NSObject, NSCoding {

    
    //MARK:- Properties
    public var currentUser: APCUser?
    public var sessionToken: String?
    public var expirationDate: NSDate?
    
    //MARK:- Computed Properties
    var isSessionExpired: Bool {
        return self.expirationDate?.earlierDate(NSDate()) == self.expirationDate
    }
    
    //MARK:- Initializers
    
    override private init() {
        super.init()
    }
    
    /**
     Initializes an user session with an user, a session token and an expiration date.
     - parameter user Session current user
     - parameter token Current session token
     - parameter expirationDate Expiration date for this session token.
     */
    convenience public init(user: APCUser, token: String, expirationDate: NSDate) {
        self.init()
        self.currentUser = user
        self.sessionToken = token
        self.expirationDate = expirationDate
        
    }
    
    
    //MARK:- NSCoding implementation
    required public init(coder aDecoder: NSCoder) {
        self.currentUser = aDecoder.decodeObjectForKey("current_user") as? APCUser
        self.expirationDate = aDecoder.decodeObjectForKey("expiration_date") as? NSDate
        self.sessionToken = aDecoder.decodeObjectForKey("session_token") as? String
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.currentUser, forKey: "current_user")
        aCoder.encodeObject(self.expirationDate, forKey: "expiration_date")
        aCoder.encodeObject(self.sessionToken, forKey: "session_token")
    }
    
    //MARK: Convenience methods
    
    //MARK:- Overrides
    public override var description: String  {
        return "currentUser = {\(self.currentUser)}, sessionToken = \(self.sessionToken), expirationDate = \(self.expirationDate)"
    }

}
