//
//  MCCoreDataRepositoryDeletion.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

public extension MCCoreDataRepository
{
    //MARK: Deletion
    
    ///### Delete objects contained into the specified array in a background thread
    ///- Parameter array: Specify an array of NSManagedObject or NSManagedObjectID
    ///- Parameter completionBlock: Completion block
    
    @objc public func delete(containedInArray array: [AnyObject], completionBlock: (() -> Void)?)
    {
        if array is [NSManagedObject] {
            self._delete(containedInArray: array as! [NSManagedObject], completionBlock: completionBlock)
        } else if array is [NSManagedObjectID] {
            self._deleteIDs(containedInArray: array as! [NSManagedObjectID], completionBlock: completionBlock)
        }
    }
    
    ///### Delete objects contained into the specified array in the current thread
    ///- Parameter array: Specify an array of NSManagedObject or NSManagedObjectID
    ///- Parameter MOC: a specific NSManagedObjectContext
    
    @objc public func delete(containedInArray array: [AnyObject], MOC moc: NSManagedObjectContext)
    {
        if array is [NSManagedObject] {
            self._delete(containedInArray: array as! [NSManagedObject], MOC: moc)
        } else if array is [NSManagedObjectID] {
            self._deleteIDs(containedInArray: array as! [NSManagedObjectID], MOC: moc)
        }
    }
}

internal extension MCCoreDataRepository
{
    
    internal func _delete(containedInArray array: [NSManagedObject],
                                                  MOC moc: NSManagedObjectContext) {
        
        for object: NSManagedObject in array {
            
            do {
                let managedObject = try moc.existingObjectWithID(object.objectID)
                moc.deleteObject(managedObject)
            } catch {
                let fetchError = error as NSError
                print("\(fetchError), \(fetchError.userInfo)")
            }
        }
    }
    
    internal func _delete(containedInArray array: [NSManagedObject],
                                                  completionBlock: (Void -> Void)?) {
        
        weak var weakSelf = self
        
        self.cdsManager.asyncWrite(operationBlock: { (MOC) in
            
            weakSelf?._delete(containedInArray: array, MOC: MOC)
            
            }, completion: {
                if let completionBlockUnwrapped = completionBlock {
                    completionBlockUnwrapped();
                }
        })
    }
    
    internal func _deleteIDs(containedInArray array: [NSManagedObjectID],
                                         MOC moc: NSManagedObjectContext) {
        
        for objectID: NSManagedObjectID in array {
            
            do {
                let managedObject = try moc.existingObjectWithID(objectID)
                moc.deleteObject(managedObject)
            } catch {
                let fetchError = error as NSError
                print("\(fetchError), \(fetchError.userInfo)")
            }
        }
    }
    
    internal func _deleteIDs(containedInArray array: [NSManagedObjectID],
                                         completionBlock: (Void -> Void)?) {
        
        weak var weakSelf = self
        
        self.cdsManager.asyncWrite(operationBlock: { (MOC) in
            
            weakSelf?._deleteIDs(containedInArray: array, MOC: MOC)
            
            }, completion: {
                if let completionBlockUnwrapped = completionBlock {
                    completionBlockUnwrapped();
                }
        })
    }
}