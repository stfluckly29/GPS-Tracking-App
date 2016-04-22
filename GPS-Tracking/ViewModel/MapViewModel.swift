//
//  MapViewModel.swift
//  LoadSetGPS
//
//  Created by Alexander Povkolas on 11/2/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import MapKit
import RxSwift
import RxCocoa
import SwiftDate

public typealias RouteData = (MKPolyline, MKMapRect)

enum MapViewModelError: ErrorType{
    case UnableCreateRoute(reason: String)
}

enum RouteType: String, CustomStringConvertible {
    case Expected = "Expected"
    case Tracked = "Tracked"
    case BlackedOut = "BlackedOut"
    case Selected = "Selected"
    case Private = "Private"
    
    var description: String {
        return self.rawValue
    }
}

public enum DateType: Int {
    case From = 0
    case To = 1
}

public class MapViewModel: StatisticsViewModel {
    
    override var selectedPeriods: Set<TrackPeriod> {
        didSet{
            self.selectedTrack.removeAll()
            let tracks = self.dtoPeriods
                .filter{ $0.begin != nil }
                .filter{ self.selectedPeriods.contains(TrackPeriod(begin: $0.begin!)) }
            tracks.forEach{ self.selectedTrack.insert($0) }
            
            self.privateTrack.removeAll()
            let privateTracks = self.dtoPeriods
                .filter{ $0.begin != nil }
                .filter{ self.privatePeriods.contains(TrackPeriod(begin: $0.begin!)) }
            privateTracks.forEach{ self.privateTrack.insert($0) }
            
            self.dtoPeriodsSubject.onNext(self.dtoPeriods)
            self.annotationsSubject.onNext(self.directionAnnotations(tracks.isEmpty ? self.dtoPeriods : tracks))
            
            if !tracks.isEmpty {
                selectedPoints = Array(tracks).sort{ $1.begin < $1.begin }.flatMap{ $0.points }
            } else {
                selectedPoints = self.dtoPeriods.filter{ $0.periodType == .Movement }.flatMap{ $0.points }
            }
            
            if let firstPoint = selectedPoints.first {
                self.showSliderSubject.onNext(true)
                self.currentAnnotationsSubject.onNext(CurrentPosition(location: firstPoint))
            } else {
                self.showSliderSubject.onNext(false)
            }

            
            
        }
    }
    
    public let isIphone4s: Bool = {
        let device = Device()
        return device == .iPhone4s || device == .Simulator(.iPhone4s)
    }()
    
    public var locateObservable: Observable<Bool> { return self.dtoPeriodsSubject.flatMap{ Observable.just($0.filter{ $0.periodType == .Movement }.isEmpty) } }
    public var annotationsObservable: Observable<[TrackPin]> { return annotationsSubject.asObservable() }
    public var currentAnnotationsObservable: Observable<CurrentPosition> { return currentAnnotationsSubject.asObservable() }
    public var fromDate = NSDate() - 7.days
    public var toDate = NSDate()
    
    public var fromDateString: String {
        return dateTimeFormater.stringFromDate(fromDate)
    }
    
    public var toDateString: String {
        return dateTimeFormater.stringFromDate(toDate)
    }
    
    public var selectedPoints = [TrackPointDto]()
    
    private var dtoPeriods: [PeriodDto] = []
    private var selectedTrack = Set<PeriodDto>()
    private var privateTrack = Set<PeriodDto>()
    private let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    private let dtoPeriodsSubject = BehaviorSubject(value: [PeriodDto]())
    private let annotationsSubject = PublishSubject<[TrackPin]>()
    private let currentAnnotationsSubject = PublishSubject<CurrentPosition>()
    private let showSliderSubject = PublishSubject<Bool>()
    
    private let dateTimeFormater: NSDateFormatter! = {
        let _formater = NSDateFormatter()
        _formater.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        _formater.dateFormat = "EEE MMM dd', 'h:mm a"
        return _formater
    }()
    
    public let sliderTimeFormater: NSDateFormatter! = {
        let _formater = NSDateFormatter()
        _formater.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        _formater.dateFormat = "hh:mm a, mm/dd/yyyy"
        return _formater
    }()


    
    // MARK: - Track logic
    
    public func loadTrack(from from: NSDate, to:NSDate) {
        self.activeLoadings++
        let apiResult: Observable<[PeriodDto]> = API.getList(.GetTrack(from: from, to: to)).observeOn(MainScheduler.instance)
        _ = apiResult.subscribe(onNext: { [weak self] in
            self?.activeLoadings--
            self?.dtoPeriods = $0
            self?.dtoPeriodsSubject.onNext($0)
        }, onError: { [weak self] in
            self?.errorSubject.onNext( ($0 as NSError).localizedDescription ?? "Can't get track" )
            self?.activeLoadings--
        })
    }
    
    public var nextSegment: Observable<MKPolyline> {
        return DataHelper.newLocations()
            .takeUntil(didBecomeInactive)
            .map{ locations in
                var points = locations.map{ CLLocationCoordinate2DMake($0.latitude, $0.longitude)}
                if let prevLocation = Location.previous(locations.first, context: self.context) {
                    points.insert(CLLocationCoordinate2DMake(prevLocation.latitude, prevLocation.longitude), atIndex: 0)
                }
                
                let line = MKPolyline(coordinates: &points, count: points.count)
                line.title = RouteType.Expected.description
                return line
        }.subscribeOn(Dependencies.sharedDependencies.backgroundWorkScheduler)
        .observeOn(MainScheduler.instance)
    }
    
    public var showSlider: Observable<Bool> {
        return showSliderSubject.asObservable()
    }
    
    public var visibleRegion: Observable<MKMapRect> {
        var seed: MKMapRect?
        return [publicRoutes(), privateRoutes(), selectedRoutes(), unsavedRoute()].toObservable().merge()
            .flatMap({ (polyline:MKPolyline) -> Observable<MKMapRect> in
                if seed == nil {
                    seed = polyline.boundingMapRect
                }
                seed = MKMapRectUnion(seed!, polyline.boundingMapRect)
                return Observable.just(seed!)
            })
    }
    
    public func savedRoute() -> Observable<MKPolyline> {
        let publicRoute: Observable<MKPolyline> = publicRoutes().filter{ $0 != nil }.map{ $0 }
            .map{ line in
                line.title = RouteType.Tracked.description
                return line}
        
        let privateRoute: Observable<MKPolyline> = privateRoutes().filter{ $0 != nil }.map{ $0 }
            .map{ line in
                line.title = RouteType.Private.description
                return line}
        
        let selectedRoute: Observable<MKPolyline> = selectedRoutes().filter{ $0 != nil }.map{ $0 }
            .map{ line in
                line.title = RouteType.Selected.description
                return line}
        return [privateRoute, publicRoute, selectedRoute].toObservable().merge()
    }
    
    
    public func unsavedRoute() -> Observable<MKPolyline> {
        return Route.fetchRoutes(context).filter{ $0.locations?.count > 0 }
            .map{ $0.locations?.allObjects as! [Location] }
            .map{ $0.filter{ !$0.saved } }
            .filter{ $0.count > 0 }
            .map{ polyline($0) }
            .toObservable()
            .map{ line in line.title = RouteType.Expected.description
                return line
            }
    }

    // MARK: - DatePicker logic
    
    public func bluredFrame(startFrame: CGRect) -> Observable<CGRect> {
        return  keyboardShowObservable
            .map { $0.userInfo }
            .filter{ $0 != nil}
            .map{ $0![UIKeyboardFrameBeginUserInfoKey]?.CGRectValue }
            .map{ CGRectMake(startFrame.minX, startFrame.minY, startFrame.maxX, $0!.minY - 44) }
    }
    
    public var keyboardHideObservable: Observable<NSNotification> {
        return NSNotificationCenter.defaultCenter()
            .rx_notification(UIKeyboardWillHideNotification, object: nil)
            .takeUntil(didBecomeInactive)
    }
    
    public var keyboardShowObservable: Observable<NSNotification> {
        return NSNotificationCenter.defaultCenter()
            .rx_notification(UIKeyboardWillShowNotification, object: nil)
            .takeUntil(didBecomeInactive)
    }
    
    private func publicRoutes() -> Observable<MKPolyline> {
        return dtoPeriodsSubject.flatMap{ $0.toObservable() }
            .filter{ $0.periodType == .Movement }
            .filter{ !self.selectedTrack.contains($0) }
            .filter{ !self.privateTrack.contains($0) }
            .map{ self.polyline(route: $0) }
    }
    
    private func privateRoutes() -> Observable<MKPolyline> {
        return dtoPeriodsSubject.flatMap{ $0.toObservable() }
            .filter{ $0.periodType == .Movement }
            .filter{ !self.selectedTrack.contains($0) }
            .filter{ self.privateTrack.contains($0) }
            .map{ self.polyline(route: $0) }
    }

    
    private func selectedRoutes() -> Observable<MKPolyline> {
        return dtoPeriodsSubject.flatMap{ $0.toObservable() }
            .filter{ $0.periodType == .Movement }
            .filter{ self.selectedTrack.contains($0) }
            .map{ self.polyline(route: $0) }
    }
    
    // TODO create Protocol for common fileds in Location & TrackPointDto
    private func polyline(route route: Route) -> MKPolyline {
        let locations = route.locations ?? []
        return polyline(locations.allObjects.map{ $0 as! Location})
    }
    
    private func polyline(locations: [Location]) -> MKPolyline {
        let points = locations
            .sort{ $0.timestamp < $1.timestamp }
            .map{ CLLocationCoordinate2DMake($0.latitude, $0.longitude) }
        
        var coords: [CLLocationCoordinate2D] = []
        coords += points
        
        return MKPolyline(coordinates: &coords, count: coords.count)
    }

    
    private func polyline(route route: PeriodDto) -> MKPolyline {
        let points = route.points
            .sort{ $0.timestamp < $1.timestamp }
            .filter{ $0.latitude != nil && $0.longitude != nil}
            .map{ CLLocationCoordinate2DMake($0.latitude!, $0.longitude!) }
        
        var coords: [CLLocationCoordinate2D] = []
        coords += points
        
        return MKPolyline(coordinates: &coords, count: coords.count)
    }
    
    private func directionAnnotations(tracks: [PeriodDto]) -> [TrackPin] {
        let annotations = tracks.filter{ $0.points.count > 1 }
            .filter{ $0.periodType == .Movement }
            .map{ $0.points }
            .map{ [annotation($0[0]), annotation($0[$0.count-1])] }
            .flatMap{ $0 }
        
        return annotations
    }
    
    private func annotation(point: TrackPointDto) -> TrackPin {
        return TrackPin(location: CLLocationCoordinate2DMake(point.latitude ?? 0, point.longitude ?? 0),
            timestamp: point.timestamp)
    }
    
    private func angleInRadians(p1: TrackPointDto, p2: TrackPointDto) -> Double {
        return ((p2.longitude ?? 0) - (p1.longitude ?? 0)) / ((p2.latitude ?? 0) - (p1.latitude ?? 0)) // zero divider
    }
}

public class CurrentPosition: NSObject, MKAnnotation {
    
    private var location: TrackPointDto
    private var clLocation: CLLocationCoordinate2D
    
    init(location: TrackPointDto) {
        self.location = location
        self.clLocation = CLLocationCoordinate2D(latitude: location.latitude!, longitude: location.longitude!)
    }
    
    public var coordinate: CLLocationCoordinate2D {
        get { return clLocation }
        set { clLocation = CLLocationCoordinate2D(latitude: location.latitude!, longitude: location.longitude!) }
    }
    
    public var title: String? { return location.timestamp != nil ? TrackPin.dateFormater.stringFromDate(location.timestamp!) : "" }
    
    public var subtitle: String? { return  "" }
    
    public var icon: UIImage { return UIImage(named: "ic_pin_truck")! }
}

public class TrackPin: NSObject, MKAnnotation {
    
    private var location: CLLocationCoordinate2D
    private var timestamp: NSDate?
    
    init(location: CLLocationCoordinate2D, timestamp: NSDate?) {
        self.location = location
        self.timestamp = timestamp
    }
    
    public var coordinate: CLLocationCoordinate2D { return location }
    
    public var title: String? { return timestamp != nil ? TrackPin.dateFormater.stringFromDate(timestamp!) : "" }
    
    public var subtitle: String? { return  "" }
    
    private static var dateFormater: NSDateFormatter! = {
        let _formater = NSDateFormatter()
        _formater.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        _formater.dateStyle = .MediumStyle
        _formater.timeStyle = .MediumStyle
        return _formater
    }()

}









