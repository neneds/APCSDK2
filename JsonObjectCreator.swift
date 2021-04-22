//
//  JsonObjectCreator.swift
//  VerseInk
//
//  Created by Luciano Almeida on 12/7/15.
//  Copyright © 2015 Luciano Almeida. All rights reserved.
//

import Foundation

class JsonObjectCreator: NSObject {

    class func create(jsonData: NSData, objectClass: JsonConvertable.Type) -> [AnyObject]? {
        do {
            if let deserializedData = try JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [[String: AnyObject]] {

                return self.create(dictionaryArray: deserializedData, objectClass: objectClass)
            }
        } catch let error {
            print("\(error)")
        }

        return nil
    }

    class func createObject(jsonData: NSData, objectClass: JsonConvertable.Type) -> AnyObject? {
        if let deserializedData = try? JSONSerialization.jsonObject(with: jsonData as Data, options: .mutableContainers) as? [String: AnyObject] {
            return objectClass.init(dictionary: deserializedData)
        }

        return nil
    }

   class func create(dictionaryArray: [[String: AnyObject]], objectClass: JsonConvertable.Type) -> [AnyObject]? {
        var array: [JsonConvertable] = []
        for value in dictionaryArray {
            let object = objectClass.init(dictionary: value)
            array.append(object)
        }
        return array
    }

    class func createObject(dictionary: [String: AnyObject], objectClass: JsonConvertable.Type) -> AnyObject? {
        return objectClass.init(dictionary: dictionary)
    }
}
