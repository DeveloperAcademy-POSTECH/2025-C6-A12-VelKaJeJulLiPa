//
//  NavigationRouter.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import Foundation
import Combine

class NavigationRouter: ObservableObject, NavigationRoutable {
    @Published var destination: [AppRoute] = []

    func push(to view: AppRoute) { destination.append(view) }
    func pop() { _ = destination.popLast() }
    func popToRootView() {  destination.removeAll() }
}
