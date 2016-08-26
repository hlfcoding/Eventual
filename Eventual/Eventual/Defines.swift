//
//  Defines.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

// MARK: - Error

let ErrorDomain = "ErrorDomain"

enum ErrorCode: Int {
    case Generic = 0, InvalidObject
}

// MARK: - Notifications

let EntityDeletionAction = "DoEntityDeletion"

let EntityAccessNotification = "DidEntityAccess"
let EntityFetchOperationNotification = "DidEntityFetchOperation"
let EntityUpdateOperationNotification = "DidEntityUpdateOperation"

// MARK: - Types

typealias Attributes = [String: AnyObject]
typealias KeyPathsMap = [String: AnyObject]
typealias UserInfo = [String: AnyObject]
typealias ValidationResults = [String: String]
