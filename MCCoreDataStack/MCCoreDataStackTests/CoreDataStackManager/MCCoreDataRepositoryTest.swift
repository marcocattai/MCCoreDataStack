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
    private var cdsManager: MCCoreDataStackManager!
    
    lazy var backgroundcontext: NSManagedObjectContext = {
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
        self.cdsManager = MCCoreDataRepository.sharedInstance.cdsManager
        
        self.cdsManager.deleteStore {
            
        };
        sleep(2)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        self.cdsManager.deleteStore { 
            
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
        
        self.coreDataRepo.write(operationBlock: { (context) in

            let createdObject = self.coreDataRepo?.create(dictionary: dictionary, entityName: "MCCategoryTest", context: context)
            
            XCTAssertFalse(createdObject == nil)
            
            if let category = createdObject as? MCCategoryTest {
                
                XCTAssertTrue(category.categoryID == "12345")
                XCTAssertTrue(category.categoryName == "Test12345")
                XCTAssertTrue(category.subCategory?.subCategoryID == "sub12345")
                XCTAssertTrue(category.subCategory?.subCategoryName == "subTest12345")
            } else {
                XCTAssertTrue(false)
            }
            
        }) { (error) in

        
        }.read { (context) in
            let result = self.coreDataRepo?.fetch(entityName: "MCCategoryTest", context: context, resultType: .ManagedObjectResultType)
            
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
        }
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            XCTAssertNil(error);
        }

    }
    
    func testCoreDataRepositoryObjectCreationSaveAndDeletion_03()
    {
        
        self.expectation = expectationWithDescription("Create and save object")
        
        let subDictionary: [String: AnyObject] = ["subCategoryID": "sub12345", "subCategoryName": "subTest12345"]
        
        let dictionary: [String: AnyObject] = ["categoryID": "12345", "categoryName": "Test12345", "subCategory": subDictionary]
        
        self.coreDataRepo.write(operationBlock: { (context) in
            let createdObject = self.coreDataRepo?.create(dictionary: dictionary, entityName: "MCCategoryTest", context: context)
            
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

        }) { (error) in
        
        }.write(operationBlock: { (context) in
                         
                let results = self.coreDataRepo?.fetch(entityName: "MCCategoryTest", context: context, resultType: .ManagedObjectResultType) as? [NSManagedObject]
                
                XCTAssertTrue(results?.count > 0)
                self.coreDataRepo?.delete(containedInArray: results!, context: context)

        }) { (error) in
            
        }.read_MT { (context) in
            
            self.coreDataRepo?.read_MT(operationBlock: { (context) in
                let results = self.coreDataRepo?.fetch(entityName: "MCCategoryTest", context: context, resultType: .ManagedObjectResultType) as? [NSManagedObject]
                XCTAssertTrue(results?.count == 0)
                self.expectation.fulfill()
            })
            
        }
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            XCTAssertNil(error);
        }
        
    }

    func testCoreDataRepositoryObjectShouldBeOverridenWhenCreatingADuplicate_04()
    {
        
        self.expectation = expectationWithDescription("Create and save object")
        
        let dictionary: [String: AnyObject] = ["categoryID": "12345", "categoryName": "Test12345"]
        let dictionaryNew: [String: AnyObject] = ["categoryID": "12345", "categoryName": "Test"]
        
        self.coreDataRepo.write(operationBlock: { (context) in
            var firstObject: NSManagedObject? = nil
            var duplicatedObject: NSManagedObject? = nil
            
            var results = self.coreDataRepo?.fetch(byPredicate: NSPredicate(format: "%K = %@", "categoryID", dictionary["categoryID"] as! String), entityName: "MCCategoryTest", context: context, resultType: .CountResultType)
            
            if let value = results {
                if value[0] as! NSInteger == 0 {
                    firstObject = self.coreDataRepo?.create(dictionary: dictionary, entityName: "MCCategoryTest", context: context)
                }
            }
            
            results = self.coreDataRepo?.fetch(byPredicate: NSPredicate(format: "%K = %@", "categoryID", dictionaryNew["categoryID"] as! String), entityName: "MCCategoryTest", context: context, resultType: .CountResultType)
            
            if let value = results {
                if value[0] as! NSInteger == 0 {
                    duplicatedObject = self.coreDataRepo?.create(dictionary: dictionaryNew, entityName: "MCCategoryTest", context: context)
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

        }) { (error) in
            
            XCTAssertTrue(error == nil)
            
            self.coreDataRepo.read(operationBlock: { (context) in
                let results = self.coreDataRepo?.fetch(byPredicate: NSPredicate(format: "%K = %@", "categoryID", "12345"), entityName: "MCCategoryTest", context: context, resultType: .ManagedObjectResultType)
                
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
        }
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            XCTAssertNil(error);
        }
        
    }
    
    func testPersist1000CategoriesWithCommonCategoryNameAndRetrieveThemByCategoryName_05()
    {
        self.expectation = expectationWithDescription("Saving 1000 categories in a background queue")
        
        let dictionary: [String: AnyObject] = ["categoryID": "12345", "categoryName": "Test12345"]
        
        self.coreDataRepo.write(operationBlock: { (context) in
            self.coreDataRepo?.create(dictionary: dictionary, entityName: "MCCategoryTest", context: context)
            
            for index in 1...1000 {
                
                let categoryID = String(index)
                let categoryName = "categoryName"
                
                let dictionary: [String: AnyObject] = ["categoryID": categoryID, "categoryName": categoryName]
                
                self.coreDataRepo?.create(dictionary: dictionary, entityName: "MCCategoryTest", context: context)
            }
            

        }) { (error) in
            
            self.coreDataRepo.read(operationBlock: { (context) in
                let results = self.coreDataRepo?.fetch(byPredicate: NSPredicate(format: "%K = %@", "categoryName", "categoryName"), entityName: "MCCategoryTest", context: context, resultType: .ManagedObjectResultType)
                
                XCTAssertTrue(results?.count == 1000)
                
                self.expectation.fulfill()
            })
        }
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            XCTAssertNil(error);
        }
    }

    func testPersist1000CategoriesAndDelete400OfThem_06()
    {
        self.expectation = expectationWithDescription("Saving 1000 categories in a background queue")
        
        let dictionary: [String: AnyObject] = ["categoryID": "12345", "categoryName": "Test12345"]
        
        
        self.coreDataRepo.write(operationBlock: { (context) in
            self.coreDataRepo?.create(dictionary: dictionary, entityName: "MCCategoryTest", context: context)
            
            for index in 1...1000 {
                
                let categoryID = String(index)
                let categoryName = "categoryName" //"CategoryName" + String(index)
                
                let dictionary: [String: AnyObject] = ["categoryID": categoryID, "categoryName": categoryName]
                
                self.coreDataRepo?.create(dictionary: dictionary, entityName: "MCCategoryTest", context: context)
            }

        }) { (error) in
            
            self.coreDataRepo.read(operationBlock: { (context) in
                let results = self.coreDataRepo?.fetch(byPredicate: NSPredicate(format: "%K = %@", "categoryName", "categoryName"), entityName: "MCCategoryTest", context: context, resultType: .ManagedObjectIDResultType)
                
                XCTAssertTrue(results?.count == 1000)
                
                if let array = results! as? [NSManagedObjectID] {
                    
                    let ctx = self.cdsManager.createPrivatecontext()
                    
                    //Checking that we can retrieve existingObjecsWithIds
                    let objs = ctx.existingObjecsWithIds(managedObjects: array)
                    
                    XCTAssertTrue(objs.count == 1000)
                    
                    self.coreDataRepo.delete(containedInArray: objs, completionBlock: {
                        
                        self.coreDataRepo.read(operationBlock: { (context) in
                            let results = self.coreDataRepo?.fetch(byPredicate: NSPredicate(format: "%K = %@", "categoryName", "categoryName"), entityName: "MCCategoryTest", context: context, resultType: .ManagedObjectIDResultType)
                            
                            XCTAssertTrue(results?.count == 0)
                            
                            self.expectation.fulfill()
                        })
                        
                    })
                }

            })
        }
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            XCTAssertNil(error);
        }

    }

    func testPersist5000CategoriesAndDelete2500OfThem_07()
    {
        self.expectation = expectationWithDescription("Saving 1000 categories in a background queue")
        
        let dictionary: [String: AnyObject] = ["categoryID": "12345", "categoryName": "Test12345"]
        
        
        self.coreDataRepo.write(operationBlock: { (context) in

            self.coreDataRepo?.create(dictionary: dictionary, entityName: "MCCategoryTest", context: context)
            
            for index in 1...5000 {
                
                let categoryID = String(index)
                let categoryName = "categoryName" //"CategoryName" + String(index)
                
                let dictionary: [String: AnyObject] = ["categoryID": categoryID, "categoryName": categoryName]
                
                self.coreDataRepo?.create(dictionary: dictionary, entityName: "MCCategoryTest", context: context)
            }

        }, completion: nil).read { (context) in
            
            let results = self.coreDataRepo?.fetch(byPredicate: NSPredicate(format: "%K = %@", "categoryName", "categoryName"), entityName: "MCCategoryTest", context: context, resultType: .ManagedObjectIDResultType)
            
            XCTAssertTrue(results?.count == 5000)
            
            if var array = results! as? [NSManagedObjectID] {
                
                let ctx = self.cdsManager.createPrivatecontext()
                //Checking that we can retrieve existingObjecsWithIds
                let objs = ctx.existingObjecsWithIds(managedObjects: array)
                XCTAssertTrue(objs.count == 5000)
                
                array.removeRange(0..<2500)
                
                let subArray = array as [NSManagedObjectID]
                
                self.coreDataRepo.delete(containedInArray: subArray, completionBlock: {
                    
                    self.coreDataRepo.read(operationBlock: { (context) in
                        let results = self.coreDataRepo?.fetch(byPredicate: NSPredicate(format: "%K = %@", "categoryName", "categoryName"), entityName: "MCCategoryTest", context: context, resultType: .ManagedObjectIDResultType)
                        
                        XCTAssertTrue(results?.count == 2500)
                        
                        self.expectation.fulfill()
                    })
                    
                })
            }
        }
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            XCTAssertNil(error);
        }
        
    }
    
    func testCoreDataRepositoryObjectCreationAndReadOnMT_PlusUpdateOnBkgAndReadOnMT_08()
    {
        
        self.expectation = expectationWithDescription("Create and read on Main Thread - Update in Background and read on Main Thread")
        
        var dataSource: [AnyObject]? = nil
        
        self.coreDataRepo.write(operationBlock: { (context) in
            
            for index in 0..<5000 {
                
                let categoryID = String(index)
                let categoryName = "categoryName"
                
                let dictionary: [String: AnyObject] = ["categoryID": categoryID, "categoryName": categoryName]
                
                let createdObject = self.coreDataRepo?.create(dictionary: dictionary, entityName: "MCCategoryTest", context: context)
                XCTAssertFalse(createdObject == nil)

            }

            
        }) { (error) in
            
            
            }.read { (context) in
                dataSource = self.coreDataRepo?.fetch(entityName: "MCCategoryTest", context: context, resultType: .ManagedObjectResultType)
                
                XCTAssertTrue(dataSource?.count > 0)
        }
        
        //Here we Update the dataSource in background
        
        self.coreDataRepo.write(operationBlock: { (context) in
            
            let objs = context.moveInContext(managedObjects: dataSource as! [NSManagedObject])

            for obj in objs
            {
                if let category = obj as? MCCategoryTest {
                    category.categoryName = "UPDATED"
                }
            }
            
            }) { (error) in
                
        }.read_MT { (context) in
            dataSource = self.coreDataRepo?.fetch(entityName: "MCCategoryTest", context: context, resultType: .ManagedObjectResultType)

            for obj in dataSource!
            {
                if let category = obj as? MCCategoryTest {
                    XCTAssertTrue(category.categoryName == "UPDATED")
                }
            }

            XCTAssertTrue(dataSource?.count > 0)
            
            self.expectation.fulfill()
        }
        
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            XCTAssertNil(error);
        }
        
    }
    
}