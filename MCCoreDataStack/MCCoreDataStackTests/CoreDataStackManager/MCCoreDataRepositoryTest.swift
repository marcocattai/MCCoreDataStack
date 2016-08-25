//
//  MCCoreDataRepositoryTest.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import XCTest
import CoreData

@testable import MCCoreDataStack

class MCCoreDataRepositoryTest: XCTestCase
{
    private var defaultStoreURL: NSURL!
    private var defaultModelURL: NSURL!
    private var coreDataRepo: MCCoreDataRepository!
    private var expectation: XCTestExpectation!
    private var coreDataStackManager: MCCoreDataStackManager!
    
    lazy var backgroundMOC: NSManagedObjectContext = {
        let bkgQueue = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        bkgQueue.mergePolicy = NSMergePolicy(mergeType: .OverwriteMergePolicyType)
        return bkgQueue
    }()
    
    override func setUp()
    {
        super.setUp();
        
        let dirPath = StackManagerHelper.Path.DocumentsFolder
        
        self.defaultStoreURL = NSURL(fileURLWithPath: dirPath.stringByAppendingString("/TestDB.sqlite"))
        
        MCCoreDataRepository.sharedInstance.setup(storeName: "TestDB.sqlite", domainName: "co.uk.tests")
        
        self.coreDataRepo = MCCoreDataRepository.sharedInstance
        self.coreDataStackManager = MCCoreDataRepository.sharedInstance.coreDataStackManager
        
        self.coreDataStackManager.deleteStore {
            
        };
        sleep(2)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        self.coreDataStackManager.deleteStore { 
            
        };
        sleep(2)
    }
    
    func testCoreDataRepositoryCreation_01()
    {
            XCTAssertFalse(self.coreDataRepo == nil)
    }
    
    func testCoreDataRepositoryObjectCreationAndSave_02()
    {

        self.expectation = expectationWithDescription("Create and save object")

        let subDictionary: [String: AnyObject] = ["subCategoryID": "sub12345", "subCategoryName": "subTest12345"]

        let dictionary: [String: AnyObject] = ["categoryID": "12345", "categoryName": "Test12345", "subCategory": subDictionary]

        self.coreDataStackManager.performOperationInBackgroundQueueWithBlockAndSave(operationBlock: { (MOC) in

            let createdObject = self.coreDataRepo?.createObjectWithDictionary(dictionary: dictionary, entityName: "MCCategoryTest", MOC: MOC)

            XCTAssertFalse(createdObject == nil)
            
            if let category = createdObject as? MCCategoryTest {

                XCTAssertTrue(category.categoryID == "12345")
                XCTAssertTrue(category.categoryName == "Test12345")
                XCTAssertTrue(category.subCategory?.subCategoryID == "sub12345")
                XCTAssertTrue(category.subCategory?.subCategoryName == "subTest12345")
            } else {
                XCTAssertTrue(false)
            }
            
        }, completion: {
            
            let result = self.coreDataRepo?.fetchAllObjects(byEntityName: "MCCategoryTest", MOC: nil, resultType: .ManagedObjectResultType)
            
            for resultItem in result! {
                let category = resultItem as! MCCategoryTest
                
                if let subCategory = category.subCategory {
                    XCTAssertTrue(subCategory.subCategoryID == "sub12345")
                    XCTAssertTrue(subCategory.subCategoryName == "subTest12345")
                    XCTAssertTrue(subCategory.parent?.categoryID == "12345")
                    XCTAssertTrue(subCategory.parent?.categoryName == "Test12345")

                }

            }
            
            self.expectation.fulfill()
            
        })
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            XCTAssertNil(error);
        }

    }
    
    func testCoreDataRepositoryObjectCreationSaveAndDeletion_03()
    {
        
        self.expectation = expectationWithDescription("Create and save object")
        
        let subDictionary: [String: AnyObject] = ["subCategoryID": "sub12345", "subCategoryName": "subTest12345"]
        
        let dictionary: [String: AnyObject] = ["categoryID": "12345", "categoryName": "Test12345", "subCategory": subDictionary]
        
        self.coreDataStackManager.performOperationInBackgroundQueueWithBlockAndSave(operationBlock: { (MOC) in
            
            let createdObject = self.coreDataRepo?.createObjectWithDictionary(dictionary: dictionary, entityName: "MCCategoryTest", MOC: MOC)
            
            XCTAssertFalse(createdObject == nil)
            
            if let category = createdObject as? MCCategoryTest {
                XCTAssertTrue(category.categoryID == "12345")
                XCTAssertTrue(category.categoryName == "Test12345")
                
                if let subCategory = category.subCategory {
                    XCTAssertTrue(subCategory.subCategoryID == "sub12345")
                    XCTAssertTrue(subCategory.subCategoryName == "subTest12345")
                }
                
            } else {
                XCTAssertTrue(false)
            }
        }, completion: {
            
            self.coreDataStackManager.performOperationInBackgroundQueueWithBlockAndSave(operationBlock: { (MOC) in
            
                let results = self.coreDataRepo?.fetchAllObjects(byEntityName: "MCCategoryTest", MOC: MOC, resultType: .ManagedObjectResultType) as? [NSManagedObject]
                
                XCTAssertTrue(results?.count > 0)
                self.coreDataRepo?.deleteObjects(containedInArray: results!, MOC: MOC)

            }, completion: {

                let results = self.coreDataRepo?.fetchAllObjects(byEntityName: "MCCategoryTest", MOC: (self.coreDataRepo?.coreDataStackManager.mainMOC)!, resultType: .ManagedObjectResultType) as? [NSManagedObject]
                XCTAssertTrue(results?.count == 0)
                self.expectation.fulfill()

            })
        })
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            XCTAssertNil(error);
        }
        
    }

    func testCoreDataRepositoryObjectShouldBeOverridenWhenCreatingADuplicate_04()
    {
        
        self.expectation = expectationWithDescription("Create and save object")
        
        let dictionary: [String: AnyObject] = ["categoryID": "12345", "categoryName": "Test12345"]
        let dictionaryNew: [String: AnyObject] = ["categoryID": "12345", "categoryName": "Test"]
        
        self.coreDataStackManager.performOperationInBackgroundQueueWithBlockAndSave(operationBlock: { (MOC) in
            
            var firstObject: NSManagedObject? = nil
            var duplicatedObject: NSManagedObject? = nil
            
            var results = self.coreDataRepo?.fetchObjectsInCurrentQueue(byPredicate: NSPredicate(format: "%K = %@", "categoryID", dictionary["categoryID"] as! String), entityName: "MCCategoryTest", MOC: MOC, resultType: .CountResultType)

            if let value = results {
                if value[0] as! NSInteger == 0 {
                    firstObject = self.coreDataRepo?.createObjectWithDictionary(dictionary: dictionary, entityName: "MCCategoryTest", MOC: MOC)
                }
            }

            results = self.coreDataRepo?.fetchObjectsInCurrentQueue(byPredicate: NSPredicate(format: "%K = %@", "categoryID", dictionaryNew["categoryID"] as! String), entityName: "MCCategoryTest", MOC: MOC, resultType: .CountResultType)

            if let value = results {
                if value[0] as! NSInteger == 0 {
                    duplicatedObject = self.coreDataRepo?.createObjectWithDictionary(dictionary: dictionaryNew, entityName: "MCCategoryTest", MOC: MOC)
                }
            }
            
            XCTAssertFalse(firstObject == nil)
            
            XCTAssertTrue(duplicatedObject == nil, "This object should be nil because it was duplicated")
            
            if let category = firstObject as? MCCategoryTest {
                XCTAssertTrue(category.categoryID == "12345")
                XCTAssertTrue(category.categoryName == "Test12345")
            } else {
                XCTAssertTrue(false)
            }
            
            }, completion: {
                
                self.coreDataStackManager.performOperationInBackgroundQueueWithBlock(operationBlock: { (MOC) in
                    let results = self.coreDataRepo?.fetchObjectsInCurrentQueue(byPredicate: NSPredicate(format: "%K = %@", "categoryID", "12345"), entityName: "MCCategoryTest", MOC: MOC)
                    
                    if let value = results {
                        XCTAssertTrue(value.count == 1)
                    }
                    
                    if let category = results![0] as? MCCategoryTest {
                        XCTAssertFalse(category.hasChanges)
                    } else {
                        XCTAssertTrue(false)
                    }
                     self.expectation.fulfill()
                    })
                
        })
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            XCTAssertNil(error);
        }
        
    }
    
    func testPersist1000CategoriesWithCommonCategoryNameAndRetrieveThemByCategoryName()
    {
        self.expectation = expectationWithDescription("Saving 1000 categories in a background queue")
        
        let dictionary: [String: AnyObject] = ["categoryID": "12345", "categoryName": "Test12345"]
        
        self.coreDataStackManager.performOperationInBackgroundQueueWithBlockAndSave(operationBlock: { (MOC) in
            
            self.coreDataRepo?.createObjectWithDictionary(dictionary: dictionary, entityName: "MCCategoryTest", MOC: MOC)
            
            for index in 1...1000 {
                
                let categoryID = String(index)
                let categoryName = "categoryName"
                
                let dictionary: [String: AnyObject] = ["categoryID": categoryID, "categoryName": categoryName]
                
                self.coreDataRepo?.createObjectWithDictionary(dictionary: dictionary, entityName: "MCCategoryTest", MOC: MOC)
            }
            
            
            }, completion: {
                
                self.coreDataStackManager.performOperationInBackgroundQueueWithBlock(operationBlock: { (MOC) in
                    let results = self.coreDataRepo?.fetchObjectsInCurrentQueue(byPredicate: NSPredicate(format: "%K = %@", "categoryName", "categoryName"), entityName: "MCCategoryTest", MOC: MOC)
                    
                        XCTAssertTrue(results?.count == 1000)
                    
                        self.expectation.fulfill()
                    })

        })
        
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            XCTAssertNil(error);
        }
    }

    func testPersist1000CategoriesAndDelete400OfThem()
    {
        self.expectation = expectationWithDescription("Saving 1000 categories in a background queue")
        
        let dictionary: [String: AnyObject] = ["categoryID": "12345", "categoryName": "Test12345"]
        
        
        
        self.coreDataStackManager.performOperationInBackgroundQueueWithBlockAndSave(operationBlock: { (MOC) in
            
            self.coreDataRepo?.createObjectWithDictionary(dictionary: dictionary, entityName: "MCCategoryTest", MOC: MOC)
            
            for index in 1...1000 {
                
                let categoryID = String(index)
                let categoryName = "categoryName" //"CategoryName" + String(index)
                
                let dictionary: [String: AnyObject] = ["categoryID": categoryID, "categoryName": categoryName]
                
                self.coreDataRepo?.createObjectWithDictionary(dictionary: dictionary, entityName: "MCCategoryTest", MOC: MOC)
            }
            
            }, completion: {
                
                self.coreDataStackManager.performOperationInBackgroundQueueWithBlock(operationBlock: { (MOC) in
                    let results = self.coreDataRepo?.fetchObjectsInCurrentQueue(byPredicate: NSPredicate(format: "%K = %@", "categoryName", "categoryName"), entityName: "MCCategoryTest", MOC: MOC, resultType: .ManagedObjectIDResultType)
                    
                    XCTAssertTrue(results?.count == 1000)

                    if let array = results! as? [NSManagedObjectID] {

                        let ctx = self.coreDataStackManager.createPrivateMOC()
                        
                        //Checking that we can retrieve existingObjecsWithIds
                        let objs = ctx.existingObjecsWithIds(managedObjects: array)
                        
                        XCTAssertTrue(objs.count == 1000)

                        self.coreDataRepo.deleteObjects(containedInArray: objs, completionBlock: {

                            self.coreDataStackManager.performOperationInBackgroundQueueWithBlock(operationBlock: { (MOC) in
                                let results = self.coreDataRepo?.fetchObjectsInCurrentQueue(byPredicate: NSPredicate(format: "%K = %@", "categoryName", "categoryName"), entityName: "MCCategoryTest", MOC: MOC, resultType: .ManagedObjectIDResultType)
                                
                                XCTAssertTrue(results?.count == 0)
                                
                                self.expectation.fulfill()
                            })
                            
                            
                        })
                    }
                })
                
        })
        
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            XCTAssertNil(error);
        }

    }

    func testPersist5000CategoriesAndDelete2500OfThem()
    {
        self.expectation = expectationWithDescription("Saving 1000 categories in a background queue")
        
        let dictionary: [String: AnyObject] = ["categoryID": "12345", "categoryName": "Test12345"]
        
        
        self.coreDataStackManager.performOperationInBackgroundQueueWithBlockAndSave(operationBlock: { (MOC) in
            
            self.coreDataRepo?.createObjectWithDictionary(dictionary: dictionary, entityName: "MCCategoryTest", MOC: MOC)
            
            for index in 1...5000 {
                
                let categoryID = String(index)
                let categoryName = "categoryName" //"CategoryName" + String(index)
                
                let dictionary: [String: AnyObject] = ["categoryID": categoryID, "categoryName": categoryName]
                
                self.coreDataRepo?.createObjectWithDictionary(dictionary: dictionary, entityName: "MCCategoryTest", MOC: MOC)
            }
            
            }, completion: {
                
                self.coreDataStackManager.performOperationInBackgroundQueueWithBlock(operationBlock: { (MOC) in
                    let results = self.coreDataRepo?.fetchObjectsInCurrentQueue(byPredicate: NSPredicate(format: "%K = %@", "categoryName", "categoryName"), entityName: "MCCategoryTest", MOC: MOC, resultType: .ManagedObjectIDResultType)
                    
                    XCTAssertTrue(results?.count == 5000)
                    
                    if var array = results! as? [NSManagedObjectID] {

                        let ctx = self.coreDataStackManager.createPrivateMOC()
                        
                        //Checking that we can retrieve existingObjecsWithIds
                        let objs = ctx.existingObjecsWithIds(managedObjects: array)
                        
                        XCTAssertTrue(objs.count == 5000)
                        
                        array.removeRange(0..<2500)
                        
                        let subArray = array as [NSManagedObjectID]
                        
                        self.coreDataRepo.deleteObjects(containedInArray: subArray, completionBlock: {
                            
                            self.coreDataStackManager.performOperationInBackgroundQueueWithBlock(operationBlock: { (MOC) in
                                let results = self.coreDataRepo?.fetchObjectsInCurrentQueue(byPredicate: NSPredicate(format: "%K = %@", "categoryName", "categoryName"), entityName: "MCCategoryTest", MOC: MOC, resultType: .ManagedObjectIDResultType)
                                
                                XCTAssertTrue(results?.count == 2500)
                                
                                self.expectation.fulfill()
                            })
                            
                            
                        })
                    }
                })
                
        })
        
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            XCTAssertNil(error);
        }
        
    }
}