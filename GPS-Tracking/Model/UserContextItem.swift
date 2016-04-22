//
//  UserContextItem.swift
//  LoadSetGPS
//
//  Created by Stefan on 1/29/16.
//  Copyright © 2016 Realine. All rights reserved.
//

import Foundation
import ObjectMapper

public class UserContextItem: Model {
    public private(set) var name: String?
    public private(set) var globalMasterId: String?
    public private(set) var globalIndexId: String?
    public private(set) var imageLink: String?
    public private(set) var website: String?
    public private(set) var city: String?
    public private(set) var country: String?
    public private(set) var state: String?
    public private(set) var postalCode: String?
    public var sharingEnabled: Bool?
    
    override public func mapping(map: Map) {
        super.mapping(map)
        
        name <- map["Name"]
        globalMasterId <- map["GlobalMasterId"]
        globalIndexId <- map["GlobalIndexId"]
        imageLink <- map["ImageLink"]
        website <- map["Website"]
        city <- map["City"]
        country <- map["Country"]
        state <- map["State"]
        postalCode <- map["PostalCode"]
        sharingEnabled <- map["SharingEnabled"]
    }
}

