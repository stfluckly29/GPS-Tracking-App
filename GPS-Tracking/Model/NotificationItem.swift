//
//  NotificationItem.swift
//  LoadSetGPS
//
//  Created by Stefan on 1/26/16.
//  Copyright © 2016 Realine. All rights reserved.
//

import Foundation
import ObjectMapper

public enum NotificationStatus: Int {
    case Undread = 0
    case Seen = 1
    case Read = 2
}

public class NotificationItem: Model {
    
    public private(set) var id: String?
    public private(set) var eventCode: String?
    public private(set) var status: NotificationStatus?
    public private(set) var createDate: NSDate?
    public private(set) var jsonData: String?
    
    override public func mapping(map: Map) {
        super.mapping(map)
        id <- map["Id"]
        eventCode <- map["EventCode"]
        createDate <- (map["CreateDate"], ServerDateTransform())
        status <- (map["Status"], RawRepresentableTransform())
        jsonData <- map["JsonData"]
    }
    
    public required init?(_ map: Map) {
        super.init(map)
    }
    
}
