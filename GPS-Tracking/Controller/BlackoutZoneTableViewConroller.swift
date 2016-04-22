//
//  BlackoutZoneTableViewConroller.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/16/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import UIKit
import RxSwift

public class BlackOutZoneTableViewController: UITableViewController {
    private let viewModel = BlackoutZoneListViewModel()
    
    var activityIndicator: UIActivityIndicatorView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        activityIndicator = self.addActivityIndicator()
    }
    
    public override func viewDidAppear(animated: Bool) {

        viewModel.active = true
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

        viewModel.loadBlackoutZones{ self.tableView.reloadData() }
    }
    
    public override func viewDidDisappear(animated: Bool) {
        viewModel.active = false
    }
    
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let viewController: MVVMControllerProtocol = segue.destinationViewController as! MVVMControllerProtocol
        viewController.setViewModel(self.viewModel.viewModel(forSeagueId: segue.identifier!))
    }
}

extension BlackOutZoneTableViewController {
    
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return viewModel.numbersOfSections
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(section: section)
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return viewModel.configureCell(forIndexPath: indexPath, tableView: tableView)
    }
    
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !viewModel.isEmpty {
            viewModel.selectedIndex = indexPath.row
            performSegueWithIdentifier("ZoneMap", sender: self)
        }        
    }
    
    public override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0.1
        } else {
            return 10
        }
    }
}