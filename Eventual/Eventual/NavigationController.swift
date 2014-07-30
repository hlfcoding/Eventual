//
//  NavigationController.swift
//  Eventual
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETNavigationController) class NavigationController: UINavigationController {
    
    private let defaultStyle: UIBarStyle = .Default
    private let defaultTextColor = AppearanceManager.defaultManager().darkGrayTextColor
    
    init(rootViewController: UIViewController!) {
        super.init(rootViewController: rootViewController);
        self.setUp()
    }
    init(navigationBarClass: AnyClass!, toolbarClass: AnyClass!) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        self.setUp()
    }
    init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setUp()
    }
    init(coder aDecoder: NSCoder!) {
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
        if navigationItem.leftBarButtonItem.title == ETLabel.NavigationBack.toRaw() {
            navigationItem.et_setUpLeftBarButtonItem()
        }
        // Initial view controllers.
        EventManager.defaultManager().completeSetup()
        self.updateViewController(self.visibleViewController)
    }
    
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
            delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut,
            animations: { () in
                self.navigationBar.barStyle = style
                if style == .Default {
                    self.navigationBar.barTintColor = UIColor(white: 1.0, alpha: 0.01)
                }
                if let titleView = viewController.navigationItem.titleView as? NavigationCustomTitleView {
                    titleView.textColor = textColor
                } else {
                    self.navigationBar.titleTextAttributes = [ NSForegroundColorAttributeName: textColor ]
                }
            },
            completion: nil
        )
    }
    
}

extension NavigationController : UINavigationControllerDelegate {
    
    // TODO.
    
}