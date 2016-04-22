//
//  DashboardNavigationController.swift
//  SnapperLite
//
//  Created by Alexey Kuchmiy on 1/11/16.
//  Copyright © 2016 Realine. All rights reserved.
//

import UIKit

class DashboardNavigationController: UINavigationController, UINavigationControllerDelegate {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        delegate = self
    }
    
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        
        if viewController.isKindOfClass(UITabBarController.self)
        {
            self.navigationBarHidden = true
        }
        else
        {
            self.navigationBarHidden = false
        }
    }
}
