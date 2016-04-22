//
//  BlackoutZoneModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/24/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import ObjectMapper


public class BlackoutZoneModel: Model {
    public var id: String?
    public var centerLatitude: Double?
    public var centerLongitude: Double?
    public var radiusKm: Double?
    public var name: String?
    
    
    override public func mapping(map: Map) {
        super.mapping(map)
        
        id <- map["Id"]
        centerLatitude <- map["CenterLatitude"]
        centerLongitude <- map["CenterLongitude"]
        radiusKm <- map["RadiusKm"]
        name <- map["Name"]
    }
}