//
//  AppMakerView.swift
//  DanceMachine
//
//  Created by Paidion on 11/6/25.
//

import SwiftUI

struct AppMakerView: View {
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      ScrollView {
        VStack(spacing: 0) {
          ForEach(TeamMember.allCases, id: \.self) { member in
            TeamMemberRow(member: member)
            Divider()
          }
        }
      }
    }
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron)
      ToolbarCenterTitle(text: "DirAct를 만든 사람들")
    }
  }
}

#Preview {
  AppMakerView()
}
