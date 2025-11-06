//
//  NavigationRoutable.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import Foundation

protocol NavigationRoutable<Route>: ObservableObject {
    associatedtype Route: Hashable

    var destination: [Route] { get set }
    
    func push(to view: Route)
    func pop()
    func popToRootView()
}
