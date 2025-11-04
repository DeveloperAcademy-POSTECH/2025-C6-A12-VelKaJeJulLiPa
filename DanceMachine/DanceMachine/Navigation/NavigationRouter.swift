//
//  NavigationRouter.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import Foundation
import Combine

class NavigationRouter<Route: Hashable>: NavigationRoutable {
  @Published var destination: [Route] = []
  
  func push(to view: Route) { destination.append(view) }
  func pop() { _ = destination.popLast() }
  func popToRootView() {  destination.removeAll() }
}
