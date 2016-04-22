//
//  GpsPointSimpleModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/22/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation

import ObjectMapper

public class GpsPointSimpleModel: Model {
    public private(set) var gpsCaptureDate: NSDate?
    public private(set) var receiptTime: NSDate?
    public private(set) var submissionDateTime: NSDate?
    public private(set) var gpsFixTime: NSDate?

    public private(set) var satelliteCount: Int?
    public private(set) var direction: Int?
    
    public private(set) var altitude: Double?
    public private(set) var latitude: Double?
    public private(set) var longitude: Double?
    public private(set) var speed: Double?
    public private(set) var accuracy: Double?
    
    override public func mapping(map: Map) {
        super.mapping(map)
        
        gpsCaptureDate <- (map["GpsCaptureDate"], ServerDateTransform())
        receiptTime <- (map["ReceiptTime"], ServerDateTransform())
        submissionDateTime <- (map["SubmissionDateTime"], ServerDateTransform())
        gpsFixTime <- (map["GpsFixTime"], ServerDateTransform())
        satelliteCount <- map["SatelliteCount"]
        direction <- map["Direction"]
        altitude <- map["Altitude"]
        latitude <- map["Latitude"]
        longitude <- map["Longitude"]
        speed <- map["Speed"]
        accuracy <- map["Accuracy"]
    }
    
    public init(location: Location) {
        super.init()
        gpsCaptureDate =  NSDate.init(timeIntervalSinceReferenceDate: location.timestamp)
        receiptTime = NSDate.init(timeIntervalSinceReferenceDate: location.timestamp)
        submissionDateTime = NSDate()
        gpsFixTime = NSDate.init(timeIntervalSinceReferenceDate: location.timestamp)
        latitude = location.latitude
        longitude = location.longitude
        accuracy = location.accuracy
        speed = location.speed
        altitude = location.altitude
        satelliteCount = Int(location.satelliteCount)
    }

    public required init?(_ map: Map) {
        super.init(map)
    }

    
}