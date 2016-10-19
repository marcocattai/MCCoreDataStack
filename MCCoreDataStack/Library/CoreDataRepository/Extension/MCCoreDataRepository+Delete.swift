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
    //MARK: Deletion
    
    ///### Delete objects contained into the specified array in a background thread
    ///- Parameter array: Specify an array of NSManagedObject or NSManagedObjectID
    ///- Parameter completionBlock: Completion block
    
    @objc public func delete(containedInArray array: [AnyObject], completionBlock: (() -> Void)?) {
        if array is [NSManagedObject] {
            self._delete(containedInArray: array as! [NSManagedObject], completionBlock: completionBlock)
        } else if array is [NSManagedObjectID] {
            self._deleteIDs(containedInArray: array as! [NSManagedObjectID], completionBlock: completionBlock)
        }
    }
    
    ///### Delete objects contained into the specified array in the current thread
    ///- Parameter array: Specify an array of NSManagedObject or NSManagedObjectID
    ///- Parameter context: a specific NSManagedObjectContext
    
    @objc public func delete(containedInArray array: [AnyObject], context: NSManagedObjectContext) {
        if array is [NSManagedObject] {
            self._delete(containedInArray: array as! [NSManagedObject], context: context)
        } else if array is [NSManagedObjectID] {
            self._deleteIDs(containedInArray: array as! [NSManagedObjectID], context: context)
        }
    }
}

internal extension MCCoreDataRepository {
    
    internal func _delete(containedInArray array: [NSManagedObject], context: NSManagedObjectContext) {
        
        let objs = context.moveInContext(managedObjects: array)
        
        for object: NSManagedObject in objs {
            
            context.delete(object)
        }        
    }
    
    internal func _deleteIDs(containedInArray array: [NSManagedObjectID], context: NSManagedObjectContext) {

        let objs = context.existingObjecsWithIds(managedObjects: array)
        
        for object: NSManagedObject in objs {
            
            context.delete(object)
        }
    }
    
    internal func _delete(containedInArray array: [NSManagedObject],
                                           completionBlock: ((Void) -> Void)?) {
        
        weak var weakSelf = self
        
        self.cdsManager.write(operationBlock: { (context) in
            
            weakSelf?._delete(containedInArray: array, context: context)
            
        }) { (error) in
            
            if let completionBlockUnwrapped = completionBlock {
                completionBlockUnwrapped();
            }
        }
    }

    internal func _deleteIDs(containedInArray array: [NSManagedObjectID],
                                         completionBlock: ((Void) -> Void)?) {
        
        weak var weakSelf = self
        
        self.cdsManager.write(operationBlock: { (context) in
            weakSelf?._deleteIDs(containedInArray: array, context: context)

        }) { (error) in
            if let completionBlockUnwrapped = completionBlock {
                completionBlockUnwrapped();
            }
        }
    }
}
