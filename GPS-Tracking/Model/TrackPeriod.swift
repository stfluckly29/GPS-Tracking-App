//
//  TrackPeriod.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/10/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import ObjectMapper

public enum TrackPeriodType: Int {
    case Unknown = 0
    case Movement = 1
    case Parking = 2
    case Break = 3
    case NoData = 4
    case Virtual = 5
}

public class TrackPeriod: Model, Hashable {
    public private(set) var id: String?
    public private(set) var periodType: TrackPeriodType?
    public private(set) var date: NSDate?
    public private(set) var begin: NSDate?
    public private(set) var end: NSDate?
    public private(set) var duration: NSTimeInterval?
    public private(set) var mileageKm: Double?
    public private(set) var averageSpeedKmh: Double?
    public private(set) var minimumSpeedKmh: Double?
    public private(set) var maximumSpeedKmh: Double?
    public var isPrivate: Bool?
    
    override public func mapping(map: Map) {
        super.mapping(map)
        
        id <- map["Id"]
        periodType <- (map["PeriodType"], RawRepresentableTransform())
        date <- (map["Date"], ServerDateTransform())
        begin <- (map["Begin"], ServerDateTransform())
        end <- (map["End"], ServerDateTransform())
        duration <- (map["Duration"], TimeIntervalTransform())
        mileageKm <- map["MileageKm"]
        averageSpeedKmh <- map["AverageSpeedKmh"]
        minimumSpeedKmh <- map["MinimumSpeedKmh"]
        maximumSpeedKmh <- map["MaximumSpeedKmh"]
        isPrivate <- map["IsPrivate"]
    }
    
    public init(begin: NSDate) {
        super.init()
        self.begin = begin
        self.periodType = .Movement
    }
    
    public required init?(_ map: Map) {
        super.init(map)
    }
    
    public var hashValue: Int { return begin?.timeIntervalSince1970.hashValue ?? 0 }
}

public func == (lhs: TrackPeriod, rhs: TrackPeriod) -> Bool {
    return lhs.hashValue == rhs.hashValue
}


