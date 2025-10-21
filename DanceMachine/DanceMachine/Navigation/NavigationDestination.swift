//
//  NavigationDestination.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import Foundation

enum NavigationDestination: Equatable, Hashable {
    case homeView // FIXME: - 임시
    case videoListView(
      tracksId: String,
      sectionId: String,
      trackName: String
    )
    case sectionEditView(
      section: [Section],
      tracksId: String,
      trackName: String
    )
}
