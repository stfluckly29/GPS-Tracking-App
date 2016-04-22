//
//  PushSubscriptionModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 1/29/16.
//  Copyright © 2016 Realine. All rights reserved.
//

import Foundation
import ObjectMapper


public enum Platform: Int {
    case iOS = 0
    case Android = 1
}

public class PushSubscriptionModel: Model {
    public private(set) var application: String?
    public private(set) var topic: String?
    public private(set) var platform: Platform?
    public private(set) var token: String?
    public private(set) var customUserData: String?
    
    override public func mapping(map: Map) {
        super.mapping(map)
        application <- map["Application"]
        platform <- (map["Platform"], RawRepresentableTransform())
        topic <- map["Topic"]
        token <- map["Token"]
        customUserData <- map["CustomUserData"]
    }
    
    public init(application: String, topic: String, token: String, platform: Platform) {
        super.init()
        self.application = application
        self.topic = topic
        self.token = token
        self.platform = platform
    }

    public required init?(_ map: Map) {
        super.init(map)
    }    
}