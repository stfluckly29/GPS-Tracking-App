//
//  NotificationsViewController.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/9/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import UIKit
import RxSwift
import UIScrollView_InfiniteScroll


public class NotificationsViewController: UIViewController {

    @IBOutlet weak var notificationsTableView: UITableView!
    @IBOutlet weak var trackerSwitch: UISwitch!
    
    var activityIndicator: UIActivityIndicatorView!
    
    private let viewModel = NotificationsViewModel()
    
    public override func viewDidLoad() {
        setupAppearance()
        notificationsTableView.tableFooterView = UIView(frame: CGRect.zero)
        activityIndicator = self.addActivityIndicator()
    }
    
    public override func viewDidAppear(animated: Bool) {
        viewModel.active = true
        trackerSwitch.on = viewModel.trackerEnabled
        _ = trackerSwitch.rx_value.subscribeNext{
            self.viewModel.trackerEnabled = $0
            if $0 && !self.viewModel.locationServicesDisabled {
                self.viewModel.trackerEnabled = true
            } else {
                self.viewModel.trackerEnabled = false
                if self.viewModel.locationServicesDisabled {
                    self.showLocationDisabledAlert()
                    self.trackerSwitch.on = false
                }
            }
        }
        
        _ = viewModel.errorObservable.observeOn(MainScheduler.instance).subscribeNext{
            self.showAlert($0)
            self.activityIndicator.stopAnimating()
        }
        _ = viewModel.loadingObservable.observeOn(MainScheduler.instance).subscribeNext{
            if $0  {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
        }

        
        viewModel.loadNotifications{ self.notificationsTableView.reloadData() }
        
        notificationsTableView.addInfiniteScrollWithHandler{ _ in
            self.viewModel.loadMore{
                self.notificationsTableView.reloadData()
                self.notificationsTableView.finishInfiniteScroll()
                if $0 {
                    self.notificationsTableView.removeInfiniteScroll()
                }
            }
        }
    }
    
    public override func viewDidDisappear(animated: Bool) {
        viewModel.active = false
        self.notificationsTableView.removeInfiniteScroll()
    }
}

extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {
    
    private func setupAppearance() {
        //notificationsTableView.backgroundColor = Theme.service.navigationBarBarTintColor
    }
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return viewModel.numbersOfSections
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(section: section)
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return viewModel.configureCell(forIndexPath: indexPath, tableView: tableView)
    }
    
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return viewModel.cellType(forIndexPath: indexPath).height
    }
    
}