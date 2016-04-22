//
//  BlackoutZoneViewModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/16/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import RxSwift
import MapKit

public enum ViewState: Int {
    case View
    case Edit
    case New
}

public let BlackoutZonesChangedNotification = "BlackoutZonesChangedNotification"

public class BlackoutZoneViewModel: NetworkingViewModel {
    
    private var zone: BlackoutZoneModel!
    private let defaultRadius = 1.0
    
    public var state: ViewState!
    
    public override init() {
        super.init()
    }
    
    public init(zone: BlackoutZoneModel) {
        self.state = .View
        self.zone = zone
        if zone.radiusKm == nil {
            zone.radiusKm = defaultRadius
        }
    }
    
    public func save(completion: (_:Void)->Void){
        self.activeLoadings++
        let apiResult: Observable<ServiceResponseModel> = API.postObject(.SaveZone(zone: zone)).observeOn(MainScheduler.instance)
        _ = apiResult.subscribe(onNext: {
            let result: ServiceResponseModel = $0
            guard let status = result.status else {
                self.errorSubject.onNext("Unable to save")
                self.activeLoadings--
                return
            }
            
            self.activeLoadings--
            if status {
                NSNotificationCenter.defaultCenter().postNotificationName(BlackoutZonesChangedNotification, object: nil)
                completion()
            } else {
                self.errorSubject.onNext(result.errors.first?.errorMessage ?? "Unable to save")
            }
            
            }, onError: {error in
                self.errorSubject.onNext( (error as NSError).localizedDescription ?? "Unable to save" )
            })
    }
    
    public func delete(completion: (_:Void)->Void){
        self.activeLoadings++
        let apiResult: Observable<ServiceResponseModel> = API.postObject(.DeleteZone(zoneId: zone.id!)).observeOn(MainScheduler.instance)
        
        _ = apiResult.subscribe(onNext: { (result: ServiceResponseModel) -> Void in
            guard let status = result.status else {
                self.errorSubject.onNext("Unable to delete")
                self.activeLoadings--
                return
            }
            
            self.activeLoadings--
            if status {
                NSNotificationCenter.defaultCenter().postNotificationName(BlackoutZonesChangedNotification, object: nil)
                completion()
            } else {
                self.errorSubject.onNext("Unable to delete")
            }
            }, onError: { error in
                self.errorSubject.onNext( (error as NSError).localizedDescription ?? "Unable to delete" )
            })        
    }
    
    public var distanceAbbr: String {
        return Config.service.units.distanceAbbr
    }
        
    public var radius: Double {
        get { return zone.radiusKm! }
        set { zone.radiusKm = newValue }
    }
    
    public var name: String {
        get { return zone.name ?? "" }
        set { zone.name = newValue }
    }
    
    public var center: CLLocationCoordinate2D {
        get {
            guard let lat = zone.centerLatitude, let long = zone.centerLongitude else {
                return CLLocationCoordinate2DMake(0, 0)
            }
            return CLLocationCoordinate2DMake(lat, long)
        }
        set {
            zone.centerLatitude = newValue.latitude
            zone.centerLongitude = newValue.longitude
        }
    }
    
    public var rx_radius: AnyObserver<Double> {
        return AnyObserver { [weak self] event in
            MainScheduler.ensureExecutingOnScheduler()
            switch event {
            case .Next(let value):
                self?.radius = value
            default:
                self?.radius = (self?.defaultRadius)!
            }
        }
    }

    public var rx_center: AnyObserver<CLLocationCoordinate2D> {
        return AnyObserver { [weak self] event in
            MainScheduler.ensureExecutingOnScheduler()
            switch event {
            case .Next(let value):
                self?.center = value
            default:
                self?.center = CLLocationCoordinate2DMake(0, 0)
            }
        }
    }
    
    public var rx_name: AnyObserver<String> {
        return AnyObserver { [weak self] event in
            MainScheduler.ensureExecutingOnScheduler()
            switch event {
            case .Next(let value):
                self?.name = value
            default:
                self?.name = ""
            }
        }
    }
}

