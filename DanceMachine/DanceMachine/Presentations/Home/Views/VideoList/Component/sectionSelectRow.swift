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
    RoundedRectangle(cornerRadius: 5)
      .fill(isSelected ? Color.gray.opacity(0.6) : Color.gray.opacity(0.2))
      .frame(maxWidth: .infinity)
      .frame(height: 43)
      .overlay {
        sectionRow
      }
  }
  
  private var sectionRow: some View {
    HStack {
      Text(section.sectionTitle)
        .font(.system(size: 16)) // FIXME: 폰트 수정
      Spacer()
      if isSelected {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(Color.blue) // FIXME: 컬러 수정
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
