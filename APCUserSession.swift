//
//  APCUserSession.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 4/2/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

public class APCUserSession: NSObject, NSCoding {

    // MARK: - Properties
    public var currentUser: APCUser?
    public var sessionToken: String?
    public var expirationDate: Date?

    // MARK: - Computed Properties
    public var isSessionExpired: Bool {
        return (self.expirationDate as NSDate?)?.earlierDate(Date()) == self.expirationDate
    }

    // MARK: - Initializers

    override fileprivate init() {
        super.init()
    }

    /**
     Initializes an user session with an user, a session token and an expiration date.
     - parameter user Session current user
     - parameter token Current session token
     - parameter expirationDate Expiration date for this session token.
     */
    convenience public init(user: APCUser, token: String, expirationDate: Date) {
        self.init()
        self.currentUser = user
        self.sessionToken = token
        self.expirationDate = expirationDate

    }

    // MARK: - NSCoding implementation
    required public init(coder aDecoder: NSCoder) {
        self.currentUser = aDecoder.decodeObject(forKey: "current_user") as? APCUser
        self.expirationDate = aDecoder.decodeObject(forKey: "expiration_date") as? Date
        self.sessionToken = aDecoder.decodeObject(forKey: "session_token") as? String
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.currentUser, forKey: "current_user")
        aCoder.encode(self.expirationDate, forKey: "expiration_date")
        aCoder.encode(self.sessionToken, forKey: "session_token")
    }

    // MARK: Convenience methods

    // MARK: - Overrides
    public override var description: String {
        return "currentUser = {\(String(describing: self.currentUser))}, sessionToken = \(String(describing: self.sessionToken)), expirationDate = \(String(describing: self.expirationDate))"
    }

}
