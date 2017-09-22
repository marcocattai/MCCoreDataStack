//
//  MCCoreDataRepositoryDeletion.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

public extension MCCoreDataRepository {
    // MARK: Deletion

    ///### Delete objects contained into the specified array in a background thread
    ///- Parameter array: Specify an array of NSManagedObject or NSManagedObjectID
    ///- Parameter completionBlock: Completion block

    @objc public func delete(containedInArray array: [AnyObject], completionBlock: (() -> Void)?) {
        if let objectArray = array as? [NSManagedObject] {
            self.deleteObjects(containedInArray: objectArray, completionBlock: completionBlock)
        } else if let objectIDArray = array as? [NSManagedObjectID] {
            self.deleteIDs(containedInArray: objectIDArray, completionBlock: completionBlock)
        }
    }

    ///### Delete objects contained into the specified array in the current thread
    ///- Parameter array: Specify an array of NSManagedObject or NSManagedObjectID
    ///- Parameter context: a specific NSManagedObjectContext

    @objc public func delete(containedInArray array: [AnyObject], context: NSManagedObjectContext) {
        if let objectArray = array as? [NSManagedObject] {
            self.deleteObjects(containedInArray: objectArray, context: context)
        } else if let objectIDArray = array as? [NSManagedObjectID] {
            self.deleteIDs(containedInArray: objectIDArray, context: context)
        }
    }
}

extension MCCoreDataRepository {

    func deleteObjects(containedInArray array: [NSManagedObject], context: NSManagedObjectContext) {
        for object: NSManagedObject in context.moveInContext(managedObjects: array) {
            context.delete(object)
        }
    }

    func deleteIDs(containedInArray array: [NSManagedObjectID], context: NSManagedObjectContext) {
        for object: NSManagedObject in context.existingObjecsWithIds(managedObjects: array) {
            context.delete(object)
        }
    }

    func deleteObjects(containedInArray array: [NSManagedObject], completionBlock: (() -> Void)?) {
        self.cdsManager.write(operationBlock: { [weak self] context in
            self?.deleteObjects(containedInArray: array, context: context)
        }, completion: { _ in
            completionBlock?()
        })
    }

    func deleteIDs(containedInArray array: [NSManagedObjectID], completionBlock: (() -> Void)?) {
        self.cdsManager.write(operationBlock: { [weak self] context in
            self?.deleteIDs(containedInArray: array, context: context)
        }, completion: { _ in
            completionBlock?()
        })
    }
}
