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

class MCCoreDataStackManagerTest: XCTestCase {
    fileprivate var defaultStoreURL: URL!
    fileprivate var coreDataRepo: MCCoreDataRepository!
    fileprivate var expectation: XCTestExpectation!

    lazy var backgroundcontext: NSManagedObjectContext = {
        let bkgQueue = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        bkgQueue.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)
        return bkgQueue
    }()

    override func setUp() {
        super.setUp()
        let dirPath = StackManagerHelper.Path.DocumentsFolder

        self.defaultStoreURL = URL(fileURLWithPath: dirPath + "/UnitTestsModel.sqlite")
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        let dirPath = StackManagerHelper.Path.DocumentsFolder

        if FileManager.default.fileExists(atPath: dirPath + "/UnitTestsModel.sqlite") {
            do {
                try FileManager.default.removeItem(atPath: dirPath + "/UnitTestsModel.sqlite")
            } catch {

            }
        }
    }

    func testCoreDataStackCreation01() {

        let bundle = Bundle(for: type(of: self))
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [bundle])!
        let cdsManager = MCCoreDataStackManager(domain: "uk.co.mccoredtastack.test", model: managedObjectModel)

        let asyncExpectation = expectation(description: "CoreDataStackCreation")

        cdsManager?.configure(url: self.defaultStoreURL, configuration: nil) {
            XCTAssertTrue(FileManager.default.fileExists(atPath: self.defaultStoreURL.path))
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("Error: \(error)")
            }
        }
    }
}
