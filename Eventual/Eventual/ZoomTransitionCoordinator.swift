//
//  ZoomTransitionCoordinator.swift
//  Eventual
//
//  Created by Peng Wang on 7/20/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETZoomTransitionCoordinator) final class ZoomTransitionCoordinator: NSObject
    /*
    , UIViewControllerTransitioningDelegate
    , UIViewControllerTransitionCoordinator
    , UIViewControllerTransitionCoordinatorContext
    , UIViewControllerAnimatedTransitioning
    , UIViewControllerInteractiveTransitioning
    */
{
    weak var zoomContainerView: UIView?
    weak var zoomedOutView: UIView?
    var zoomedOutFrame: CGRect!
    
    var zoomDuration: NSTimeInterval!
    var zoomCompletionCurve: UIViewAnimationCurve!
    var zoomReversed: Bool!
    var zoomInteractive: Bool!
    
    init() {
        super.init()
        self.setToInitialContext()
    }
    
    private func setToInitialContext() {}
}