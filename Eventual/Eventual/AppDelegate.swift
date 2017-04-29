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

    func applicationDidBecomeActive(_ application: UIApplication) {
        defer {
            pastEvents.isNeedsRefreshEnabled = false
            upcomingEvents.isNeedsRefreshEnabled = false
        }
        guard flowEvents.needsRefresh else { return }
        if flowEvents.wasStoreChanged {
            eventManager.requestAccess() {
                self.flowEvents.refetch()
            }
        } else if !flowEvents.isEmpty {
            flowEvents.refresh()
            flowEvents.notifyOfFetch()
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        pastEvents.isNeedsRefreshEnabled = true
        upcomingEvents.isNeedsRefreshEnabled = true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        pastEvents.isNeedsRefreshEnabled = false
        upcomingEvents.isNeedsRefreshEnabled = false
    }

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    // MARK: UIStateRestoring

    var currentScreenRestorationIdentifier: String! {
        let rootViewController = UIApplication.shared.keyWindow!.rootViewController!
        return UIViewController.topViewController(from: rootViewController).restorationIdentifier!
    }

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

    func application(_ application: UIApplication, didDecodeRestorableStateWith coder: NSCoder) {}

}
