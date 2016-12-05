//
//  AppDelegate.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    lazy var mainCoordinator: NavigationCoordinator = {
        return NavigationCoordinator(eventManager: EventManager())
    }()

    static var sharedDelegate: AppDelegate {
        guard
            let delegate = UIApplication.shared.delegate as? AppDelegate
            else { preconditionFailure("No app delegate!") }

        return delegate
    }

    var didDecodeRestorableState = false

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        mainCoordinator.isRestoringState = didDecodeRestorableState
        Appearance.apply()
        let navigationController = window?.rootViewController as! UINavigationController
        navigationController.delegate = mainCoordinator
        let viewController = navigationController.topViewController as! CoordinatedViewController
        viewController.coordinator = mainCoordinator
        return true
    }

    func application(_ application: UIApplication,
                     shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(_ application: UIApplication,
                     shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(_ application: UIApplication, willEncodeRestorableStateWith coder: NSCoder) {}

    func application(_ application: UIApplication, didDecodeRestorableStateWith coder: NSCoder) {
        didDecodeRestorableState = true
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {}

}
