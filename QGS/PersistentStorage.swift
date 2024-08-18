//
//  PersistentStorage.swift
//  QGS
//
//  Created by Edin Martinez on 8/13/24.
//

import Foundation
import CoreData

final class PersistentStorage{
    
    private init(){}
    static let shared = PersistentStorage()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "QGSDataBase")
        container.loadPersistentStores(completionHandler: {
            (storeDescription, error) in
            if let error = error as NSError?{
               
                
                fatalError("one unresolved error \(error),\(error.userInfo)")
            }
            
            
        })
        return container
    }()
    
    lazy var context = persistentContainer.viewContext
    
    func saveContext(){
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("unresolved error \(nserror),\(nserror.userInfo)")
            }
        }
    }
}
