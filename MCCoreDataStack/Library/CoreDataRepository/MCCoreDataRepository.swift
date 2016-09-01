//
//  MCCoreDataRepository.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

@objc public class MCCoreDataRepository : NSObject
{
    
    //MARK: Public vars
    ///### Internal CoreDataStackManager

    @objc private(set) public var cdsManager: MCCoreDataStackManager! = nil

    ///### Shared Instance

    @objc public class var sharedInstance: MCCoreDataRepository {
        
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: MCCoreDataRepository? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = MCCoreDataRepository(CoreDataStackManager: nil)
        }
        return Static.instance!
    }
    
    //MARK: Init
    
    @objc private init?(CoreDataStackManager stack: MCCoreDataStackManager?) {
        if let stackUnwrapped = stack {
            self.cdsManager = stackUnwrapped
        }
    }
    
    //MARK: Setup
    
    ///### Setup a coreDataRepository. It looks up all models in the specified bundles and merges them
    ///- Parameter storeName: Name of the sql store
    ///- Parameter domainName: Domain Name
    ///- Return: Bool
    
    @objc public func setup(storeName storeName: String, domainName: String) -> Bool
    {
        let dirPath = StackManagerHelper.Path.DocumentsFolder
        let defaultStoreURL = NSURL(fileURLWithPath: dirPath.stringByAppendingString("/"+storeName))
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let managedObjectModel = NSManagedObjectModel.mergedModelFromBundles([bundle])!
        
        print(defaultStoreURL.path)
        self.cdsManager = MCCoreDataStackManager(domain: domainName, model: managedObjectModel)
        
        return self.cdsManager.configure(storeURL: defaultStoreURL, configuration: nil)
    }

    ///### Setup a coreDataRepository
    ///- Parameter storeName: Name of the sql store
    ///- Parameter modelName: Name of the data Model
    ///- Parameter domainName: Domain Name
    ///- Return: Bool
    
    @objc public func setup(storeName storeName: String, modelName: String, domainName: String) -> Bool
    {
        
        let dirPath = StackManagerHelper.Path.DocumentsFolder
        let defaultStoreURL = NSURL(fileURLWithPath: dirPath.stringByAppendingString("/"+storeName))
        let defaultModelURL = NSBundle(forClass: MCCoreDataRepository.self).URLForResource(modelName, withExtension: "momd")!

        self.cdsManager = MCCoreDataStackManager(domainName: domainName, model: defaultModelURL)!
        
        return self.cdsManager.configure(storeURL: defaultStoreURL, configuration: nil)
    }
    
    //MARK: Creation
    
    ///### Create a new object from a dictionary
    ///- Parameter entityName: Name of the corresponding entity
    ///- Parameter MOC: ManagedObjectContext created in the current thread
    ///- Return: New NSManagedObject or nil
    
    @objc public func create(dictionary dictionary: Dictionary<String, AnyObject>, entityName: String, MOC moc: NSManagedObjectContext) -> NSManagedObject?
    {
        return NSManagedObject.instanceWithDictionary(dictionary: dictionary, entityName: entityName, MOC: moc)
    }
        
}