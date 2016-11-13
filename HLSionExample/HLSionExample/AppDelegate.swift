//
//  AppDelegate.swift
//  HLSionExample
//
//  Created by hyde on 2016/11/13.
//  Copyright © 2016年 r-plus. All rights reserved.
//

import UIKit
import HLSion

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        HLSion.restoreDownloadsTasks()
        return true
    }

}
