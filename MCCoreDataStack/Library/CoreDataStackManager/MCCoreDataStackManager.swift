//
//  MCCoreDataStackManager.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData


public typealias EmptyResult = () throws -> ()
public typealias MCCoreDataAsyncResult = (inner: EmptyResult) -> Void
public typealias MCCoreDataAsyncCompletion = () -> ()

///### Internal Error
public enum CoreDataStackError: ErrorType {
    case InternalError(description: String)
}

///### This helper gives you back the path for the Library, Documents and Tmp folders

public struct StackManagerHelper {
    
    struct Path {
        static let LibraryFolder = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)[0] as String
        static let DocumentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        static let TmpFolder = NSTemporaryDirectory()
    }
}

@objc public class MCCoreDataStackManager : NSObject {
    
    //MARK: Public vars
    
    ///### Root ManagedObjectContext where the persistentStore is attached (PrivateQueueConcurrencyType)
    public var rootMOC: NSManagedObjectContext? = nil

    ///### Main ManagedObjectContext. Iis parentContext is rootMOC
    public var mainMOC: NSManagedObjectContext? = nil
    
    //MARK: Private vars
    
    @objc let accessSemaphore = dispatch_group_create()

    private var name: String = ""

    internal(set) public var isReady: Bool = false
    
    //MARK: Internal vars
    
    ///### Current Store URL
    private(set) public var storeURL: NSURL? = nil
    internal var model: NSManagedObjectModel? = nil
    internal var PSC: NSPersistentStoreCoordinator? = nil
    
    #if TARGET_OS_IPHONE
    internal var bkgPersistTask: UIBackgroundTaskIdentifier? = nil
    internal var areObserversRegistered: Bool = false
    
    //MARK: De-init
    
    deinit {
        if areObserversRegistered {
            self.deregisterObservers()
        }
    }
    #endif
    
    //MARK: Initializers
    
    ///### Init method
    ///- Parameter domain: name of the current domain
    ///- Parameter model: NSManagedObjectModel

    @objc public init?(domain name: String, model: NSManagedObjectModel) {
        self.name = name
        self.model = model
        
        if self.name.isEmpty { return nil }
    }
    
    ///### Init method
    ///- Parameter domainName: completion Block
    ///- Parameter model: URL for the current data model

    @objc public convenience init?(domainName: String, model URL: NSURL?)
    {
        guard let model = NSManagedObjectModel.init(contentsOfURL: URL!) else {
            
            fatalError("Error initializing mom from: \(URL)")
        }
        
        self.init(domain: domainName, model: model)
    }
    
    ///### This method delete the current persistent Store
    ///- Parameter completionBlock: completion Block

    @objc public func deleteStore(completionBlock completionBlock: (() -> Void)?)
    {
        let store = self.PSC?.persistentStoreForURL(self.storeURL!)
        if let storeUnwrapped = store {
            do {
                try self.PSC?.removePersistentStore(storeUnwrapped)
            } catch {}
            
            if NSFileManager.defaultManager().fileExistsAtPath((self.storeURL?.path)!) {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath((self.storeURL?.path)!)
                    
                    if let completionUnWrapped = completionBlock {
                        completionUnWrapped();
                    }
                } catch { }
            }
        }
    }
    
    //MARK: Private
    
    private func isPersistentStoreAvailable(completionBlock:MCCoreDataAsyncCompletion?)
    {
        if self.isReady {
            if let completionBlockUnwrapped = completionBlock {
                completionBlockUnwrapped();
            }
        } else {
            dispatch_group_wait(self.accessSemaphore, 10)
            //FIXME: PersistentStore needs
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                if let completionBlockUnwrapped = completionBlock {
                    completionBlockUnwrapped();
                }
            }
        }
    }
    
    //MARK: Configuration
    
    ///### Configure the current coreDataStack
    ///- Parameter storeURL: the URL of your sqlite file. See StackManagerHelper for Help
    ///- Parameter configuration: configuration Name
    ///- Return: Bool
    @objc public func configure(storeURL storeURL: NSURL, configuration: String?) -> Bool {
        
        guard storeURL.absoluteString.isEmpty == false else {
            return false
        }
        
        self.storeURL = storeURL
        
        self.createPersistentStoreIfNeeded()
        
        dispatch_group_enter(self.accessSemaphore);

        let success = self.addSqliteStore(self.storeURL!, configuration: configuration, completion: {
            self.isReady = true
            dispatch_group_leave(self.accessSemaphore);
        })

        
        return success
    }

    //MARK: Private MOC Creation

    ///### Create a private NSManagedObjectContext of type PrivateQueueConcurrencyType with mainMOC as parentContext
    ///- Return: New NSManagedObjectContext

    @objc public func createPrivateMOC() -> NSManagedObjectContext
    {
        
        let moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        
        moc.performBlockAndWait({ [weak self] in
            
            guard let strongSelf = self else { return }
            
            moc.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyObjectTrumpMergePolicyType)
            if ((strongSelf.mainMOC) != nil) {
                moc.parentContext = strongSelf.mainMOC
            }
            });
        
        return moc
    }
    
    //MARK: Read
    
    ///### Helper to perform a background operation on a new privateMOC
    ///- Parameter operationBlock: The operation block to be performed in background

    @objc public func asyncRead(operationBlock operationBlock: ((MOC: NSManagedObjectContext) -> Void)?)
    {
        self.isPersistentStoreAvailable {
            let bkgMOC = self.createPrivateMOC()
            
            bkgMOC.performBlock({ () -> Void in
                
                if let operationBlockUnWrapped = operationBlock {
                    operationBlockUnWrapped(MOC: bkgMOC)
                }
            })
        }
    }
    
    //MARK: Write

    ///### Helper to perform a background operation, on a new privateMOC, and automatically save the changes
    ///- Parameter operationBlock: The operation block to be performed in background

    @objc public func asyncWrite(operationBlock operationBlock: ((MOC: NSManagedObjectContext) -> Void)?, completion completionBlock: (() -> Void)?)
    {
        self.isPersistentStoreAvailable {
            let bkgMOC = self.createPrivateMOC()
            
            bkgMOC.performBlock({ [weak self] in
                guard let strongSelf = self else { return }
                
                if let operationBlockUnWrapped = operationBlock {
                    operationBlockUnWrapped(MOC: bkgMOC)
                }
                strongSelf.save(MOC: bkgMOC, completionBlock: completionBlock)
                
            })
        }
    }
    
    ///### Helper to perform an operation on the main MOC, mainThread, and automatically save the changes
    ///- Parameter operationBlock: The operation block to be performed in background

    @objc public func write(operationBlock operationBlock: ((MOC: NSManagedObjectContext) -> Void)?, completion completionBlock: (() -> Void)?)
    {
        self.isPersistentStoreAvailable {
            self.mainMOC!.performBlock({ [weak self] in
                guard let strongSelf = self else { return }
                
                if let operationBlockUnWrapped = operationBlock {
                    operationBlockUnWrapped(MOC: (strongSelf.mainMOC)!)
                }
                
                strongSelf.save(MOC: strongSelf.mainMOC!, completionBlock: completionBlock)
            })
        }
    }
    
    ///### Helper to perform an operation on the main MOC in the mainThread
    ///- Parameter operationBlock: The operation block to be performed in background

    @objc public func performMainThreadOperation(operationBlock operationBlock: ((MOC: NSManagedObjectContext) -> Void)?)
    {
        self.isPersistentStoreAvailable {
            self.mainMOC!.performBlock({ [weak self] in
                guard let strongSelf = self else { return }
                
                if let operationBlockUnWrapped = operationBlock {
                    operationBlockUnWrapped(MOC: (strongSelf.mainMOC)!)
                }
            })
        }
    }
    
    //MARK: Save

    ///### Save the specified context and all its parents
    ///- Parameter completionBlock: completion Block

    @objc public func save(MOC MOC: NSManagedObjectContext, completionBlock: (() -> Void)?) -> Void {
        
        weak var weakSelf = self
        
        MOC.save(completionBlock: { (inner) in
            do {
                try inner()
                
                weakSelf!.mainMOC?.save(completionBlock: { (inner) in
                    do {
                        try inner()
                        
                        if let coordinator = self.rootMOC!.persistentStoreCoordinator {
                            
                            if coordinator.persistentStores.isEmpty {
                                if let exCompletionBlock = completionBlock {
                                    exCompletionBlock();
                                }
                                return
                            }
                        }
                        
                        weakSelf!.rootMOC?.save(completionBlock: { (inner) in
                            do {
                                try inner()
                                
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    if let exCompletionBlock = completionBlock {
                                        exCompletionBlock();
                                    }
                                })
                                
                            } catch let error {
                                print(error)
                            }
                            
                        })
                        
                    } catch let error {
                        print(error)
                    }
                    
                })
                
            } catch let error {
                print(error)
            }
        })
    }
    
    //MARK: Notifications
    
    @objc private func contextWillSave()
    {
        //Not implemented yet
    }
    
    @objc private func contextDidSave(notification: NSNotification)
    {
        //Not implemented yet
    }
}
