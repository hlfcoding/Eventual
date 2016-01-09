//
//  NavigationController.swift
//  Eventual
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

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

    deinit {
        self.tearDown()
    }

    private func setUp() {
        self.delegate = self
    }
    private func tearDown() {}

    override func viewDidLoad() {
        super.viewDidLoad()
        // Initial view controllers.
        EventManager.defaultManager.completeSetup()
        // Temporary appearance changes.
        for view in self.navigationBar.subviews {
            view.backgroundColor = UIColor.clearColor()
        }
        // Custom bar border color, at the cost of translucency.
        let height = self.navigationBar.frame.size.height +
                     UIApplication.sharedApplication().statusBarFrame.size.height
        let image = color_image(
            UIColor(white: 1.0, alpha: 0.95),
            size: CGSize(width: self.navigationBar.frame.size.width, height: height)
        )
        self.navigationBar.setBackgroundImage(image, forBarMetrics: .Default)
        self.navigationBar.shadowImage = color_image( self.view.tintColor,
            size: CGSize(width: self.navigationBar.frame.size.width, height: 1.0))
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
        if let controller = self.transitioningDelegate as? UIViewControllerAnimatedTransitioning {
            return controller
        }
        return nil
    }

    func navigationController(navigationController: UINavigationController,
         interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning)
         -> UIViewControllerInteractiveTransitioning?
    {
        if let controller = self.transitioningDelegate as? UIViewControllerInteractiveTransitioning {
            return controller
        }
        return nil
    }

}

// MARK: - Modal View Controllers

extension NavigationController {

    // NOTE: This would normally be done in a storyboard, but the latter fails to auto-load the xib.
    static func modalMapViewControllerWithDelegate(delegate: MapViewControllerDelegate) -> NavigationController {
        guard delegate.respondsToSelector(Selector("dismissModalMapViewController:"))
              else { fatalError("Needs to implement dismissModalMapViewController:.") }

        let mapViewController = MapViewController(nibName: "MapViewController", bundle: MapViewController.bundle)
        mapViewController.delegate = delegate
        mapViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: Label.NavigationBack.rawValue, style: .Plain,
            target: delegate, action: "dismissModalMapViewController:"
        )
        mapViewController.customizeNavigationItem()

        let navigationController = NavigationController(rootViewController: mapViewController)
        return navigationController
    }
    
}
