//
//  SectionEditRow.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/17/25.
//

import SwiftUI

struct SectionEditRow: View {
  let section: Section
  let isEditing: Bool
//  let onEditComplete: () -> Void
  let onEditStart: () -> Void
  let onDelete: () -> Void
  
  
  @Binding var editText: String
  @FocusState private var isFocused: Bool
  
  var body: some View {
    RoundedRectangle(cornerRadius: 5)
      .fill(Color.gray.opacity(0.6))
      .frame(maxWidth: .infinity)
      .frame(height: 43)
      .overlay {
        sectionRow
      }
  }
  
  private var sectionRow: some View {
    HStack {
      if isEditing {
        TextField("섹션 이름", text: $editText)
          .textFieldStyle(.plain)
          .font(.system(size: 16)) // FIXME: 폰트 수정
          .focused($isFocused)
          .onAppear {
            isFocused = true
          }
        Button {
          self.editText = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.gray)
        }
      } else { // 일반 모드
        Text(section.sectionTitle)
          .font(.system(size: 16)) // FIXME: 폰트 수정
        Spacer()
        Button {
          onEditStart()
        } label: {
          Text("수정")
            .font(Font.system(size: 14, weight: .medium)) // FIXME: 폰트 수정
            .foregroundStyle(Color.blue) // FIXME: 컬러 수정
        }
        Button {
          onDelete()
        } label: {
          Text("삭제")
            .font(Font.system(size: 14, weight: .medium)) // FIXME: 폰트 수정
            .foregroundStyle(Color.blue) // FIXME: 컬러 수정
        }
      }
    }
    .padding(.horizontal, 16)
  }
}

#Preview {
  SectionEditRow(
    section: Section(sectionId: "", sectionTitle: "dd"),
    isEditing: true,
    onEditStart: {},
    onDelete: {} ,
    editText: .constant("dd")
  )
}
