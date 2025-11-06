//
//  SectionEditRow.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/17/25.
//

import SwiftUI

struct SectionEditRow: View {
  
  let tracksId: String
  let section: Section
  let isEditing: Bool
  let onEditStart: () -> Void
  let sheetAction: () -> Void
  let onDeleteIfEmpty: () -> Void
  
  @State private var showDeleteModal: Bool = false
  @Binding var editText: String
  @Binding var showToast: Bool
  @FocusState private var isFocused: Bool
  
  var body: some View {
    RoundedRectangle(cornerRadius: 10)
      .fill(.fillNormal)
      .frame(maxWidth: .infinity)
      .frame(height: 43)
      .overlay {
        sectionRow
      }
      .alert(
        "\(section.sectionTitle)파트를 삭제하시겠어요?",
        isPresented: $showDeleteModal) {
          Button("취소", role: .cancel) {}
          Button("삭제", role: .destructive) {
            sheetAction()
          }
        } message: {
          Text("삭제하면 복구할 수 없습니다.")
        }
  }
  
  private var sectionRow: some View {
    HStack {
      if isEditing {
        TextField("파트 이름", text: $editText)
          .textFieldStyle(.plain)
          .font(.headline2Medium)
          .foregroundStyle(.labelStrong)
          .focused($isFocused)
          .onChange(of: editText) { oldValue, newValue in
            var updated = newValue
            
            // Prevent leading space as the first character
            if updated.first == " " {
              updated = String(updated.drop(while: { $0 == " " })) // ❗️공백 금지
            }
            
            // Enforce 10-character limit
            if updated.count > 10 {
              NotificationCenter.post(.showEditWarningToast, object: nil)
              updated = String(updated.prefix(10)) // ❗️10글자 초과 금지
            }
            
            if updated != editText {
              editText = updated
            }
          }
          .overlay {
            Rectangle()
              .frame(height: 2)
              .foregroundStyle(
                editText.count > 9 ? .accentRedNormal : .secondaryAssitive
              )
              .padding(.top, 30)
              .overlay(alignment: .trailing) {
                if editText.count > 9 {
                  Text("10/10")
                    .font(.caption1Medium)
                    .foregroundStyle(.accentRedNormal)
                }
              }
          }
          .onAppear {
            isFocused = true
          }
        Button { // xmark: 텍스트 비어있을때는 섹션 제거, 아니면 텍스트 비우기
          if editText == "" {
            onDeleteIfEmpty()
          } else {
            self.editText = ""
          }
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.labelNormal)
        }
      } else { // 일반 모드
        Text(section.sectionTitle)
          .font(.headline2Medium)
          .foregroundStyle(.labelStrong)
        Spacer()
        Button {
          onEditStart()
        } label: {
          Text("수정")
            .font(.headline2Medium)
            .foregroundStyle(.accentBlueNormal)
        }
        Button {
          self.showDeleteModal = true
        } label: {
          Text("삭제")
            .font(.headline2Medium)
            .foregroundStyle(.accentRedNormal)
        }
      }
    }
    .padding(.horizontal, 16)
  }
}

#Preview {
  SectionEditRow(
    tracksId: "",
    section: Section(sectionId: "", sectionTitle: "dd"),
    isEditing: true,
    onEditStart: {},
    sheetAction: {},
    onDeleteIfEmpty: {},
    editText: .constant("dd"), showToast: .constant(true)
  )
}
