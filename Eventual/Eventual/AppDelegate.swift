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

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        finishRestoringState()
        Appearance.apply()
        let navigationController = window?.rootViewController as! UINavigationController
        navigationController.delegate = mainCoordinator
        let viewController = navigationController.topViewController as! CoordinatedViewController
        viewController.coordinator = mainCoordinator
        return true
    }

    // MARK: - UIStateRestoring

    var flowToRestore: NavigationCoordinator.Flow?

    func application(_ application: UIApplication,
                     shouldRestoreApplicationState coder: NSCoder) -> Bool {
        guard let stateBundleVersion = coder.decodeObject(forKey: UIApplicationStateRestorationBundleVersionKey) as? String,
            let bundleVersion = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String,
            stateBundleVersion == bundleVersion
            else { return false }
        return true
    }

    func application(_ application: UIApplication,
                     shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(_ application: UIApplication, willEncodeRestorableStateWith coder: NSCoder) {
        coder.encode(mainCoordinator.flow.rawValue, forKey: "mainCoordinator.flow")
    }

    func application(_ application: UIApplication, didDecodeRestorableStateWith coder: NSCoder) {
        guard let rawValue = coder.decodeObject(forKey: "mainCoordinator.flow") as? String else { return }
        guard let flow = NavigationCoordinator.Flow(rawValue: rawValue) else { return }
        flowToRestore = flow
    }

    private func finishRestoringState() {
        guard let flow = flowToRestore else { return }
        mainCoordinator.flow = flow
        mainCoordinator.isRestoringState = true
    }

    // MARK: -

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {}

}
