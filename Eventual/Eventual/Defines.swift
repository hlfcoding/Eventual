//
//  Defines.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import Foundation

// MARK: - Error

let ErrorDomain = "ErrorDomain"

enum ErrorCode: Int {
    case Generic = 0, InvalidObject
}

// MARK: - Notifications

extension NSNotification.Name {

    static let EntityAccess = NSNotification.Name("DidEntityAccess")
    static let EntityFetchOperation = NSNotification.Name("DidEntityFetchOperation")
    static let EntityUpdateOperation = NSNotification.Name("DidEntityUpdateOperation")

}

// MARK: - Types

typealias Attributes = [String: AnyObject]
typealias KeyPathsMap = [String: AnyObject]
typealias UserInfo = [String: AnyObject]
typealias ValidationResults = [String: String]
