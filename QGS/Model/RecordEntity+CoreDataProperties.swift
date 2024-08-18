//
//  RecordEntity+CoreDataProperties.swift
//  QGS
//
//  Created by Edin Martinez on 8/12/24.
//
//

import Foundation
import CoreData


extension RecordEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecordEntity> {
        return NSFetchRequest<RecordEntity>(entityName: "RecordEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var type: String?
    @NSManaged public var date: Date?
    @NSManaged public var times: String?

}

extension RecordEntity : Identifiable {

}
