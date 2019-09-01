//
//  AppDelegate.swift
//  Pattern
//
//  Created by jaume on 31/08/2019.
//  Copyright © 2019 Jaume. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var nav: UINavigationController!
    var vc: ViewController!
    var pattern: [Int]!


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        vc = ViewController.init()
        vc.functionality = .createPattern(3)
        vc.delegate = self
        window?.rootViewController = vc
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

extension AppDelegate: PatternDelegate {
    func created(pattern: [Int]) {

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.vc.functionality = .checkPattern(pattern)
            self.pattern = pattern
        }

    }

    func failedCreatingPattern(lenght: Int) {
    }

    func introducedPattern(ok: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if ok {
                self.vc.functionality = .viewPattern(self.pattern)
            } else {
                self.vc.functionality = .createPattern(3)
            }
        }
    }

    func endedShowingPattern() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.vc.functionality = .createPattern(3)
        }
    }

}

