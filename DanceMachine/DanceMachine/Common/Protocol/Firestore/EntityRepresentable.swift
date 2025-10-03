//
//  EntityRepresentable.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/30/25.
//

import Foundation

protocol EntityRepresentable {
    var entityName: CollectionType { get }
    var documentID: String { get }
    var asDictionary: [String: Any]? { get }
}

