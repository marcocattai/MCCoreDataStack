//
//  MCCoreDataRepositoryDeletion.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

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