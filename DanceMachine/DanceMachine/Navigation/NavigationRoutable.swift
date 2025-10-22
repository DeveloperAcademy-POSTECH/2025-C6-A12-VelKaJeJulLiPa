//
//  NavigationRoutable.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import Foundation

protocol NavigationRoutable {

    var destination: [AppRoute] { get set }
    
    func push(to view: AppRoute)
    func pop()
    func popToRootView()
}
