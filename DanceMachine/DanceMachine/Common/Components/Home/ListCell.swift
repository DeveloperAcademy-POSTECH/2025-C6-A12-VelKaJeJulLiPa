//
//  ListCell.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/17/25.
//

import SwiftUI

/// 리스트 셀 컴포넌트 입니다.
struct ListCell: View {
  let title: String
  var projectRowState: ProjectRowState = .viewing
  
  let deleteAction: () -> Void
  let editAction: () -> Void
  let rowTapAction: () -> Void
  
  var onTextChanged: (String) -> Void = { _ in }
  
  @Binding var editText: String
  
  var isExpanded: Bool = false // 화살표 회전 변수
  
  @FocusState private var nameFieldFocused: Bool
  
  var body: some View {
    HStack {
      switch projectRowState {
      case .viewing:
        Text(title)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.black)
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
        Spacer()
        Image(systemName: "chevron.right")
          .foregroundStyle(Color.black) // FIXME: - 컬러 수정
          .rotationEffect(.degrees(isExpanded ? 90 : 0))
          .animation(.easeInOut(duration: 0.2), value: isExpanded)
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
      case .editing(let action):
        switch action {
        case .none, .delete:
          Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
          Spacer()
          HStack(spacing: 16) {
            Button("삭제", action: deleteAction)
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(.red)
              .buttonStyle(.plain)
            
            Button("수정", action: editAction) // ← 이걸 누르면 상위에서 .editing(.update)로 전환
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(.blue)
              .buttonStyle(.plain)
          }
          .padding(.horizontal, 16)
        case .update:
          VStack(spacing: .zero) {
            TextField("프로젝트 명", text: $editText)
              .font(.system(size: 16, weight: .semibold))
              .textFieldStyle(.plain)
              .padding(.leading, 16)
              .padding(.top, 12)
              .focused($nameFieldFocused)
              .onChange(of: projectRowState) { _, new in
                if case .editing(.update) = new {
                  // 셀이 update 모드로 바뀐 그 순간만 초기화
                  editText = title
                  nameFieldFocused = true
                  onTextChanged(editText)
                }
              }
              .onChange(of: editText) { _, newValue in
                // 프로젝트 리스트 글자 제한
                var updated = newValue

                if updated.first == " " {
                  updated = String(updated.drop(while: { $0 == " " })) // ❗️공백 금지
                }

                if updated.count > 20 {
                  updated = String(updated.prefix(20)) // ❗️20글자 초과 금지
                }

                if updated != editText {
                  editText = updated
                }
    
                onTextChanged(newValue)
              }
            
            Rectangle()
              .fill(Color.blue)
              .frame(height: 1)
              .padding(.leading, 16)
              .padding(.bottom, 12)
          }
          
          Spacer()
          
          XmarkButton { self.editText = "" }
            .padding(.trailing, 16)
          
        }
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 5)
        .fill(Color.gray)
    )
    .contentShape(Rectangle())
    //        .onTapGesture {
    //            if case .viewing = projectRowState { rowTapAction() }
    //        }
    .simultaneousGesture(
      TapGesture()
        .onEnded {
          if case .viewing = projectRowState { rowTapAction() }
        }
    )
  }
  
  private var isUpdateMode: Bool {
    if case .editing(.update) = projectRowState { return true }
    return false
  }
}

#Preview("수정 x") {
  ListCell(
    title: "수정",
    deleteAction: {
      
    },
    editAction: {
      
    },
    rowTapAction: {
      
    }, editText: .constant("")
  )
  .padding(.horizontal, 16)
}
