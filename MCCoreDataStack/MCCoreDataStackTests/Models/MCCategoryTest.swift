//
//  MCCategoryTest.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

@objc(MCCategoryTest)
class MCCategoryTest: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    override internal func update(keyName: String, array: Array<Dictionary<String, AnyObject>>)
    {
        if let entityName = self.getEntity(keyName) {
            
            for dict in array {
                
                let entity = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self.managedObjectContext!)
                entity.updateWithDictionary(dict)
                
                switch entityName {
                case "MCSubCategoryTest":
                    self.subCategory = (entity as! MCSubCategoryTest)
                    
                    break
                default: break
                }
            }
        }
    }
    
    
    private func getEntity(keyName: String) -> String?
    {
        switch keyName {
        case "subCategory":
            return "MCSubCategoryTest"
        default:
            break
            
        }
        return nil
    }

    
}
