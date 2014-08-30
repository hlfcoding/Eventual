//
//  NavigationController.swift
//  Eventual
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETNavigationController) class NavigationController: UINavigationController {
    
    // MARK: Private
    
    private let defaultStyle: UIBarStyle = .Default
    private lazy var defaultTextColor: UIColor! = {
        return AppearanceManager.defaultManager().darkGrayTextColor
    }()
    
    // MARK: - Initializers
    
    override init(rootViewController: UIViewController!) {
        super.init(rootViewController: rootViewController)
        self.setUp()
    }
    override init(navigationBarClass: AnyClass!, toolbarClass: AnyClass!) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        self.setUp()
    }
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
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
        self.completeSetup()
    }
    
    private func completeSetup() {
        // Custom back button.
        assert(!self.viewControllers.isEmpty, "Must have view controllers.")
        let rootViewController = self.viewControllers[0] as UIViewController
        let navigationItem = rootViewController.navigationItem
        if let buttonItem = navigationItem.leftBarButtonItem {
            if buttonItem.title == ETLabel.NavigationBack.toRaw() {
                navigationItem.et_setUpLeftBarButtonItem()
            }
        }
        // Initial view controllers.
        EventManager.defaultManager().completeSetup()
        self.updateViewController(self.visibleViewController)
        // Temporary appearance changes.
        let subviews = self.navigationBar.subviews as [UIView]
        for view in subviews {
            view.backgroundColor = UIColor.clearColor()
        }
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
                    self.navigationBar.barTintColor = UIColor(white: 1.0, alpha: 0.01)
                }
                if let titleView = viewController.navigationItem.titleView as? NavigationTitleViewProtocol {
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