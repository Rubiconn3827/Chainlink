//
//  MessageObject.swift
//  Chainlink
//
//  Created by AJ Priola on 6/30/15.
//  Copyright © 2015 AJ Priola. All rights reserved.
//

import Foundation

class MessageObject: NSObject, NSCoding {
    let message:String?
    let from:String!
    let image:NSData?
    let id:Int!
    
    required init?(coder aDecoder: NSCoder) {
        self.message = aDecoder.decodeObjectForKey("message") as? String
        self.from = aDecoder.decodeObjectForKey("from") as? String
        self.id = aDecoder.decodeObjectForKey("id") as? Int
        self.image = aDecoder.decodeObjectForKey("image") as? NSData
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(message, forKey: "message")
        aCoder.encodeObject(from, forKey: "from")
        aCoder.encodeObject(id, forKey: "id")
        aCoder.encodeObject(image, forKey: "image")
    }
    
    init(message:String, from:String) {
        self.message = message
        self.from = from
        self.image = nil
        id = Int(arc4random())
    }
    
    init(withImageData:NSData, from:String) {
        self.message = nil
        self.from = from
        self.image = withImageData
        self.id = Int(arc4random())
    }
    
    func toData() -> NSData {
        if self.message == nil {
            let dictionary:NSDictionary = ["from":from,"image":image!,"id":id]
            return NSKeyedArchiver.archivedDataWithRootObject(dictionary as NSDictionary)
        } else {
            let dictionary:NSDictionary = ["message":message!,"from":from,"id":id]
            return NSKeyedArchiver.archivedDataWithRootObject(dictionary as NSDictionary)
        }
        
    }
}