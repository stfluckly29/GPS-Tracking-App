//
//  DashboardViewModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/14/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import RxSwift


public class DashboardViewModel: StatisticsViewModel {
        
    public var hoursObservable: Observable<(String, Double)> {
        return dayPeriodsSubject
            .takeUntil(didBecomeInactive)
            .map{ $0.reduce(0 as Double, combine: { $0 + ($1.duration ?? 0) }) } 
            .map{ duration in
                let durationString = (Double(duration.asMinutes) / NSTimeInterval.MinutesInHour).format(".1")
                let percentage = Double(duration.asHours) / NSTimeInterval.HoursInDay
                return (durationString, percentage)
        }
    }
    
    public var milesObservable: Observable<String> {
        return dayPeriodsSubject
            .takeUntil(didBecomeInactive)
            .map{ $0.reduce(0 as Double, combine: { $0 + ($1.mileageKm ?? 0) }) }
            .map{ $0.normalize().format(".1") }
    }
}