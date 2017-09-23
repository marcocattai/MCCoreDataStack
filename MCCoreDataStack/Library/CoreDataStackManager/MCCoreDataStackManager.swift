//
//  MCCoreDataStackManager.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

public typealias MCCoreDataAsyncResult = (_ inner: () throws -> Void) -> Void
public typealias MCCoreDataAsyncCompletion = () -> Void
public typealias MCCoreDataOperationBlock = (_ context: NSManagedObjectContext) -> Void

///###  Error
public enum CoreDataStackError: Error {
    case Error(description: String)
}

struct Constants {
    static let DomainName = "MCCoreDataStack"
}

///### This helper gives you back the path for the Library, Documents and Tmp folders

public struct StackManagerHelper {
    struct Path {
        static let LibraryFolder = NSSearchPathForDirectoriesInDomains(.libraryDirectory,
                                                                       .userDomainMask, true)[0] as String
        static let DocumentsFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                         .userDomainMask, true)[0] as String
        static let TmpFolder = NSTemporaryDirectory()
    }
}

@objc open class MCCoreDataStackManager: NSObject {

    // MARK: Public vars

    ///### Root ManagedObjectContext where the persistentStore is attached (PrivateQueueConcurrencyType)
    open var rootcontext: NSManagedObjectContext?

    ///### Main ManagedObjectContext. Iis parentContext is rootcontext
    open var maincontext: NSManagedObjectContext?

    // MARK: Private vars

    @objc let accessSemaphore = DispatchGroup()

    private var domain: String = ""

    open var isReady: Bool = false

    // MARK: vars

    ///### Current Store URL
    fileprivate(set) open var storeURL: URL?
    var model: NSManagedObjectModel?
    var storeCoordinator: NSPersistentStoreCoordinator?

    #if TARGET_OS_IPHONE
    var bkgPersistTask: UIBackgroundTaskIdentifier?
    var areObserversRegistered: Bool = false

    // MARK: De-init

    deinit {
    if areObserversRegistered {
    self.deregisterObservers()
    }
    }
    #endif

    // MARK: - Initializers

    /// Init method
    /// - Parameter domain: name of the current domain
    /// - Parameter model: the given object model

    @objc public init?(domain: String, model: NSManagedObjectModel) {
        guard !domain.isEmpty else {
            return nil
        }

        self.domain = domain
        self.model = model
    }

    /// Init method
    /// - Parameter domain: name of the current domain
    /// - Parameter url: URL for the current data model

    @objc public convenience init?(domain: String, url: URL?) {
        guard
            let url = url,
            let model = NSManagedObjectModel(contentsOf: url) else {
                return nil
        }

        self.init(domain: domain, model: model)
    }

    // MARK: - Public methods

    /// Configure the current CoreDataStack
    /// - Parameter url: the URL of your sqlite file. See StackManagerHelper for help.
    /// - Parameter configuration: configuration name
    @objc open func configure(url: URL, configuration: String?, completion: MCCoreDataAsyncCompletion?) {
        guard !url.absoluteString.isEmpty else {
            return
        }

        self.storeURL = url

        self.createPersistentStoreIfNeeded()

        self.accessSemaphore.enter()

        self.addSqliteStore(self.storeURL!, configuration: configuration) {
            self.isReady = true
            self.accessSemaphore.leave()

            completion?()
        }
    }

    /// Delete the current persistent store
    /// - Parameter completion: completion block

    @objc open func deleteStore(completion: MCCoreDataAsyncCompletion?) {
        guard
            let url = storeURL,
            let storeCoordinator = storeCoordinator,
            let persistentStore = storeCoordinator.persistentStore(for: url) else
        {
            completion?()
            return
        }

        do {
            try storeCoordinator.remove(persistentStore)

            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(atPath: url.path)
            }

        } catch {
            print("Error removing items")
        }

        completion?()
    }

    // MARK: Private context Creation

    ///### Create a private NSManagedObjectContext of type PrivateQueueConcurrencyType with maincontext as parentContext
    ///- Return: New NSManagedObjectContext

    @objc open func createPrivatecontext() -> NSManagedObjectContext {

        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

        context.performAndWait({ [weak self] in

            guard let strongSelf = self else { return }

            context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
            if strongSelf.maincontext != nil {
                context.parent = strongSelf.maincontext
            }
        })

        return context
    }

    // MARK: Private

    fileprivate func isPersistentStoreAvailable(_ completionBlock: MCCoreDataAsyncCompletion?) {
        if self.isReady {
            if let completionBlockUnwrapped = completionBlock {
                completionBlockUnwrapped()
            }
        } else {
            let now = DispatchTime.now()
            let delta = Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            let timeout: DispatchTime = now + delta

            _ = self.accessSemaphore.wait(timeout: timeout)

            // FIXME: PersistentStore needs
            let delayTime = now + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                completionBlock?()
            }
        }
    }

    // MARK: Read

    ///### Helper to perform a background operation on a new privatecontext
    ///- Parameter operationBlock: The operation block to be performed in background

    @objc fileprivate func syncBkgRead(_ context: NSManagedObjectContext, operationBlock: (MCCoreDataOperationBlock)?) {
        self.isPersistentStoreAvailable {

            context.performAndWait({ () -> Void in

                if let operationBlockUnWrapped = operationBlock {
                    operationBlockUnWrapped(context)
                }
            })
        }
    }

    @objc fileprivate func syncBkgWrite(_ context: NSManagedObjectContext,
                                        operationBlock: (MCCoreDataOperationBlock)?,
                                        completion completionBlock: ((NSError?) -> Void)?) {
        self.isPersistentStoreAvailable {

            context.performAndWait({ [weak self] in
                guard let strongSelf = self else { return }

                if let operationBlockUnWrapped = operationBlock {
                    operationBlockUnWrapped(context)
                }
                strongSelf.save(context: context, completionBlock: completionBlock)
            })
        }
    }

    @objc fileprivate func asyncBkgRead(_ context: NSManagedObjectContext,
                                        operationBlock: (MCCoreDataOperationBlock)?) {
        self.isPersistentStoreAvailable {

            context.perform({ () -> Void in

                if let operationBlockUnWrapped = operationBlock {
                    operationBlockUnWrapped(context)
                }
            })
        }
    }

    @objc fileprivate func asyncBkgWrite(_ context: NSManagedObjectContext,
                                         operationBlock: (MCCoreDataOperationBlock)?,
                                         completion completionBlock: ((NSError?) -> Void)?) {
        self.isPersistentStoreAvailable {

            context.perform({ [weak self] in
                guard let strongSelf = self else { return }

                if let operationBlockUnWrapped = operationBlock {
                    operationBlockUnWrapped(context)
                }
                strongSelf.save(context: context, completionBlock: completionBlock)
            })
        }
    }

    // MARK: Read

    ///### Helper to perform a background read operation, on a new privatecontext
    ///- Parameter operationBlock: The operation block to be performed in background

    @objc open func read(operationBlock: (MCCoreDataOperationBlock)?) {
        let context = self.createPrivatecontext()
        self.syncBkgRead(context, operationBlock: operationBlock)
    }

    ///### Helper to perform an operation on the main context in the mainThread
    ///- Parameter operationBlock: The operation block to be performed in background

    @objc open func read_MT(operationBlock: (MCCoreDataOperationBlock)?) {
        self.syncBkgRead(self.maincontext!, operationBlock: operationBlock)
    }

    // MARK: Write

    ///### Helper to perform a background operation, on a new privatecontext, and automatically save the changes
    ///- Parameter operationBlock: The operation block to be performed in background

    @objc open func write(operationBlock: (MCCoreDataOperationBlock)?,
                          completion completionBlock: ((NSError?) -> Void)?) {
        let context = self.createPrivatecontext()
        self.syncBkgWrite(context, operationBlock: operationBlock, completion: completionBlock)
    }

    ///### Helper to perform an operation on the main context, mainThread, and automatically save the changes
    ///- Parameter operationBlock: The operation block to be performed in background

    @objc open func write_MT(operationBlock: (MCCoreDataOperationBlock)?,
                             completion completionBlock: ((NSError?) -> Void)?) {
        self.asyncBkgWrite(self.maincontext!, operationBlock: operationBlock, completion: completionBlock)
    }

    // MARK: Save

    ///### Save the specified context and all its parents
    ///- Parameter completionBlock: completion Block

    @objc open func save(context: NSManagedObjectContext, completionBlock: ((NSError?) -> Void)?) {

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
                                    exCompletionBlock(nil)
                                }
                                return
                            }
                        }

                        weakSelf!.rootcontext?.save(completionBlock: { (inner) in

                            do {
                                try inner()

                                DispatchQueue.main.async(execute: { () -> Void in
                                    if let exCompletionBlock = completionBlock {
                                        exCompletionBlock(nil)
                                    }
                                })

                            } catch CoreDataStackError.Error(let descr) {

                                if let exCompletionBlock = completionBlock {
                                    exCompletionBlock(NSError   (domain:Constants.DomainName, code:-1, userInfo:[
                                        NSLocalizedDescriptionKey: descr]))
                                }

                            } catch {
                            }

                        })

                    } catch CoreDataStackError.Error(let descr) {

                        if let exCompletionBlock = completionBlock {
                            exCompletionBlock(NSError   (domain:Constants.DomainName, code:-1, userInfo:[
                                NSLocalizedDescriptionKey: descr]))
                        }
                    } catch {
                    }

                })

            } catch CoreDataStackError.Error(let descr) {

                if let exCompletionBlock = completionBlock {
                    exCompletionBlock(NSError   (domain:Constants.DomainName, code:-1, userInfo:[
                        NSLocalizedDescriptionKey: descr]))
                }
            } catch {
            }
        })
    }

    // MARK: Notifications

    @objc fileprivate func contextWillSave() {
        //Not implemented yet
    }

    @objc fileprivate func contextDidSave(_ notification: Notification) {
        //Not implemented yet
    }
}
