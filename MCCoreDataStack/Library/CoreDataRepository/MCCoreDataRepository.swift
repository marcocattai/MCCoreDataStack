//
//  MCCoreDataRepository.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

@objc open class MCCoreDataRepository : NSObject {
    
    //MARK: Public vars
    ///### Internal CoreDataStackManager

    @objc fileprivate(set) open var cdsManager: MCCoreDataStackManager! = nil
    
    //MARK: Setup
    
    ///### Setup a coreDataRepository. It looks up all models in the specified bundles and merges them
    ///- Parameter storeName: Name of the sql store
    ///- Parameter domainName: Domain Name
    ///- Return: Bool
    
    @objc open func setup(storeName: String, domainName: String, completion: MCCoreDataAsyncCompletion?) {
        let dirPath = StackManagerHelper.Path.DocumentsFolder
        let defaultStoreURL = URL(fileURLWithPath: dirPath + ("/"+storeName))
        
        let bundle = Bundle(for: type(of: self))
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [bundle])!
        
        self.cdsManager = MCCoreDataStackManager(domain: domainName, model: managedObjectModel)
        
        self.cdsManager.configure(storeURL: defaultStoreURL, configuration: nil, completion: completion)
    }

    ///### Setup a coreDataRepository
    ///- Parameter storeName: Name of the sql store
    ///- Parameter modelName: Name of the data Model
    ///- Parameter domainName: Domain Name
    ///- Return: Bool
    
    @objc open func setup(storeName: String, modelName: String, domainName: String, completion: MCCoreDataAsyncCompletion?) {
        
        let dirPath = StackManagerHelper.Path.DocumentsFolder
        let defaultStoreURL = URL(fileURLWithPath: dirPath + ("/"+storeName))
        let defaultModelURL = Bundle(for: MCCoreDataRepository.self).url(forResource: modelName, withExtension: "momd")!

        self.cdsManager = MCCoreDataStackManager(domainName: domainName, model: defaultModelURL)!
        
        self.cdsManager.configure(storeURL: defaultStoreURL, configuration: nil, completion: completion)
    }
    
    //MARK: Creation
    ///### Create a new object from a dictionary
    ///- Parameter entityName: Name of the corresponding entity
    ///- Parameter context: ManagedObjectContext created in the current thread
    ///- Return: New NSManagedObject or nil
    
    @discardableResult @objc open func create(dictionary: Dictionary<String, AnyObject>, entityName: String, context: NSManagedObjectContext) -> NSManagedObject? {
        return NSManagedObject.instanceWithDictionary(dictionary: dictionary, entityName: entityName, context: context)
    }
 
    //MARK: read
    ///### read on a background queue
    ///- Parameter operationBlock
    ///- Parameter completionBlock - The operation is persisted in the disk
    ///- Return: Self - (Chaining support)

    @discardableResult @objc open func read(operationBlock: @escaping (_ context: NSManagedObjectContext) -> Void) -> Self {
        self.cdsManager.read(operationBlock: { (context) in
            operationBlock(context)
        })
        
        return self
    }

    //MARK: write
    ///### write on a background queue
    ///- Parameter operationBlock
    ///- Parameter completionBlock - The operation is persisted in the disk
    ///- Return: Self - (Chaining support)

    @discardableResult @objc open func write(operationBlock: @escaping (_ context: NSManagedObjectContext) -> Void, completion completionBlock: ((NSError?) -> Void)?) -> Self {
        self.cdsManager.write(operationBlock: { (context) in
            operationBlock(context)
        }) { (error) in
            
            if let block = completionBlock {
                block(error);
            }
        }
        return self
    }
    
    //MARK: read_MT
    ///### read from the mainContext on the mainThread
    ///- Parameter operationBlock

    @discardableResult @objc open func read_MT(operationBlock: @escaping (_ context: NSManagedObjectContext) -> Void) -> Void {
        DispatchQueue.main.async(execute: {
            self.cdsManager.read_MT { (context) in
                    operationBlock(context)
            }
        })
    }
}
