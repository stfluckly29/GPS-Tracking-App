//
//  DayTrackPeriod.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/10/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import ObjectMapper

public class DayTrackPeriod: Model {
    public private(set) var id: String?
    public private(set) var date: NSDate?
    public private(set) var duration: NSTimeInterval?
    public private(set) var mileageKm: Double?
    public private(set) var averageSpeedKmh: Double?
    public private(set) var minimumSpeedKmh: Double?
    public private(set) var maximumSpeedKmh: Double?
    public private(set) var periods: [TrackPeriod] = []
    
    override public func mapping(map: Map) {
        super.mapping(map)
        
        id <- map["Id"]
        date <- (map["Date"], ServerDateTransform())
        duration <- (map["Duration"], TimeIntervalTransform())
        mileageKm <- map["MileageKm"]
        averageSpeedKmh <- map["AverageSpeedKmh"]
        minimumSpeedKmh <- map["MinimumSpeedKmh"]
        maximumSpeedKmh <- map["MaximumSpeedKmh"]
        periods <- map["Periods"]
    }
    
}
