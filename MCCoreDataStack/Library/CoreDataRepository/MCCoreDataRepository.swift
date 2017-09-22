//
//  MCCoreDataRepository.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

@objc open class MCCoreDataRepository: NSObject {

    // MARK: Public vars
    ///###  CoreDataStackManager

    @objc private(set) open var cdsManager: MCCoreDataStackManager!

    // MARK: Setup

    ///### Setup a coreDataRepository. It looks up all models in the specified bundles and merges them
    ///- Parameter storeNameURL: URL of the sql store
    ///- Parameter modelNameURL: URL of the model
    ///- Parameter domainName: Domain Name
    ///- Return: Bool

    @objc open func setup(storeNameURL: URL,
                          modelNameURL: URL,
                          domainName: String,
                          completion: MCCoreDataAsyncCompletion?) {

        self.cdsManager = MCCoreDataStackManager(domain: domainName, url: modelNameURL)!
        self.cdsManager.configure(url: storeNameURL, configuration: nil, completion: completion)
    }

    ///### Setup a coreDataRepository. It looks up all models in the specified bundles and merges them
    ///- Parameter storeName: Name of the sql store
    ///- Parameter domainName: Domain Name
    ///- Return: Bool

    @available(*, deprecated)
    @objc open func setup(storeName: String, domainName: String, completion: MCCoreDataAsyncCompletion?) {
        let dirPath = StackManagerHelper.Path.DocumentsFolder
        let defaultStoreURL = URL(fileURLWithPath: dirPath + ("/"+storeName))

        let bundle = Bundle(for: type(of: self))
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [bundle])!

        self.cdsManager = MCCoreDataStackManager(domain: domainName, model: managedObjectModel)
        self.cdsManager.configure(url: defaultStoreURL, configuration: nil, completion: completion)
    }

    ///### Setup a coreDataRepository
    ///- Parameter storeName: Name of the sql store
    ///- Parameter modelName: Name of the data Model
    ///- Parameter domainName: Domain Name
    ///- Return: Bool

    @objc open func setup(storeName: String,
                          modelName: String,
                          domainName: String,
                          completion: MCCoreDataAsyncCompletion?) {
        let dirPath = StackManagerHelper.Path.DocumentsFolder
        let defaultStoreURL = URL(fileURLWithPath: dirPath + ("/" + storeName))
        let defaultModelURL = Bundle(for: MCCoreDataRepository.self).url(forResource: modelName, withExtension: "momd")!

        self.cdsManager = MCCoreDataStackManager(domain: domainName, url: defaultModelURL)!
        self.cdsManager.configure(url: defaultStoreURL, configuration: nil, completion: completion)
    }

    // MARK: Creation
    ///### Create a new object from a dictionary
    ///- Parameter entityName: Name of the corresponding entity
    ///- Parameter context: ManagedObjectContext created in the current thread
    ///- Return: New NSManagedObject or nil

    @discardableResult @objc open func create(dictionary: [String: AnyObject],
                                              entityName: String,
                                              context: NSManagedObjectContext) -> NSManagedObject? {
        return NSManagedObject.instanceWithDictionary(dictionary: dictionary, entityName: entityName, context: context)
    }

    // MARK: read
    ///### read on a background queue
    ///- Parameter operationBlock
    ///- Parameter completionBlock - The operation is persisted in the disk
    ///- Return: Self - (Chaining support)

    @discardableResult @objc open func read(operationBlock: @escaping MCCoreDataOperationBlock) -> Self {
        self.cdsManager.read(operationBlock: { (context) in
            operationBlock(context)
        })

        return self
    }

    // MARK: write
    ///### write on a background queue
    ///- Parameter operationBlock
    ///- Parameter completionBlock - The operation is persisted in the disk
    ///- Return: Self - (Chaining support)

    @discardableResult @objc open func write(operationBlock: @escaping MCCoreDataOperationBlock,
                                             completion completionBlock: ((NSError?) -> Void)?) -> Self {
        self.cdsManager.write(operationBlock: { (context) in
            operationBlock(context)
        }, completion: { error in
            completionBlock?(error)
        })

        return self
    }

    // MARK: read_MT
    ///### read from the mainContext on the mainThread
    ///- Parameter operationBlock

    @objc open func read_MT(operationBlock: @escaping MCCoreDataOperationBlock) {
        DispatchQueue.main.async {
            self.cdsManager.read_MT { (context) in
                operationBlock(context)
            }
        }
    }
}
