//
//  SettingsViewController.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/16/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import UIKit
import LoginSignUpiOS
import RxSwift

public class SettingsViewController: UITableViewController {
    
    private let viewModel = SettingsViewModel()
    
    @IBOutlet weak var englishSystemViewCell: UITableViewCell!
    @IBOutlet weak var metricSystemViewCell: UITableViewCell!
    @IBOutlet weak var englishImage: UIImageView!
    @IBOutlet weak var metricImage: UIImageView!
    
    @IBOutlet weak var appNotificationsSwitch: UISwitch!
    @IBOutlet weak var blackoutZoneNotificationsSwitch: UISwitch!
    
    @IBOutlet var backButton: UIBarButtonItem!
    
    private var uiDisposeBag: DisposeBag!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        let bundle = NSBundle(forClass: RLLoginSignUpManager.self)
        backButton.image = UIImage(named: "backArrow", inBundle: bundle, compatibleWithTraitCollection: nil)
    }

    public override func viewDidAppear(animated: Bool) {
        viewModel.active = true
        uiDisposeBag = DisposeBag()
        updateUnits(viewModel.unit)
        appNotificationsSwitch.on = viewModel.appNotifications
        blackoutZoneNotificationsSwitch.on = viewModel.gpsZoneEntryNotification
        
        appNotificationsSwitch.rx_value.subscribeNext{
            self.viewModel.appNotifications = $0
        }.addDisposableTo(uiDisposeBag)
        blackoutZoneNotificationsSwitch.rx_value.subscribeNext{
            self.viewModel.gpsZoneEntryNotification = $0
        }.addDisposableTo(uiDisposeBag)
    }
    
    public override func viewDidDisappear(animated: Bool) {
        viewModel.active = false
        uiDisposeBag = nil
    }
    
    @IBAction func close(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
        RLLoginSignUpManager.sharedManager().toggleSideMenu()
    }
    
    private func updateUnits(unit: UnitsOfMeasure){
        switch unit {
        case .English:
            englishImage.highlighted = true
            metricImage.highlighted = false
        case .Metric:
            englishImage.highlighted = false
            metricImage.highlighted = true
        }
    }
}

extension SettingsViewController {
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            let unit: UnitsOfMeasure = tableView.cellForRowAtIndexPath(indexPath) == englishSystemViewCell ? .English : .Metric
            viewModel.unit = unit
            updateUnits(unit)            
        } else if indexPath.section == 2 {
            self.navigationController?.pushViewController(CompanyListViewController(viewModel.sharingViewModel), animated: true)
        }
    }
}