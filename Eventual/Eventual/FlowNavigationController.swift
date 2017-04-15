//
//  FlowNavigationController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class FlowNavigationController: UINavigationController {

    var dataSource: MonthEventDataSource?

    var supportedSegues: [Segue] { return [] }

    override func viewDidLoad() {
        super.viewDidLoad()

        Action.prepareSegueForDescendant.verify(performer: self)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == Action.prepareSegueForDescendant.selector(),
            let sender = sender as? CoordinatedViewController {
            guard let identifier = sender.currentSegue?.identifier else {
                assertionFailure()
                return false
            }
            return supportedSegues.contains(Segue(rawValue: identifier)!)
        }
        return super.canPerformAction(action, withSender: sender)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        restoreState()
    }

    func ensureAccess(ensuredOperation: @escaping () -> Void) {
        let manager = dataSource!.manager!
        guard manager.hasAccess else {
            manager.requestAccess(completion: ensuredOperation)
            return
        }
        ensuredOperation()
    }

    func prepareSegueForDescendant(_ sender: Any?) {
        let viewController = sender as! CoordinatedViewController
        let (_, _, _, destinationContainer, _) = unpackSegue(for: viewController)
        if let navigationController = destinationContainer as? FlowNavigationController {
            navigationController.dataSource = dataSource
        }
    }

    func restoreState() {
        dataSource = AppDelegate.sharedDelegate.flowEvents
    }

    func unpackSegue(for viewController: CoordinatedViewController) -> (
        type: Segue, destination: UIViewController, source: UIViewController,
        destinationContainer: UINavigationController?, sourceContainer: UINavigationController?)
    {
        let segue = viewController.currentSegue!
        let type = Segue(rawValue: segue.identifier!)!
        let destinationContainer = segue.destination as? UINavigationController
        let destination = destinationContainer?.topViewController ?? segue.destination
        let sourceContainer = segue.source.navigationController
        return (type, destination, segue.source, destinationContainer, sourceContainer)
    }

}
