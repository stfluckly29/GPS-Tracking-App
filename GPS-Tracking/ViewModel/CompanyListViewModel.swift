//
//  CompanyListViewModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 1/30/16.
//  Copyright © 2016 Realine. All rights reserved.
//

import UIKit
import AlamofireImage
import RxSwift

let defErrorMessage = "Unable to complete"

public class CompanyListViewModel: NetworkingViewModel {
    var companyList: [UserContextItem] = []
    
    public var navigationTitle: String {
        return ""
    }
    
    public var topLabel: String? {
        return nil
    }
    
    public func listObservable() -> Observable<[UserContextItem]> {
        preconditionFailure("This method must be overridden")
    }
    
    public func enableSharingObservable(item: UserContextItem) -> Observable<ServiceResponseModel> {
        preconditionFailure("This method must be overridden")
    }
    
    public func disableSharingObservable(item: UserContextItem) -> Observable<ServiceResponseModel> {
        preconditionFailure("This method must be overridden")
    }
    
    public let numbersOfSections = 1
    
    public var numberOfRows: Int {
        return companyList.count
    }
    
    public func configureCell(forIndexPath indexPath:NSIndexPath, tableView: UITableView) -> UITableViewCell {
        //public func registerClass(cellClass: AnyClass?, forCellReuseIdentifier identifier: String)
        
        let cellIdentifier = "CompanyCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as UITableViewCell!
        if cell == nil {
            cell = UITableViewCell(style:.Default, reuseIdentifier: cellIdentifier)
            cell.textLabel?.font = Theme.service.baseFont
        }        
        
        let company = companyList[indexPath.row]
        cell.textLabel?.text = company.name ?? "Unknown name"
        cell.imageView?.af_setImageWithURL(NSURL(string: company.imageLink ?? "")!)
        cell.accessoryType = (company.sharingEnabled ?? false) ? .Checkmark : .None
        cell.textLabel?.textColor = (company.sharingEnabled ?? false) ? Theme.service.textColorDark : Theme.service.textColorGrey
        
        return cell
    }
    
    public func loadList(completed: (_: Void)->Void){
        self.activeLoadings++
        _ = listObservable().observeOn(MainScheduler.instance).subscribe(
            onNext: {
                let result: [UserContextItem] = $0
                self.companyList = result
                self.activeLoadings--
                completed()
            },
            onError: {error in
                self.activeLoadings--
                self.errorSubject.onNext( (error as NSError).localizedDescription ?? defErrorMessage )
        })
    }
    
    public func enableSharing(indexPath: NSIndexPath, completed: (_: Bool)->Void){
        self.activeLoadings++
        let company = companyList[indexPath.row]
        let result = company.sharingEnabled ?? false ? disableSharingObservable(company) : enableSharingObservable(company)
        
        _ = result.observeOn(MainScheduler.instance).subscribe(
            onNext: {
                let result: ServiceResponseModel = $0
                guard let status = result.status else {
                    self.errorSubject.onNext(defErrorMessage)
                    self.activeLoadings--
                    completed(false)
                    return
                }
                
                self.activeLoadings--
                if !status {
                    self.errorSubject.onNext(result.errors.first?.errorMessage ?? defErrorMessage)
                } else {
                    company.sharingEnabled = !(company.sharingEnabled ?? false)
                }
                completed(status)
            },
            onError: {error in
                self.activeLoadings--
                self.errorSubject.onNext( (error as NSError).localizedDescription ?? defErrorMessage )
        })
        
    }
}