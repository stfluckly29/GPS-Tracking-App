//
//  StatisticsViewModel.swift
//  LoadSetGPS
//
//  Created by Alexander Povkolas on 11/6/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

enum CellTypes: String {
    case Statistic = "Statistic"
    case AverageStatistic = "AverageStatistic"
    case StatisticHeader = "StatisticHeader"
}

public class StatisticsViewModel: TrackedViewModel{
        
    private var dayPeriods: [DayTrackPeriod] = []
    let dayPeriodsSubject = PublishSubject<[DayTrackPeriod]>()
    var selectedPeriods = Set<TrackPeriod>()
    var privatePeriods: Set<TrackPeriod> {
        return Set(self.dayPeriods.flatMap{ $0.periods }.filter{ $0.isPrivate != nil && $0.isPrivate! })
    }
    
    public func clearData(){
        dayPeriods = []
        dayPeriodsSubject.onNext(dayPeriods)
    }
    
    public var isPrivatePeriodSelected: Bool {
        return selectedPeriods.first?.isPrivate ?? false
    }
    
    public var isSelected: Bool {
        return !selectedPeriods.isEmpty
    }
    
    public var noStatistics: Bool {
        return dayPeriods.isEmpty
    }
    
    public var distanceDescription: String {
        return Config.service.units.distanceDescription
    }
    
    public var statsUpdateObservable: Observable<(String, String, String)> {
        return dayPeriodsSubject.map{ self.totalData($0) }.takeUntil(didBecomeInactive) }
    
    public var numbersOfSections: Int {
        return !dayPeriods.isEmpty ? dayPeriods.count : 1
    }
    
    public func addDayPeriod(section: Int) {
        dayPeriods[section].periods.forEach{ selectedPeriods.insert($0) }
    }
    
    public func removeDayPeriod(section: Int) {
        dayPeriods[section].periods.forEach{ selectedPeriods.remove($0) }
    }

    public func addPeriod(indexPath: NSIndexPath) -> Bool {
        selectedPeriods.insert(dayPeriods[indexPath.section].periods[indexPath.row - 1])
        return selectedPeriods.isSupersetOf(dayPeriods[indexPath.section].periods)
    }
    
    public func removePeriod(indexPath: NSIndexPath) {
        selectedPeriods.remove(dayPeriods[indexPath.section].periods[indexPath.row - 1])
    }
    
    public func clearPeriods() {
        selectedPeriods.removeAll()
    }
        
    public func numberOfRows(section section:Int) -> Int {
        return !dayPeriods.isEmpty ? dayPeriods[section].periods.count + 1 : 1
    }
    
    public func configureCell(forIndexPath indexPath:NSIndexPath, tableView: UITableView) -> UITableViewCell {
        if dayPeriods.isEmpty {
            let cell = tableView.dequeueReusableCellWithIdentifier( CellTypes.Statistic.rawValue, forIndexPath: indexPath) as! StatisticViewCell
            cell.setData(("-", "0", "0", "0"))
            return cell
        }
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier( CellTypes.AverageStatistic.rawValue, forIndexPath: indexPath) as! AverageStatisticViewCell
            cell.setData(averageDayStat(dayPeriods[indexPath.section]))
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier( CellTypes.Statistic.rawValue, forIndexPath: indexPath) as! StatisticViewCell
            let data = dayPeriods[indexPath.section].periods[indexPath.row - 1]
            cell.setData(periodStat(data))
            cell.isPrivate = data.isPrivate ?? false
            return cell
        }
    }
    
    public func makePrivate(){
        updatePeriods(isPrivate: true)
    }
    
    public func makePublic(){
        updatePeriods(isPrivate: false)
    }
    
    public var sharingViewModel: CompanyListViewModel {
        let (periodId, from, to) = Array(selectedPeriods).filter{ $0.begin != nil && $0.end != nil }
            .map{ ($0.id ?? "", $0.begin!, $0.end!) }.first!
        return PeriodSharingViewModel(periodId: periodId, from: from, to: to)
    }
    
    var loadStatsDisposable: Disposable?
    
    public func loadStatistic(from from: NSDate, to:NSDate) {
        if let disp = loadStatsDisposable {
            disp.dispose()
            self.activeLoadings--
        }
        
        self.activeLoadings++
        let apiResult: Observable<[DayTrackPeriod]> = API.getList(.GetPeriods(from: from, to: to))
        loadStatsDisposable = apiResult.observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    self?.dayPeriods = $0
                    self?.dayPeriodsSubject.onNext($0)
                    self?.loadStatsDisposable = nil
                    self?.activeLoadings--
                },
                onError: { [weak self] error in
                    self?.dayPeriodsSubject.onNext([DayTrackPeriod]())
                    // back end workaround. model == null when nothing tracked
                    // self.errorSubject.onNext("Error getting periods")
                    self?.loadStatsDisposable = nil
                    self?.activeLoadings--
            })
    }
    
    // MARK: - Formating
    
    func dayPeriodsStats(dayTrackPeriod: DayTrackPeriod) -> (NSTimeInterval, NSTimeInterval){
        return dayTrackPeriod.periods.filter {
            $0.periodType == TrackPeriodType.Movement ||
                $0.periodType == TrackPeriodType.Parking ||
                $0.periodType == TrackPeriodType.Break }
            .reduce((0 as NSTimeInterval, 0 as NSTimeInterval)) { sum, period  in
                if period.periodType == TrackPeriodType.Movement {
                    return (sum.0 + (period.duration ?? 0), sum.1)
                } else {
                    return (sum.0, sum.1 + (period.duration ?? 0))
                }
        }
    }
    
    private func totalData(dayPeriods: [DayTrackPeriod]) -> (String, String, String) {
        let (mileage, driving, idle) = dayPeriods.reduce((0 as Double, 0 as NSTimeInterval, 0 as NSTimeInterval)) { sum, day in
            let dayStats = dayPeriodsStats(day)
            return (sum.0 + (day.mileageKm ?? 0),  sum.1 + dayStats.0, sum.2 + dayStats.1) }
        
        return ("\(mileage.normalize().format(".1"))", "\(driving.hours):\(driving.minutes.format("02"))", "\(idle.hours):\(idle.minutes.format("02"))");
    }
    
    private func averageDayStat(dayTrackPeriod: DayTrackPeriod) -> (String, String, String, String) {
        let (drivingPeriod, idlePeriod) = dayPeriodsStats(dayTrackPeriod)
        let dateString = dayTrackPeriod.date != nil ? avgFormater.stringFromDate(dayTrackPeriod.date!) : "-"
        let mileageString = dayTrackPeriod.mileageKm != nil && dayTrackPeriod.mileageKm > 0 ? "\(dayTrackPeriod.mileageKm!.normalize().format(".1"))" : "0.0"
        return (dateString, "\(mileageString)",
                "\(drivingPeriod.hours):\(drivingPeriod.minutes.format("02"))",
                "\(idlePeriod.hours):\(idlePeriod.minutes.format("02"))")
    }
    
    private func periodStat(period: TrackPeriod) -> (String, String, String, String){
        let startTime = period.begin != nil ? timeFormater.stringFromDate(period.begin!) : "?"
        let endTime = period.end != nil ? timeFormater.stringFromDate(period.end!) : "?"
        let timeString = "\(startTime)-\(endTime)"
        let periodString = period.duration != nil ? "\(period.duration!.hours):\(period.duration!.minutes.format("02"))" : "-"
        
        let distance = period.mileageKm != nil && period.mileageKm > 0 ? "\(period.mileageKm!.normalize().format(".1"))" : "0.0"
        
        if let type = period.periodType {
            switch type {
            case .Movement:
                return (timeString, distance, periodString, "-")
            default:
                return (timeString, distance, "-", periodString)
            }
        } else {
            return (timeString, distance, "-", "-")
        }
    }
    
    private func updatePeriods(isPrivate isPrivate: Bool){
        self.activeLoadings++
        let periods = Array(selectedPeriods).filter{ $0.begin != nil && $0.end != nil }.map{ DtRangeModel(from: $0.begin!, to: $0.end!) }
        let apiRequest: Observable<ServiceResponseModel> = isPrivate ?
            API.postObject(.MakePeriodPrivateBulk(periods: periods )) : API.postObject(.MakePeriodPublicBulk(periods: periods ))
        let errorMessage = isPrivate ? "Unable to make period private" : "Unable to make period public"
        
        _ = apiRequest.observeOn(MainScheduler.instance)
            .subscribeNext { [weak self] (result: ServiceResponseModel) -> Void in
                guard let status = result.status else {
                    self?.errorSubject.onNext(errorMessage)
                    self?.activeLoadings--
                    self?.clearPeriods()
                    return
                }
                
                if status {
                    _ = self?.dayPeriods.flatMap{ $0.periods }
                        .filter{ self!.selectedPeriods.contains($0) }.forEach{ $0.isPrivate = isPrivate }
                    self?.dayPeriodsSubject.onNext(self!.dayPeriods) // todo check self != nil
                    self?.activeLoadings--
                } else {
                    self?.errorSubject.onNext(errorMessage)
                    self?.activeLoadings--
                }
                self?.clearPeriods()
        }
    }
    
    private lazy var avgFormater: NSDateFormatter! = {
        let _formater = NSDateFormatter()
        _formater.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        _formater.dateFormat = "MMM d', 'yyyy"
        return _formater
    }()

    private lazy var timeFormater: NSDateFormatter! = {
        let _formater = NSDateFormatter()
        _formater.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        _formater.dateFormat = "h:mm a"
        return _formater
    }()

    
}