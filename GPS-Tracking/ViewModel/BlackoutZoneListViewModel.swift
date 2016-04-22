//
//  BlackoutZoneListViewModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/16/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import UIKit
import RxSwift

public class BlackoutZoneListViewModel: NetworkingViewModel {
    
    private var zones: [BlackoutZoneModel] = []
    
    public var isEmpty: Bool { return zones.isEmpty }
    
    public var selectedIndex: Int?
    
    public func loadBlackoutZones( updateList: (_:Void)->Void ){
        self.activeLoadings++
        
        let apiResult: Observable<[BlackoutZoneModel]> = API.getList(.ZonesList).observeOn(MainScheduler.instance)

        _ = apiResult.subscribe(
            onNext: { list in
                self.zones = list
                updateList()
                self.activeLoadings--
            }, onError: { error in
                self.activeLoadings--
                self.errorSubject.onNext( (error as NSError).localizedDescription ?? "Can't get zones list" )
        })
    }
    
    public var numbersOfSections: Int {
        return 1
    }
    
    public func numberOfRows(section section:Int) -> Int {
        return isEmpty ? 1 : zones.count
    }
    
    public func configureCell(forIndexPath indexPath:NSIndexPath, tableView: UITableView) -> UITableViewCell {
        if isEmpty {
            let reuseId = "no_zones"
            var cell = tableView.dequeueReusableCellWithIdentifier(reuseId)
            if cell == nil {
                cell = UITableViewCell(style: .Default, reuseIdentifier: reuseId)
            }
            cell?.textLabel?.text = "No zones currently"
            cell?.textLabel?.textAlignment = .Center
            
            return cell!
            
        } else {
            let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier( "BlackZone", forIndexPath: indexPath)
            cell.textLabel?.text = zones[indexPath.row].name
            if let radius = zones[indexPath.row].radiusKm {
                cell.detailTextLabel?.text = "\(radius.normalize().format(".1")) \(Config.service.units.distanceAbbr)"
            } else {
                cell.detailTextLabel?.text = "-"
            }
            
            return cell
        }
    }
    
    public override func viewModel(forSeagueId id:String) -> ViewModel {
        if let index = selectedIndex {
            selectedIndex = nil
            return BlackoutZoneViewModel(zone: zones[index])
        } else {
            let zone = BlackoutZoneViewModel(zone: BlackoutZoneModel())
            zone.state = .New
            return zone
        }
    }
    
}