//
//  NavigationController.swift
//  Eventual
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

@objc(ETNavigationController) class NavigationController: UINavigationController {
    
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
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }
    
    private func setUp() {
        self.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(!self.viewControllers.isEmpty, "Must have view controllers.")
        // Initial view controllers.
        EventManager.defaultManager().completeSetup()
        self.updateViewController(self.visibleViewController)
        // Temporary appearance changes.
        let subviews = self.navigationBar.subviews as [UIView]
        for view in subviews {
            view.backgroundColor = UIColor.clearColor()
        }
        // Custom bar border color.
        let height = self.navigationBar.frame.size.height +
                     UIApplication.sharedApplication().statusBarFrame.size.height
        self.navigationBar.setBackgroundImage( color_image( self.navigationBar.barTintColor!,
                size: CGSize(width: self.navigationBar.frame.size.width, height: height)),
            forBarMetrics: .Default)
        self.navigationBar.shadowImage = color_image( self.view.tintColor,
            size: CGSize(width: self.navigationBar.frame.size.width, height: 1.0))
    }

    // MARK: - UINavigationController
    
    override func supportedInterfaceOrientations() -> Int { // TODO: Framework error on the return type.
        if self.topViewController is EventViewController {
            return Int(UIInterfaceOrientationMask.Portrait.rawValue)
        }
        return super.supportedInterfaceOrientations()
    }
    
    // MARK: - View Controller Decoration
    
    private func updateViewController(viewController: UIViewController) {
        var style = self.defaultStyle
        var textColor = self.defaultTextColor
        if let conformingViewController = viewController as? NavigationAppearanceDelegate {
            if conformingViewController.wantsAlternateNavigationBarAppearance {
                style = .Black
                textColor = UIColor.whiteColor()
            }
        }
        UIView.animateWithDuration( NSTimeInterval(UINavigationControllerHideShowBarDuration),
            delay: 0.0, options: .CurveEaseInOut,
            animations: {
                self.navigationBar.barStyle = style
                if style == .Default {
                    self.navigationBar.barTintColor = UIColor.whiteColor()
                }
                if let titleView = viewController.navigationItem.titleView as? NavigationTitleViewProtocol {
                    if titleView is NavigationTitlePickerView {
                        textColor = AppearanceManager.defaultManager().darkGrayTextColor
                    }
                    titleView.textColor = textColor
                } else {
                    self.navigationBar.titleTextAttributes = [ NSForegroundColorAttributeName: textColor ]
                }
            },
            completion: nil
        )
    }
    
}

// MARK: - UINavigationControllerDelegate

extension NavigationController: UINavigationControllerDelegate {
    
    func navigationController(navigationController: UINavigationController!,
         willShowViewController viewController: UIViewController!,
         animated: Bool)
    {
        self.updateViewController(viewController)
    }
    
    func navigationController(navigationController: UINavigationController!,
         animationControllerForOperation operation: UINavigationControllerOperation,
         fromViewController fromVC: UIViewController!,
         toViewController toVC: UIViewController!)
         -> UIViewControllerAnimatedTransitioning!
    {
        if let controller = self.transitioningDelegate as? UIViewControllerAnimatedTransitioning {
            return controller
        }
        return nil
    }
    
    func navigationController(navigationController: UINavigationController!,
         interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning!)
         -> UIViewControllerInteractiveTransitioning!
    {
        if let controller = self.transitioningDelegate as? UIViewControllerInteractiveTransitioning {
            return controller
        }
        return nil
    }
    
}