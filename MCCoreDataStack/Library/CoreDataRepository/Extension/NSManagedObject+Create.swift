//
//  NSManagedObject+Create.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 02/06/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject: EUManagedObjectProtocol
{
    
    //MARK: Extension to auto populate properties from a dictionary
    
    ///### Class method to create an Instance of a specific NSManagedObject using a Dictionary
    ///- Parameter dictionary: dictionary
    ///- Parameter entityName: the name of the entity
    ///- Parameter context: NSManagedObjectContext
    ///- Return: NSManagedObject

    @objc public class func instanceWithDictionary(dictionary: Dictionary<String, AnyObject>,
                                                   entityName: String,
                                                   context: NSManagedObjectContext) -> NSManagedObject?
    {
        let entity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        entity.updateWithDictionary(dictionary: dictionary)
        
        return entity
    }
    
    ///### Update current NSManagedObject with a dictionary
    ///- Parameter dictionary: dictionary

    @objc public func updateWithDictionary(dictionary: Dictionary<String, AnyObject>)
    {
        for (key, value) in dictionary {
            let keyName = key
            let keyValue: AnyObject = value
            
            if value is Array<Dictionary<String, AnyObject>> {
                
                self.update(keyName: keyName, array: value as! Array<Dictionary<String, AnyObject>>)
            } else if (value is Dictionary<String, AnyObject>) {
                
                let array = [value]
                self.update(keyName: keyName, array: array as! Array<Dictionary<String, AnyObject>>)
            } else if (self.responds(to: NSSelectorFromString(keyName))) {
                
                if keyValue is String {
                   let keyValueString = keyValue as! String
                    self.setValue(keyValueString, forKey: keyName)
                } else if keyValue is DateComponents {
                    let dateComponents = keyValue as! DateComponents
                    self.setValue((dateComponents as NSDateComponents).date, forKey: keyName)
                } else {
                    self.setValue(keyValue, forKey: keyName)
                }
            }
        }
    }
    
    ///### called when a value is an array of NSManagedObjects. To be overridden
    ///- Parameter array: array of dictionaries

    public func update(keyName: String, array: Array<Dictionary<String, AnyObject>>)
    {
        // To be overridden by subclasses
    }

}
