//
//  sectionSelectRow.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/20/25.
//

import SwiftUI

struct SectionSelectRow: View {
  let section: Section
  let isSelected: Bool
  
  var body: some View {
    RoundedRectangle(cornerRadius: 10)
      .fill(isSelected ? .fillAssitive : .fillSubtle)
      .strokeBorder(isSelected ? Color.secondaryNormal : Color.clear, lineWidth: 1)
      .frame(maxWidth: .infinity)
      .frame(height: 43)
      .overlay {
        sectionRow
      }
      .contentShape(Rectangle())
  }
  
  private var sectionRow: some View {
    HStack {
      Text(section.sectionTitle)
        .font(.headline2Medium)
        .foregroundStyle(.labelStrong)
      Spacer()
      if isSelected {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.secondaryNormal)
      }
    }
    .padding(.horizontal, 16)
  }
}

#Preview {
  SectionSelectRow(
    section: Section(
      sectionId: "",
      sectionTitle: "ddd"
    ),
    isSelected: true
  )
}
