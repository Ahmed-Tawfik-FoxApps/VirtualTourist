//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Ahmed Tawfik on 12/12/17.
//  Copyright © 2017 Fox Apps. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        stack.autoSave(60)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        do {
            try stack.saveContext()
        } catch {
            print("Error while asving context")
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        do {
            try stack.saveContext()
        } catch {
            print("Error while asving context")
        }
    }
}

