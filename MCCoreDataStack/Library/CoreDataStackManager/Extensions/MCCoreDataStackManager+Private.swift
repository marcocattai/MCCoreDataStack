//
//  MCCoreDataStackManagerPrivate.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import Swift
import CoreData

enum CDJournalMode  : String {
    case WAL = "WAL"
    case DELETE = "DELETE"
}

internal extension MCCoreDataStackManager
{
    
    internal func createPersistentStoreIfNeeded()
    {
        var shouldCreateStack: Bool = false
        
        if let unwrappedPSC = self.PSC {
            
            if unwrappedPSC.persistentStores.count == 0 {
                shouldCreateStack = true;
            } else {
                
                let found = unwrappedPSC.persistentStores.filter{ $0.URL == self.storeURL }.first
                
                if found == nil {
                    shouldCreateStack = true
                }
            }
        } else {
            shouldCreateStack = true
        }
        
        if shouldCreateStack {
            self.PSC = NSPersistentStoreCoordinator(managedObjectModel: self.model!)
        }
    }
    
    internal func createPathToStoreFileIfNeccessary(URL: NSURL)
    {
        let pathToStore = URL.URLByDeletingLastPathComponent!
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(pathToStore.path!, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("\(error.localizedDescription)")
        }
    }
    
    internal func autoMigrationWithJournalMode(mode: String) -> Dictionary<NSObject, AnyObject>
    {
        
        var sqliteOptions = Dictionary<NSObject, AnyObject>()
        sqliteOptions["journal_mode"] = mode
        
        var persistentStoreOptions = Dictionary<NSObject, AnyObject>()
        persistentStoreOptions[NSMigratePersistentStoresAutomaticallyOption] = true
        persistentStoreOptions[NSInferMappingModelAutomaticallyOption] = true
        persistentStoreOptions[NSSQLitePragmasOption] = sqliteOptions
        return persistentStoreOptions
    }
    
    internal func addSqliteStore(storeURL: NSURL, configuration: String?, completion: MCCoreDataAsyncCompletion?) -> Bool
    {
        
        var options = self.autoMigrationWithJournalMode("WAL")
        
        self.createPathToStoreFileIfNeccessary(storeURL);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            
            do {
                
                let sourceMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(NSSQLiteStoreType, URL: storeURL, options:nil)
                
                let destinationModel = self.PSC?.managedObjectModel
                
                if let _destinationModel = destinationModel {
                    // Check if we need a migration
                    
                    if let metadata = sourceMetadata {
                        
                        let isModelCompatible = _destinationModel.isConfiguration(nil, compatibleWithStoreMetadata: metadata);
                        
                        if (!isModelCompatible)
                        {
                            options = self.autoMigrationWithJournalMode("DELETE")
                        }
                    }
                }
                
                
                try self.PSC!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
                
                self.isReady = true
                
                if let completionBlock = completion {
                    completionBlock();
                }
                
            } catch {
                print("Error migrating store")
            }
        }
        //https://www.cocoanetics.com/2012/07/multi-context-coredata/
        // create main thread context
        
        self.rootcontext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        
        self.rootcontext!.performBlockAndWait({ [weak self] in
            self!.rootcontext!.persistentStoreCoordinator = self!.PSC;
            self!.rootcontext!.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyObjectTrumpMergePolicyType)
        });
        
        self.maincontext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        self.maincontext?.parentContext = self.rootcontext
        
        return true;
    }

}
