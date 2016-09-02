//
//  MCCoreDataStackManager.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

public typealias MCCoreDataAsyncResult = (inner: () throws -> ()) -> Void
public typealias MCCoreDataAsyncCompletion = () -> ()

///### Internal Error
public enum CoreDataStackError: ErrorType {
    case InternalError(description: String)
}

struct Constants {
    static let DomainName = "MCCoreDataStack"
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
    public var rootcontext: NSManagedObjectContext? = nil

    ///### Main ManagedObjectContext. Iis parentContext is rootcontext
    public var maincontext: NSManagedObjectContext? = nil
    
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

    //MARK: Private context Creation

    ///### Create a private NSManagedObjectContext of type PrivateQueueConcurrencyType with maincontext as parentContext
    ///- Return: New NSManagedObjectContext

    @objc public func createPrivatecontext() -> NSManagedObjectContext
    {
        
        let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        
        context.performBlockAndWait({ [weak self] in
            
            guard let strongSelf = self else { return }
            
            context.mergePolicy = NSMergePolicy(mergeType: .MergeByPropertyObjectTrumpMergePolicyType)
            if ((strongSelf.maincontext) != nil) {
                context.parentContext = strongSelf.maincontext
            }
            });
        
        return context
    }
    
    //MARK: Read
    
    ///### Helper to perform a background operation on a new privatecontext
    ///- Parameter operationBlock: The operation block to be performed in background

    @objc private func syncBkgRead(context:NSManagedObjectContext, operationBlock: ((context: NSManagedObjectContext) -> Void)?)
    {
        self.isPersistentStoreAvailable {
            
            context.performBlockAndWait({ () -> Void in
                
                if let operationBlockUnWrapped = operationBlock {
                    operationBlockUnWrapped(context: context)
                }
            })
        }
    }

    @objc private func syncBkgWrite(context:NSManagedObjectContext, operationBlock: ((context: NSManagedObjectContext) -> Void)?, completion completionBlock: ((NSError?) -> Void)?)
    {
        self.isPersistentStoreAvailable {
            
            context.performBlockAndWait({ [weak self] in
                guard let strongSelf = self else { return }
                
                if let operationBlockUnWrapped = operationBlock {
                    operationBlockUnWrapped(context: context)
                }
                strongSelf.save(context: context, completionBlock: completionBlock)
            })
        }
    }

    @objc private func asyncBkgRead(context:NSManagedObjectContext, operationBlock: ((context: NSManagedObjectContext) -> Void)?)
    {
        self.isPersistentStoreAvailable {
            
            context.performBlock({ () -> Void in
                
                if let operationBlockUnWrapped = operationBlock {
                    operationBlockUnWrapped(context: context)
                }
            })
        }
    }
    
    @objc private func asyncBkgWrite(context:NSManagedObjectContext, operationBlock: ((context: NSManagedObjectContext) -> Void)?, completion completionBlock: ((NSError?) -> Void)?)
    {
        self.isPersistentStoreAvailable {
            
            context.performBlock({ [weak self] in
                guard let strongSelf = self else { return }
                
                if let operationBlockUnWrapped = operationBlock {
                    operationBlockUnWrapped(context: context)
                }
                strongSelf.save(context: context, completionBlock: completionBlock)
                })
        }
    }

    //MARK: Read
    
    ///### Helper to perform a background read operation, on a new privatecontext
    ///- Parameter operationBlock: The operation block to be performed in background

    @objc public func read(operationBlock operationBlock: ((context: NSManagedObjectContext) -> Void)?)
    {
        let context = self.createPrivatecontext()
        self.syncBkgRead(context, operationBlock: operationBlock);
    }
    
    ///### Helper to perform an operation on the main context in the mainThread
    ///- Parameter operationBlock: The operation block to be performed in background
    
    @objc public func read_MT(operationBlock operationBlock: ((context: NSManagedObjectContext) -> Void)?)
    {
        self.syncBkgRead(self.maincontext!, operationBlock: operationBlock);
    }

    //MARK: Write

    ///### Helper to perform a background operation, on a new privatecontext, and automatically save the changes
    ///- Parameter operationBlock: The operation block to be performed in background
    
    @objc public func write(operationBlock operationBlock: ((context: NSManagedObjectContext) -> Void)?, completion completionBlock:((NSError?) -> Void)?)
        {
        let context = self.createPrivatecontext()
        self.syncBkgWrite(context, operationBlock: operationBlock, completion: completionBlock);
    }
    
    ///### Helper to perform an operation on the main context, mainThread, and automatically save the changes
    ///- Parameter operationBlock: The operation block to be performed in background

    @objc public func write_MT(operationBlock operationBlock: ((context: NSManagedObjectContext) -> Void)?, completion completionBlock: ((NSError?) -> Void)?)
    {
        self.asyncBkgWrite(self.maincontext!, operationBlock: operationBlock, completion: completionBlock);
    }
    
    //MARK: Save

    ///### Save the specified context and all its parents
    ///- Parameter completionBlock: completion Block
    
    @objc public func save(context context: NSManagedObjectContext, completionBlock: ((NSError?) -> Void)?) -> Void {
        
        weak var weakSelf = self
        
        context.save(completionBlock: { (inner) in
            do {
                try inner()
                
                weakSelf!.maincontext?.save(completionBlock: { (inner) in
                    do {
                        try inner()
                        
                        if let coordinator = self.rootcontext!.persistentStoreCoordinator {
                            
                            if coordinator.persistentStores.isEmpty {
                                if let exCompletionBlock = completionBlock {
                                    exCompletionBlock(nil);
                                }
                                return
                            }
                        }
                        
                        weakSelf!.rootcontext?.save(completionBlock: { (inner) in
                            
                            do {
                                try inner()
                                
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    if let exCompletionBlock = completionBlock {
                                        exCompletionBlock(nil);
                                    }
                                })
                                
                            } catch CoreDataStackError.InternalError(let descr) {

                                if let exCompletionBlock = completionBlock {
                                    exCompletionBlock(NSError   (domain:Constants.DomainName, code:-1, userInfo:[
                                        NSLocalizedDescriptionKey: descr]));
                                }
                                
                            } catch {    
                            }
                            
                        })
                        
                    } catch CoreDataStackError.InternalError(let descr) {
                        
                        if let exCompletionBlock = completionBlock {
                            exCompletionBlock(NSError   (domain:Constants.DomainName, code:-1, userInfo:[
                                NSLocalizedDescriptionKey: descr]));
                        }
                    } catch {
                    }
                    
                })
                
            } catch CoreDataStackError.InternalError(let descr) {
                
                if let exCompletionBlock = completionBlock {
                    exCompletionBlock(NSError   (domain:Constants.DomainName, code:-1, userInfo:[
                        NSLocalizedDescriptionKey: descr]));
                }
            } catch {
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
