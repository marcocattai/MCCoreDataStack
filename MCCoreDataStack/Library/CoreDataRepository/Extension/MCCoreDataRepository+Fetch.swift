//
//  MCCoreDataRepositoryFetching.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

public extension MCCoreDataRepository {
        
    //MARK Fetching in currentQueue
    
    //MARK: Fetching
    ///### fetch all the objects by EntityName in the current thread
    ///- Parameter entityName: Name of the corresponding entity
    ///- Parameter context: ManagedObjectContext created in the current thread. If nil the call should be from the main Thread
    ///- Parameter resultType: this can be  .ManagedObject .ManagedObjectID .Dictionary .Count
    ///- Return: New NSManagedObject or nil
    
    public func fetch(entityName: String, context: NSManagedObjectContext, resultType: NSFetchRequestResultType) -> [AnyObject]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.resultType = resultType
        
        #if DEBUG
            fetchRequest.returnsObjectsAsFaults = false;
        #endif
        
        do {
            let results = try context.fetch(fetchRequest)
            
            return results as [AnyObject];
        } catch {
            //Nothing to do here
        }
        return []
    }

    
    ///### fetch all the object of a specific entityName, by Predicate, in the current thread
    ///- Parameter predicate: NSPredicate object
    ///- Parameter entityName: Name of the corresponding entity
    ///- Parameter context: ManagedObjectContext created in the current thread. If nil the call should be from the main Thread
    ///- Parameter resultType: this can be  .ManagedObject .ManagedObjectID .Dictionary .Count
    ///- Return: array of results
    
    public func fetch(byPredicate predicate: NSPredicate, entityName: String, context: NSManagedObjectContext, resultType: NSFetchRequestResultType) -> [AnyObject]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.predicate = predicate
        fetchRequest.resultType = resultType
        
        let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: context)
        
        #if DEBUG
            fetchRequest.returnsObjectsAsFaults = false;
        #endif

        var results: [AnyObject]? = nil
        fetchRequest.entity = entityDescription;
        
        do {
            results = try context.fetch(fetchRequest)
            
            return results
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
            //Nothing to do here
        }
        return []
    }
        
}
