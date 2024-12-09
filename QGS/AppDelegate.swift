//
//  AppDelegate.swift
//  QGS
//
//  Created by Edin Martinez on 8/13/24.
//

import UIKit
import CoreData


class AppDelegate : UIResponder, UIApplicationDelegate{
    
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions lauchOptions: [UIApplication.LaunchOptionsKey : Any]?)  -> Bool {
        LocationViewController.shared.requestLocationPermission()
    return true
    }
    
   
}
