//
//  MCSubCategoryTest+CoreDataProperties.swift
//  
//
//  Created by Marco Cattai on 23/08/2016.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension MCSubCategoryTest {

    @NSManaged var subCategoryID: String?
    @NSManaged var subCategoryName: String?
    @NSManaged var parent: MCCategoryTest?

}
