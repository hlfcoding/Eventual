//
//  TabBarController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {

    override var selectedIndex: Int {
        didSet {
            prepareTabTransition(for: viewControllers![selectedIndex])
        }
    }

    private var tabTransition: CarouselTransition?

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        tabTransition = CarouselTransition()
    }

    func prepareTabTransition(for viewController: UIViewController) {
        guard let tabTransition = tabTransition else { return }
        tabTransition.currentViewController = viewController
    }

    // MARK: - UITabBarControllerDelegate

    func tabBarController(_ tabBarController: UITabBarController,
                          animationControllerForTransitionFrom fromVC: UIViewController,
                          to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return tabTransition
    }

    func tabBarController(_ tabBarController: UITabBarController,
                          interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return tabTransition
    }

}
