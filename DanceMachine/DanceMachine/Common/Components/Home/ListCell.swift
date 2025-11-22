//
//  ListCell.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/17/25.
//

import SwiftUI

/// 리스트 셀 컴포넌트 입니다.
struct ListCell: View {
  
  var projectRowState: ProjectRowState = .viewing
  
  let title: String
  
  let deleteAction: () -> Void
  let editAction: () -> Void
  let rowTapAction: () -> Void
  var onTextChanged: (String) -> Void = { _ in }
  
  @Binding var editText: String
  
  // 화살표 회전 변수
  var isExpanded: Bool = false
  
  // 이 프로젝트를 수정/삭제할 수 있는지 여부 ( 팀 스페이스 오너, 프로젝트 생성자만 삭제 가능)
  //var canEdit: Bool = false
  
  @FocusState private var nameFieldFocused: Bool
  
  @Binding var showToastMessage: Bool
  
  var body: some View {
    HStack {
      switch projectRowState {
      case .viewing:
        Text(title)
          .font(.headline2Medium)
          .foregroundStyle(Color.labelStrong)
          .padding(16)
        Spacer()
        Image(systemName: "chevron.right")
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(Color.labelNormal)
          .rotationEffect(.degrees(isExpanded ? 90 : 0))
          .animation(.easeInOut(duration: 0.2), value: isExpanded)
          .padding(16)
        
      case .editing:
        HStack(spacing: 0) {
          // 왼쪽: 텍스트필드 + 글자수 + 밑줄
          VStack(spacing: 4) {
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              TextField("프로젝트 이름", text: $editText)
                .font(.headline2Medium)
                .foregroundStyle(Color.labelStrong)
                .tint(Color.labelStrong)
                .focused($nameFieldFocused)
                .onAppear {
                  nameFieldFocused = true
                }
                .onChange(of: editText) { oldValue, newValue in
                  if newValue.count < oldValue.count {
                    if newValue.count < 20 {
                      self.showToastMessage = false
                    }
                    return
                  }

                  let result = self.validateProjectName(
                    oldValue: oldValue,
                    newValue: newValue
                  )

                  if editText != result.text {
                    editText = result.text
                  }

                  self.showToastMessage = result.overText
                }

              Text("\(editText.count)/20")
                .font(.caption1Medium)
                .foregroundStyle(showToastMessage ? Color.accentRedNormal : Color.labelAssitive)

              Spacer(minLength: 0) // X 버튼 자리 때문에 오른쪽 밀어주기
            }
            .padding(.top, 12)
            .padding(.leading, 16)
            .padding(.trailing, 8)

            Rectangle()
              .fill(showToastMessage ? Color.accentRedNormal : Color.secondaryNormal)
              .frame(height: 1)
              .padding(.leading, 16)
              .padding(.trailing, 16)  // 밑줄은 기존처럼 전체 폭
              .padding(.bottom, 12)
          }

          // 오른쪽: X 버튼을 완전히 분리해서 끝에 고정
          XmarkButton {
            self.editText = ""
          }
          .padding(.vertical, 16.5)
          .padding(.trailing, 16)
          
        }
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(Color.fillNormal)
    )
    .contentShape(Rectangle())
    .simultaneousGesture(
      TapGesture()
        .onEnded {
          if case .viewing = projectRowState { rowTapAction() }
        }
    )
  }
  
  private var isUpdateMode: Bool {
    if case .editing = projectRowState { return true }
    return false
  }
  
  // 20글자 초과 확인 메서드
  private func validateProjectName(oldValue: String, newValue: String) -> ProjectNameValidationResult {
    var updated = newValue
    var overText = false
    
    // 1) 첫 글자 공백 막기
    if let first = updated.first, first == " " {
      updated = String(updated.drop(while: { $0 == " " }))
    }
    
    // 2) 20자 초과 여부 체크
    if updated.count > 20 {
      if updated.count == 21 {
        overText = true
      }
      updated = String(updated.prefix(20))
    }
    
    return ProjectNameValidationResult(
      text: updated,
      overText: overText
    )
  }
  
}

#Preview("수정 x") {
  ZStack {
    Color.backgroundNormal.ignoresSafeArea()
    
    ListCell(
      title: "수정",
      deleteAction: {
        
      },
      editAction: {
        
      },
      rowTapAction: {
        
      },
      editText: .constant(""),
      showToastMessage: .constant(false)
    )
    .padding(.horizontal, 16)
  }
}


