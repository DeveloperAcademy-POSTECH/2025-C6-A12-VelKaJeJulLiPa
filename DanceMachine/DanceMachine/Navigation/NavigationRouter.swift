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
  private var isPushing = false

  func push(to view: Route) {
    // 중복 푸시 방지: 이미 푸시 중이거나 마지막 destination과 동일하면 무시
    guard !isPushing else { return }
    guard destination.last != view else { return }

    isPushing = true
    destination.append(view)

    // 0.5초 후 플래그 해제 (네비게이션 애니메이션 시간 고려)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      self?.isPushing = false
    }
  }

  func pop() { _ = destination.popLast() }
  func popToRootView() {  destination.removeAll() }

  deinit {
    // 아카이브 버그 해결 코드
  }
}
