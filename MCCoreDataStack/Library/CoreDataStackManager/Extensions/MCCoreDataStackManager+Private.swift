//
//  MCCoreDataStackManagerPrivate.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

private enum CDJournalMode: String {
    case WAL
    case DELETE
}

 extension MCCoreDataStackManager {

     func createPersistentStoreIfNeeded() {
        guard let model = model else {
            return
        }

        if let storeCoordinator = storeCoordinator {
            let stores = storeCoordinator.persistentStores
            let store = stores.filter { $0.url == self.storeURL }.first

            if store != nil {
                return
            }

        }

        self.storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    }

     func addSqliteStore(_ storeURL: URL, configuration: String?, completion: MCCoreDataAsyncCompletion?) {
        createPathToStoreFileIfNeccessary(storeURL)
        createContexts()

        //lass func global(qos: DispatchQoS.QoSClass)
        DispatchQueue.global().async {

            do {
                if let storeCoordinator = self.storeCoordinator {
                    var options = self.autoMigrationWithJournalMode(CDJournalMode.WAL.rawValue)
                    let sourceMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType,
                                                                                                      at: storeURL,
                                                                                                      options: nil)

                    // Check if we need a migration
                    if let metadata = sourceMetadata {
                        let destinationModel = storeCoordinator.managedObjectModel
                        if (!destinationModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)) {
                            options = self.autoMigrationWithJournalMode(CDJournalMode.DELETE.rawValue)
                        }
                    }

                    try storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                            configurationName: nil,
                                                            at: storeURL,
                                                            options: options)

                    self.isReady = true
                }
            } catch {
                print("Error migrating store")
            }

            completion?()
        }
    }
}

fileprivate extension MCCoreDataStackManager {

    fileprivate func createPathToStoreFileIfNeccessary(_ url: URL) {
        let path = url.deletingLastPathComponent().path

        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("\(error.localizedDescription)")
        }
    }

    fileprivate func autoMigrationWithJournalMode(_ mode: String) -> Dictionary<String, AnyObject> {
        var sqliteOptions = [String: AnyObject]()
        sqliteOptions["journal_mode"] = mode as AnyObject?

        var persistentStoreOptions = [String: AnyObject]()
        persistentStoreOptions[NSMigratePersistentStoresAutomaticallyOption] = true as AnyObject?
        persistentStoreOptions[NSInferMappingModelAutomaticallyOption] = true as AnyObject?
        persistentStoreOptions[NSSQLitePragmasOption] = sqliteOptions as AnyObject?

        return persistentStoreOptions
    }

    fileprivate func createContexts() {
        // https://www.cocoanetics.com/2012/07/multi-context-coredata/
        // create main thread context

        rootcontext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        rootcontext?.performAndWait { [weak self] in
            guard
                let weakSelf = self,
                let rootContext = weakSelf.rootcontext else
            {
                return
            }

            rootContext.persistentStoreCoordinator = weakSelf.storeCoordinator
            rootContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        }

        maincontext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        maincontext?.parent = rootcontext
    }
}
