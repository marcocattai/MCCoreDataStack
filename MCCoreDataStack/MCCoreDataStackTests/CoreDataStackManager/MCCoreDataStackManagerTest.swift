//
//  MCCoreDataStackManagerTest.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import XCTest
import CoreData

@testable import MCCoreDataStack

class MCCoreDataStackManagerTest: XCTestCase
{
    private var defaultStoreURL: NSURL!
    private var defaultModelURL: NSURL!
    private var coreDataRepo: MCCoreDataRepository!
    private var expectation: XCTestExpectation!
    
    lazy var backgroundMOC: NSManagedObjectContext = {
        let bkgQueue = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        bkgQueue.mergePolicy = NSMergePolicy(mergeType: .OverwriteMergePolicyType)
        return bkgQueue
    }()
    
    override func setUp()
    {
        super.setUp();
        let dirPath = StackManagerHelper.Path.DocumentsFolder
        
        self.defaultStoreURL = NSURL(fileURLWithPath: dirPath.stringByAppendingString("/UnitTestsModel.sqlite"))

        self.defaultModelURL = NSBundle(forClass: MCCoreDataStackManagerTest.self).URLForResource("TestModel", withExtension: "momd")!
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        let dirPath = StackManagerHelper.Path.DocumentsFolder
        
        if NSFileManager.defaultManager().fileExistsAtPath(dirPath.stringByAppendingString("/UnitTestsModel.sqlite")) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(dirPath.stringByAppendingString("/UnitTestsModel.sqlite"))
            }catch {
                
            }
        }
    }
    
    func testCoreDataStackCreation01()
    {
        let coreDataStackManager = MCCoreDataStackManager(domainName: "co.uk.test.CoreDataStackManager", model: self.defaultModelURL)
        
        let configured = coreDataStackManager!.configure(storeURL: self.defaultStoreURL, configuration: "TestConfiguration")
        XCTAssertTrue(configured)
    
        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(self.defaultStoreURL.path!))
    }
}
