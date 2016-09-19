//
//  NSManagedObjectContext+Fetch.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 31/05/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    //MARK: Fetch existing Objects

    ///### fetch all the objects from an array of NSManagedObjectID
    ///- Parameter managedObjects: Array of NSManagedObjectIDs
    ///- Return: Array of NSManagedObjects

    @objc public func existingObjecsWithIds(managedObjects objectIDArray:[NSManagedObjectID]) -> [NSManagedObject] {
        
        var objects: [NSManagedObject] = []
        
        for objectID in objectIDArray {
            
            if objectID.isKind(of: NSManagedObjectID.self) {
                
                let mo = self.object(with: objectID)
                objects.append(mo)
                
            }
        }
        return objects
    }
    
    ///### fetch all the objects from an array of NSManagedObjects
    ///- Parameter managedObjects: Array of NSManagedObjects
    ///- Return: Array of NSManagedObjectIDs

    @objc public func existingIdsWith(managedObjects objectIDArray:[NSManagedObject]) -> [NSManagedObjectID] {
        
        var objects: [NSManagedObjectID] = []
        
        for object in objectIDArray {
            
            if object.isKind(of: NSManagedObject.self) {
                
                objects.append(object.objectID)
                
            }
        }
        return objects
    }
    
    ///### Move array of NSManagedObject in the current Managed Object Context
    ///- Parameter managedObjects: Array of NSManagedObjects
    ///- Return: Array of NSManagedObjects in the current context

    @objc public func moveInContext(managedObjects objectIDArray:[NSManagedObject]) -> [NSManagedObject] {
        
        var objects: [NSManagedObject] = []
        
        for object in objectIDArray {
            
            if object.isKind(of: NSManagedObject.self) {
                
                let mo = self.object(with: object.objectID)
                objects.append(mo)
                
            }
        }
        return objects
    }
}
