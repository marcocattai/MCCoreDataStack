# MCCoreDataStack
MCCoreDataStack is a simple SWIFT wrapper around Apple's Core Data Framework to create, save and fetch Managed Objects

##Documentation
[API Reference](https://marcocattai.github.io/MCCoreDataStack/)

##Introduction:

It is a very simple, thread safe, swift library that helps you dig into the CoreData Framework. 
I have created it for a personal project and it is on my personal library since February 2016.

This library has been used with success and it doesn't have any particoular issue. Here on github it could be be useful to other developers that hopefully will contribute to it. Feel free to create pull requests. Thank you in advance for that. 

####MCCoreDataStackManager 

This class includes all the basic functionalities to setup a CoreData Stack. It uses the approach described by Core Data guru Marcus Zarra which builds on the above Parent/Child method but adds an additional context exclusively for writing to disk. A lenghty write operation might block the main thread for a short time causing the UI to freeze. This smart approach uncouples the writing into its own private queue and keeps the UI smooth.

![alt tag](https://dl.dropboxusercontent.com/u/7201536/model.png)

####MCCoreDataRepository
 This class includes an helper method to setup a CoreDataStack using MCCoreDataStackManager. This class provides basic functionalities to create, delete and fetch NSManagedObjects.

##Integrate in your existing project

###You can use Cocoapods to install EUCoreDataStack adding it to your Pod file

```
platform :ios, '8.0'
use_frameworks!

target 'MyApp' do
    pod 'EUCoreDataStack'
end
```

###Manually (iOS 7+)

To use this library on iOS 7 
- drag Library folder to the project tree
- Build the project
- #import "[YourProductModuleName]-Swift.h"

###This library supports chaining

This library supports chaining of write - read - read_MT operations. For more information please refer to the following examples.

##How to use:

####Setup CoreDataStack
```swift
self.coreDataRepo = MCCoreDataRepository()
let success = self.coreDataRepo.setup(storeName: "TestDB.sqlite", domainName: "co.uk.tests")
```
####Create one object in background, fetch it on the main queue and delete it in background
```swift
//Here we define our Dictionaries

let subDictionary: [String: AnyObject] = ["subCategoryID": "sub12345", "subCategoryName": "subTest12345"]
let dictionary: [String: AnyObject] = ["categoryID": "12345", "categoryName": "Test12345", "subCategory": subDictionary]

self.coreDataRepo.write(operationBlock: { (context) in

   	self.coreDataRepo.create(dictionary: dictionary, entityName: "MCCategoryTest", context: context)
 
   }) { (error) in
   
	//Object is persisted on disk
	
})

//Here we don't use chaining

self.coreDataRepo.read_MT { (context) in
   
	let results = self.coreDataRepo.fetch(entityName: "MCCategoryTest", context: context, resultType: .ManagedObjectResultType) as? [NSManagedObject]

   	// Objects will be deleted in a background thread. Deletion will fetch the objects from the background context
   	self.coreDataRepo.delete(containedInArray: results, completionBlock: nil)
}

```
####Let's try to Create 5000 fake objects in background and then fetch them, using chaining, to populate the UI

```swift

var dataSource: [AnyObject]? = nil
        
self.coreDataRepo.write(operationBlock: { (context) in
            
            for index in 0..<5000 {
                
                let categoryID = String(index)
                let categoryName = "categoryName"
                let dictionary: [String: AnyObject] = ["categoryID": categoryID, "categoryName": categoryName]
                self.coreDataRepo.create(dictionary: dictionary, entityName: "MCCategoryTest", context: context)
            }

            
	}) { (error) in
        	//Here they are persisted
        	
}.read_MT { (context) in

	dataSource = self.coreDataRepo.fetch(entityName: "MCCategoryTest", context: context, resultType: .ManagedObjectResultType)
}
```
####Now We want to update the dataSource of the above example
####After the update, we want to fetch it on the main context (used by the main Thread)

```swift

self.coreDataRepo.write(operationBlock: { (context) in
            
	let objs = context.moveInContext(managedObjects: dataSource as! [NSManagedObject])

	for obj in objs {
       		if let category = obj as? MCCategoryTest {
                    category.categoryName = "UPDATED"
                }
        }
            
}) { (error) in
            //Here they are persisted
}.read_MT { (context) in
	dataSource = self.coreDataRepo.fetch(entityName: "MCCategoryTest", context: context, resultType: .ManagedObjectResultType)

	//Here we have our updated objects

}

```
####Read and update objects in background

```swift

	self.coreDataRepo.write(operationBlock: { (context) in
		let results = self.coreDataRepo.fetch(byPredicate: NSPredicate(format: "%K = %@", "categoryName", "categoryName"), entityName: "MCCategoryTest", context: context, resultType: .ManagedObjectResultType)
		
		//Here we update our objects in BKG
	
	}, completion: nil)
		
```

... Please, refer to the unit tests. On the unit tests I have tested the creation / fetch and deletion of thousand of objects

##Tracking Violations

1) Please enable  Enable Core Data multi-threading assertions by passing following arguments during app launch.

```
-com.apple.CoreData.ConcurrencyDebug 1
```
2) Verify that Xcode prints out following text in console to indicate that the multi-threading assertions is enabled. 

```
CoreData: annotation: Core Data multi-threading assertions enabled.
```
3) Once the Core Data debugging is enabled, Xcode will throw an exception whenenver the app attempts to access an instance of managed object from a wrong context. You might want to check this change into your version control system so that everyone in your team can benefit from tracking these violations early during development.

