//
//  MCCoreDataRepositoryFetching.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

internal extension MCCoreDataRepository
{
        
    //MARK Fetching in currentQueue
    
    internal func _fetchAllObjectInCurrentQueue(entityName: String, MOC: NSManagedObjectContext?, resultType: NSFetchRequestResultType) -> [AnyObject]?
    {
        let fetchRequest = NSFetchRequest.init(entityName: entityName)
        fetchRequest.resultType = resultType
        
        #if DEBUG
            fetchRequest.returnsObjectsAsFaults = false;
        #endif
        var managedObjectContext = MOC
        if managedObjectContext == nil {
            managedObjectContext = self.coreDataStackManager?.mainMOC
        }
        
        do {
            let results = try managedObjectContext!.executeFetchRequest(fetchRequest)
            
            return results;
        } catch {
            //Nothing to do here
        }
        return []
    }

    internal func _fetchObjectsInCurrentQueue(byPredicate predicate: NSPredicate, entityName: String, MOC: NSManagedObjectContext?, resultType: NSFetchRequestResultType) -> [AnyObject]?
    {
        let fetchRequest = NSFetchRequest.init()
        fetchRequest.predicate = predicate
        fetchRequest.resultType = resultType
        
        var managedObjectContext = MOC
        if managedObjectContext == nil {
            managedObjectContext = self.coreDataStackManager?.mainMOC
        }

        let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedObjectContext!)
        
        #if DEBUG
            fetchRequest.returnsObjectsAsFaults = false;
        #endif

        var results: [AnyObject]? = nil
        fetchRequest.entity = entityDescription;
        
        do {
            results = try managedObjectContext!.executeFetchRequest(fetchRequest)
            
            return results
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
            //Nothing to do here
        }
        return []
    }
        
}
