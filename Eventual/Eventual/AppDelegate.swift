//
//  AppDelegate.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    static var sharedDelegate: AppDelegate! {
        return UIApplication.shared.delegate as! AppDelegate
    }

    var window: UIWindow?

    lazy var eventManager = EventManager()
    lazy var pastEvents: PastEvents = PastEvents(manager: self.eventManager)
    lazy var upcomingEvents: UpcomingEvents = UpcomingEvents(manager: self.eventManager)

    var flowEvents: MonthEventDataSource!

    var currentScreenRestorationIdentifier: String! {
        let rootViewController = UIApplication.shared.keyWindow!.rootViewController!
        return UIViewController.topViewController(from: rootViewController).restorationIdentifier!
    }

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        flowEvents = upcomingEvents
        return true
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        Appearance.apply()
        Settings.registerDefaults()
        let navigationController = window!.rootViewController as! UpcomingEventsNavigationController
        navigationController.dataSource = flowEvents
        return true
    }

    // MARK: - UIStateRestoring

    func application(_ application: UIApplication,
                     shouldRestoreApplicationState coder: NSCoder) -> Bool {
        guard let stateBundleVersion = coder.decodeObject(forKey: UIApplicationStateRestorationBundleVersionKey) as? String,
            let bundleVersion = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String,
            stateBundleVersion == bundleVersion,
            let currentScreen = coder.decodeObject(forKey: "currentScreen") as? String,
            currentScreen != "MonthsViewController"
            else { return false }
        return true
    }

    func application(_ application: UIApplication,
                     shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(_ application: UIApplication, willEncodeRestorableStateWith coder: NSCoder) {
        coder.encode(currentScreenRestorationIdentifier, forKey: "currentScreen")
    }

    func application(_ application: UIApplication, didDecodeRestorableStateWith coder: NSCoder) {
    }

    // MARK: -

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {}

}
