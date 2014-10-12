//
//  AppDelegate.swift
//  SwiftExample
//
//  Created by Nick Lockwood on 12/10/2014.
//  Copyright (c) 2014 Nick Lockwood. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        window = iConsoleWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = ViewController(nibName: "ViewController", bundle: nil)
        window?.backgroundColor = UIColor.whiteColor()
        window?.makeKeyAndVisible()
        return true
    }
}

