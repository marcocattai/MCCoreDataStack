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

    @objc private(set) public var coreDataStackManager: MCCoreDataStackManager! = nil

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
            self.coreDataStackManager = stackUnwrapped
        }
    }
    
    //MARK: Setup
    
    ///### Setup a coreDataRepository. It looks up all models in the specified bundles and merges them
    ///- Parameter storeName: Name of the sql store
    ///- Parameter domainName: Domain Name
    ///- Return: Bool
    
    @objc public func setupWithStoreName(storeName storeName: String, domainName: String) -> Bool
    {
        let dirPath = StackManagerHelper.Path.DocumentsFolder
        let defaultStoreURL = NSURL(fileURLWithPath: dirPath.stringByAppendingString("/"+storeName))
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let managedObjectModel = NSManagedObjectModel.mergedModelFromBundles([bundle])!
        
        print(defaultStoreURL.path)
        self.coreDataStackManager = MCCoreDataStackManager(domain: domainName, model: managedObjectModel)
        
        return self.coreDataStackManager.configureCoreDataStackWithStoreURL(storeURL: defaultStoreURL, configuration: nil)
    }

    ///### Setup a coreDataRepository
    ///- Parameter storeName: Name of the sql store
    ///- Parameter modelName: Name of the data Model
    ///- Parameter domainName: Domain Name
    ///- Return: Bool
    
    @objc public func setupWithStoreName(storeName storeName: String, modelName: String, domainName: String) -> Bool
    {
        
        let dirPath = StackManagerHelper.Path.DocumentsFolder
        let defaultStoreURL = NSURL(fileURLWithPath: dirPath.stringByAppendingString("/"+storeName))
        let defaultModelURL = NSBundle(forClass: MCCoreDataRepository.self).URLForResource(modelName, withExtension: "momd")!

        self.coreDataStackManager = MCCoreDataStackManager(domainName: domainName, model: defaultModelURL)!
        
        return self.coreDataStackManager.configureCoreDataStackWithStoreURL(storeURL: defaultStoreURL, configuration: nil)
    }
    
    //MARK: Creation
    
    ///### Create a new object from a dictionary
    ///- Parameter entityName: Name of the corresponding entity
    ///- Parameter MOC: ManagedObjectContext created in the current thread
    ///- Return: New NSManagedObject or nil
    
    @objc public func createObjectWithDictionary(dictionary dictionary: Dictionary<String, AnyObject>, entityName: String, MOC moc: NSManagedObjectContext) -> NSManagedObject?
    {
        return NSManagedObject.instanceWithDictionary(dictionary: dictionary, entityName: entityName, MOC: moc)
    }
    
    //MARK: Deletion

    ///### Delete objects contained into the specified array in a background thread
    ///- Parameter array: Specify an array of NSManagedObject or NSManagedObjectID
    ///- Parameter completionBlock: Completion block
    
    @objc public func deleteObjects(containedInArray array: [AnyObject], completionBlock: (() -> Void)?)
    {
        if array is [NSManagedObject] {
            self._deleteObjects(containedInArray: array as! [NSManagedObject], completionBlock: completionBlock)
        } else if array is [NSManagedObjectID] {
            self._deleteObjectsID(containedInArray: array as! [NSManagedObjectID], completionBlock: completionBlock)
        }
    }

    ///### Delete objects contained into the specified array in the current thread
    ///- Parameter array: Specify an array of NSManagedObject or NSManagedObjectID
    ///- Parameter MOC: a specific NSManagedObjectContext

    @objc public func deleteObjects(containedInArray array: [AnyObject], MOC moc: NSManagedObjectContext)
    {
        if array is [NSManagedObject] {
            self._deleteObjects(containedInArray: array as! [NSManagedObject], MOC: moc)
        } else if array is [NSManagedObjectID] {
            self._deleteObjectsID(containedInArray: array as! [NSManagedObjectID], MOC: moc)
        }
    }
    
    //MARK: Fetching
    ///### fetch all the objects by EntityName in the current thread
    ///- Parameter entityName: Name of the corresponding entity
    ///- Parameter MOC: ManagedObjectContext created in the current thread
    ///- Parameter resultType: this can be  .ManagedObject .ManagedObjectID .Dictionary .Count
    ///- Return: New NSManagedObject or nil
    
    @objc public func fetchAllObjects(byEntityName entityName: String, MOC: NSManagedObjectContext, resultType: NSFetchRequestResultType) -> [AnyObject]?
    {
        return self._fetchAllObjectInCurrentQueue(entityName, MOC: MOC, resultType: resultType)
    }

    ///### fetch all the object of a specific entityName, by Predicate, in the current thread
    ///- Parameter predicate: NSPredicate object
    ///- Parameter entityName: Name of the corresponding entity
    ///- Parameter MOC: ManagedObjectContext created in the current thread
    ///- Return: array of results

    @objc public func fetchObjectsInCurrentQueue(byPredicate predicate: NSPredicate, entityName: String, MOC: NSManagedObjectContext) -> [AnyObject]?
    {
        return self._fetchObjectsInCurrentQueue(byPredicate: predicate, entityName: entityName, MOC: MOC, resultType: .ManagedObjectResultType)
    }
    
    ///### fetch all the object of a specific entityName, by Predicate, in the current thread
    ///- Parameter predicate: NSPredicate object
    ///- Parameter entityName: Name of the corresponding entity
    ///- Parameter MOC: ManagedObjectContext created in the current thread
    ///- Parameter resultType: this can be  .ManagedObject .ManagedObjectID .Dictionary .Count
    ///- Return: array of results
    
    @objc public func fetchObjectsInCurrentQueue(byPredicate predicate: NSPredicate, entityName: String, MOC: NSManagedObjectContext, resultType: NSFetchRequestResultType) -> [AnyObject]?
    {
        return self._fetchObjectsInCurrentQueue(byPredicate: predicate, entityName: entityName, MOC: MOC, resultType: resultType)
    }
    
}