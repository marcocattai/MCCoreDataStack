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

internal extension MCCoreDataStackManager {
    
    internal func createPersistentStoreIfNeeded() {
        var shouldCreateStack: Bool = false
        
        if let unwrappedPSC = self.PSC {
            
            if unwrappedPSC.persistentStores.count == 0 {
                shouldCreateStack = true;
            } else {
                
                let found = unwrappedPSC.persistentStores.filter{ $0.url == self.storeURL }.first
                
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
    
    internal func createPathToStoreFileIfNeccessary(_ URL: Foundation.URL) {
        let pathToStore = URL.deletingLastPathComponent()
        
        do {
            try FileManager.default.createDirectory(atPath: pathToStore.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("\(error.localizedDescription)")
        }
    }
    
    internal func autoMigrationWithJournalMode(_ mode: String) -> Dictionary<String, AnyObject> {
        
        var sqliteOptions = Dictionary<String, AnyObject>()
        sqliteOptions["journal_mode"] = mode as AnyObject?
        
        var persistentStoreOptions = Dictionary<String, AnyObject>()
        persistentStoreOptions[NSMigratePersistentStoresAutomaticallyOption] = true as AnyObject?
        persistentStoreOptions[NSInferMappingModelAutomaticallyOption] = true as AnyObject?
        persistentStoreOptions[NSSQLitePragmasOption] = sqliteOptions as AnyObject?
        return persistentStoreOptions
    }
    
    internal func addSqliteStore(_ storeURL: URL, configuration: String?, completion: MCCoreDataAsyncCompletion?) {
        
        var options = self.autoMigrationWithJournalMode("WAL")
        
        self.createPathToStoreFileIfNeccessary(storeURL);
        //lass func global(qos: DispatchQoS.QoSClass)
        DispatchQueue.global().async {
            
            do {
                
                let sourceMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options:nil)
                
                let destinationModel = self.PSC?.managedObjectModel
                
                if let _destinationModel = destinationModel {
                    // Check if we need a migration
                    
                    if let metadata = sourceMetadata {
                        
                        let isModelCompatible = _destinationModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata);
                        
                        if (!isModelCompatible)
                        {
                            options = self.autoMigrationWithJournalMode("DELETE")
                        }
                    }
                }
                
                
                try self.PSC!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
                
                self.isReady = true

                
            } catch {
                print("Error migrating store")
            }

            completion?()
        }

        //https://www.cocoanetics.com/2012/07/multi-context-coredata/
        // create main thread context

        self.rootcontext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        self.rootcontext!.performAndWait({ [weak self] in
            self!.rootcontext!.persistentStoreCoordinator = self!.PSC;
            self!.rootcontext!.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        });
        
        self.maincontext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.maincontext?.parent = self.rootcontext
    }

}
