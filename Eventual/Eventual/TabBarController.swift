//
//  TabBarController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController, CarouselTransitionDelegate, UITabBarControllerDelegate {

    override var selectedIndex: Int {
        didSet {
            prepareTabTransition(for: viewControllers![selectedIndex])
        }
    }

    private var tabTransition: CarouselTransition?

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        tabTransition = CarouselTransition(delegate: self)
    }

    func prepareTabTransition(for viewController: UIViewController) {
        guard let tabTransition = tabTransition else { return }
        tabTransition.selectedView = viewController.view
    }

    // MARK: - CarouselTransitionDelegate

    var carouselContainerView: UIView { return view }
    var selectedView: UIView? { return selectedViewController?.view }

    func shiftSelectedIndex() -> Bool {
        switch tabTransition!.direction {
        case .right:
            guard selectedIndex + 1 < viewControllers!.count else { return false }
            selectedIndex += 1
        case .left:
            guard selectedIndex - 1 >= 0 else { return false }
            selectedIndex -= 1
        }
        return true
    }

    // MARK: - UITabBarControllerDelegate

    func tabBarController(_ tabBarController: UITabBarController,
                          animationControllerForTransitionFrom fromVC: UIViewController,
                          to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return tabTransition
    }

    func tabBarController(_ tabBarController: UITabBarController,
                          interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return (tabTransition?.isInteractivelyTransitioning == true) ? tabTransition : nil
    }

}
