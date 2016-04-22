//
//  TrackPeriodDto.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/22/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import ObjectMapper

public class TrackPointDto: Model {
    public private(set) var timestamp: NSDate?
    public private(set) var latitude: Double?
    public private(set) var longitude: Double?
    public private(set) var speed: Double?
    
    override public func mapping(map: Map) {
        super.mapping(map)
        
        timestamp <- (map["Timestamp"], ServerDateTransform())
        latitude <- map["Latitude"]
        longitude <- map["Longitude"]
        speed <- map["Speed"]
    }
    
}
