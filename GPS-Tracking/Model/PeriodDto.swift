//
//  PeriodDto.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/22/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import ObjectMapper


public class PeriodDto: Model, Hashable {
    public private(set) var periodType: TrackPeriodType?
    public private(set) var begin: NSDate?
    public private(set) var end: NSDate?
    public private(set) var duration: NSTimeInterval?
    public var selected = false
    public var points: [TrackPointDto] = []
    
    override public func mapping(map: Map) {
        super.mapping(map)
        
        periodType <- (map["TrackPeriodType"], RawRepresentableTransform())
        begin <- (map["Begin"], ServerDateTransform())
        end <- (map["End"], ServerDateTransform())
        duration <- (map["Duration"], TimeIntervalTransform())
        points <- map["Points"]
    }    
    
    public var hashValue: Int { return begin?.timeIntervalSince1970.hashValue ?? 0 }
}

public func == (lhs: PeriodDto, rhs: PeriodDto) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
