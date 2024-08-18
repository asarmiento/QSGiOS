//
//  UserEntity+CoreDataProperties.swift
//  QGS
//
//  Created by Edin Martinez on 8/12/24.
//
//

import Foundation
import CoreData


extension UserEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var email: String?
    @NSManaged public var token: String?
    @NSManaged public var sysconf: Int32

}

extension UserEntity : Identifiable {

}
