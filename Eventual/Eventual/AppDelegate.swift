//
//  AppDelegate.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    static var shared: AppDelegate! {
        return UIApplication.shared.delegate as! AppDelegate
    }

    var window: UIWindow?
    private var tabBarController: AppTabBarController? {
        return window?.rootViewController as? AppTabBarController
    }

    private lazy var eventStore = EventStore()
    lazy var pastEvents: PastEvents = PastEvents(store: self.eventStore)
    lazy var upcomingEvents: UpcomingEvents = UpcomingEvents(store: self.eventStore)

    private var allEvents: [MonthEventDataSource] { return [pastEvents, upcomingEvents] }
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
        tabBarController!.selectedIndex = 0
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        flowEvents.refreshIfNeeded()
        allEvents.forEach() { $0.isNeedsRefreshEnabled = false }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        allEvents.forEach() { $0.isNeedsRefreshEnabled = true }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        allEvents.forEach() { $0.isNeedsRefreshEnabled = false }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        defer {
            allEvents.filter() { !$0.isEmpty }.forEach() { $0.refetch() }
        }
        guard let tabBarController = tabBarController else { return }
        let alertController = UIAlertController(
            title: t("Oh no!", "error"),
            message: t("Your device is running out of memory. We're clearing some up.", "error"),
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(title: t("OK", "button"), style: .default)
            { _ in alertController.dismiss(animated: true) }
        )
        tabBarController.present(alertController, animated: true)
    }

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
