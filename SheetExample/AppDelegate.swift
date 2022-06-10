//
//  AppDelegate.swift
//  SheetExample
//
//  Created by 최광현 on 2022/05/13.
//

import UIKit
import Sheet

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.window = self.window ?? UIWindow()
        window?.backgroundColor = .white
        
        let backgroundSheet = BackgroundSheetViewController()
        let frontSheet = FrontSheetViewController()
        let sheet = Sheet(backgroundSheet, frontSheet, positionConfiguration: .init(originMargin: 500, targetMargin: 400, pinPosition: .bottom))
        sheet.view.backgroundColor = .white
        sheet.backgroundSheetDelegate = backgroundSheet
        sheet.frontSheetDelegate = frontSheet
        window?.rootViewController = UINavigationController(rootViewController: sheet)
        window?.makeKeyAndVisible()
        return true
    }


}

