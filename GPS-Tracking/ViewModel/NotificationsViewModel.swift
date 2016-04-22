//
//  NotificationsViewModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/9/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import UIKit
import RxSwift


public class NotificationsViewModel: TrackedViewModel {
    
    private let defaultCount = 10
    
    private var notificationItems: [NotificationItem] = []
    private var notifications: [RealineNotification] = []
    private let notificationsFactory: NotificationModelFactory = NotificationModelFactory()
    
    
    public enum CellTypes: String{
        case Notification = "Notification"
        case Social = "Social"
        
        var height: CGFloat {
            switch self {
            case .Notification:
                return 78
            case .Social:
                return 41
            }
        }
    }
    
    public func loadNotifications(updateList: (_:Void)->Void ){
        loadNotifications(0, take: defaultCount, showSpinner: true){ updateList() }
    }
    
    public func loadMore(updateList: (lastPart:Bool)->Void){
        let initialCount = notificationItems.count
        loadNotifications(notificationItems.count, take: defaultCount, showSpinner: false){ [weak self] _ in
            let diff = self!.notificationItems.count - initialCount
            if diff < self!.defaultCount {
                updateList(lastPart: true)
            } else {
                updateList(lastPart: false)
            }            
        }
    }
    
    private func loadNotifications(skip: Int, take: Int, showSpinner: Bool, updateList: (_:Void)->Void ){
        if showSpinner {
            self.activeLoadings++
        }
        
        let apiResult: Observable<[NotificationItem]> = API.getList(.NotificationList(skip: skip, take: take))
        
        _ = apiResult.map{ [weak self] list in
                self!.notificationItems.appendContentsOf(list)
                self!.notifications.appendContentsOf(list.map{ self!.notificationsFactory.createNotification($0) })
            }
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] list in
                    updateList()
                    if showSpinner {
                        self!.activeLoadings--
                    }
                }, onError: { error in
                    self.errorSubject.onNext( (error as NSError).localizedDescription ?? "Can't get notifications list" )
            })
    }
    
    public var numbersOfSections: Int {
        return 1
    }
    
    public func numberOfRows(section section: Int) -> Int {
        return notifications.count
    }
    
    public func configureCell(forIndexPath indexPath:NSIndexPath, tableView: UITableView) -> UITableViewCell {
        switch cellType(forIndexPath: indexPath) {
        case .Notification:
            let cell = tableView.dequeueReusableCellWithIdentifier( CellTypes.Notification.rawValue, forIndexPath: indexPath) as! NotificationViewCell
            cell.avatar.hidden = true
            cell.date.font = Theme.service.dateFont
            cell.date.textColor = Theme.service.textColorGrey
            bindData(cell, indexPath: indexPath)
            return cell
        case .Social:
            let cell = tableView.dequeueReusableCellWithIdentifier( CellTypes.Social.rawValue, forIndexPath: indexPath) as! SocialViewCell
            cell.followButton.setTitleColor(Theme.service.textColorLightGrey, forState: .Normal)
            cell.commentButton.setTitleColor(Theme.service.textColorLightGrey, forState: .Normal)
            cell.shareButton.setTitleColor(Theme.service.textColorLightGrey, forState: .Normal)
            return cell
        }
    }
    
    public func cellType(forIndexPath indexPath:NSIndexPath) -> CellTypes {
        return .Notification
    }
    
    // MARK: - Formating
    
    private func bindData(cell: NotificationViewCell, indexPath:NSIndexPath) {
        let notification = notifications[indexPath.row]
        if let notification = notification as? NewUserNotification {
            let name = notification.fullName != nil ? notification.fullName! : "\(notification.firstName ?? "") \(notification.lastName ?? "")"
            cell.actionTitle.attributedText = actionTitle("New user", name: name)
            cell.date.text = formater.stringFromDate(notification.createDate ?? NSDate())
            cell.locations.text = "Some details"
        }
    }
    
    private lazy var formater: NSDateFormatter! = {
        let _formater = NSDateFormatter()
        _formater.dateFormat = "MMM dd','HH:mm a"
        return _formater
    }()
    
    private func actionTitle(title: String, name: String) -> NSAttributedString {
        let textAttrs = [NSFontAttributeName : Theme.service.baseFont,
            NSForegroundColorAttributeName : Theme.service.textColorDark]
        var attributedString = NSMutableAttributedString(string:title, attributes:textAttrs)
        let numberAttrs = [NSFontAttributeName : Theme.service.baseBoldFont,
            NSForegroundColorAttributeName : Theme.service.textColorBlue]
        attributedString += NSMutableAttributedString(string: " \(name)", attributes: numberAttrs)
        
        return attributedString
    }
    
    private func locations(from: String, to: String) -> NSAttributedString {
        let textAttrs = [NSFontAttributeName : Theme.service.dateFont,
            NSForegroundColorAttributeName : Theme.service.textColorGrey]
        let locationAttrs = [NSFontAttributeName : Theme.service.secondaryTitleFont,
            NSForegroundColorAttributeName : Theme.service.textColorDark]
        
        var attributedString = NSMutableAttributedString(string:"From ", attributes:textAttrs)
        attributedString += NSMutableAttributedString(string: from, attributes: locationAttrs)
        attributedString += NSMutableAttributedString(string: " to ", attributes: textAttrs)
        attributedString += NSMutableAttributedString(string: to, attributes: locationAttrs)
        
        return attributedString
    }
}






