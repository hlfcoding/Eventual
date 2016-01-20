//
//  NavigationController.swift
//  Eventual
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

import MapKit
import HLFMapViewController

class NavigationController: UINavigationController {

    // MARK: Private

    private let defaultStyle: UIBarStyle = .Default
    private lazy var defaultTextColor: UIColor! = {
        return UIColor.blackColor()
    }()

    // MARK: - Initializers

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        self.setUp()
    }
    override init(navigationBarClass: AnyClass!, toolbarClass: AnyClass!) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        self.setUp()
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setUp()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }

    private func setUp() {
        self.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.applyCustomBorderColor(self.view.tintColor)
    }

    // MARK: - UINavigationController

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask { // TODO: Framework error on the return type.
        if self.topViewController is EventViewController {
            return .Portrait
        }
        return super.supportedInterfaceOrientations()
    }

}

// MARK: - UINavigationControllerDelegate

extension NavigationController: UINavigationControllerDelegate {

    func navigationController(navigationController: UINavigationController,
         animationControllerForOperation operation: UINavigationControllerOperation,
         fromViewController fromVC: UIViewController, toViewController toVC: UIViewController)
         -> UIViewControllerAnimatedTransitioning?
    {
        guard let controller = self.transitioningDelegate as? UIViewControllerAnimatedTransitioning
              else { return nil }
        return controller
    }

    func navigationController(navigationController: UINavigationController,
         interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning)
         -> UIViewControllerInteractiveTransitioning?
    {
        guard let controller = self.transitioningDelegate as? UIViewControllerInteractiveTransitioning
              else { return nil }
        return controller
    }

}

// MARK: - Modal View Controllers

extension NavigationController {

    // NOTE: This would normally be done in a storyboard, but the latter fails to auto-load the xib.
    static func modalMapViewControllerWithDelegate(delegate: MapViewControllerDelegate,
                                                   selectedMapItem: MKMapItem? = nil) -> NavigationController
    {
        guard delegate.respondsToSelector(Selector("dismissModalMapViewController:"))
              else { fatalError("Needs to implement dismissModalMapViewController:.") }

        let mapViewController = MapViewController(nibName: "MapViewController", bundle: MapViewController.bundle)
        mapViewController.delegate = delegate
        mapViewController.selectedMapItem = selectedMapItem

        mapViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: Label.NavigationBack.rawValue, style: .Plain,
            target: delegate, action: "dismissModalMapViewController:"
        )
        mapViewController.customizeNavigationItem()

        let navigationController = NavigationController(rootViewController: mapViewController)
        return navigationController
    }
    
}
