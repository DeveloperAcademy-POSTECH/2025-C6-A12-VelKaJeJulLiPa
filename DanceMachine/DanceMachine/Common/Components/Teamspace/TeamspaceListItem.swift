//
//  TeamspaceListItem.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/31/25.
//

import SwiftUI

struct TeamspaceListItem: View {
  
  let title: String
  var isCreated: Bool = false
  
  var body: some View {
    
    HStack {
      if isCreated {
        Image(systemName: "plus.circle")
          .foregroundStyle(Color.secondaryNormal)
      } else {
        EmptyView()
      }
      Text(title)
        .font(.headline2Medium)
        .foregroundStyle(isCreated ? Color.secondaryNormal : Color.labelNormal)
    }
      .padding(.vertical, 12)
      .padding(.leading, 16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: 5)
          .fill(Color.fillNormal)
      )
  }
}


#Preview {
  ZStack {
    Color.backgroundNormal.ignoresSafeArea()
    TeamspaceListItem(title: "벨카제줄리파", isCreated: false)
      .frame(height: 43)
      .padding(.horizontal, 16)
  }
}

