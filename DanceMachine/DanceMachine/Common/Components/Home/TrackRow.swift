//
//  TrackRow.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/22/25.
//

import SwiftUI

struct TrackRow: View {
  
  @Bindable var viewModel: ProjectListViewModel
  
  let track: Tracks
  var rowState: TracksRowState = .viewing
  
  let deleteAction: () -> Void
  let editAction: () -> Void
  let rowTapAction: () -> Void
  
  var onTextChanged: (String) -> Void = { _ in }
  
  @Binding var editText: String
  @FocusState private var nameFieldFocused: Bool
  
  var canEdit: Bool = false
  @Binding var showToastMessage: Bool
  
  var body: some View {
    HStack(spacing: 10) {
      
      // editing이면 왼쪽 아이콘 숨김
      if rowState == .editing {
        EmptyView()
      } else {
        Image(systemName: "music.note.list")
          .foregroundStyle(Color.labelStrong)
      }
      
      switch rowState {
        
      case .viewing:
        Text(track.trackName)
          .font(.headline2Medium)
          .foregroundStyle(.labelStrong)
        Spacer()
        Image(systemName: "chevron.right")
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(Color.labelNormal)
        
      case .editing:
        HStack(spacing: 0) {
          VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              TextField("곡 이름", text: $editText)
                .font(.headline2Medium)
                .foregroundStyle(Color.labelStrong)
                .textFieldStyle(.plain)
                .focused($nameFieldFocused)
                .onAppear {
                  editText = track.trackName
                  Task { @MainActor in
                    // TextField가 리스트에 붙고 난 다음 틱에 포커싱
                    await Task.yield()
                    nameFieldFocused = true
                    onTextChanged(editText)
                  }
                }
                .onChange(of: editText) { oldValue, newValue in
                  // 삭제 방향이면 경고만 정리
                  if newValue.count < oldValue.count {
                    if newValue.count < 20 {
                      showToastMessage = false
                    }
                    onTextChanged(newValue)
                    return
                  }
                  
                  // 입력 증가일 때만 검증
                  let result = validateTrackName(oldValue: oldValue, newValue: newValue)
                  
                  if editText != result.text {
                    editText = result.text
                  }
                  
                  showToastMessage = result.overText
                  onTextChanged(editText)
                }
              
              Text("\(editText.count)/20")
                .font(.caption1Medium)
                .foregroundStyle(showToastMessage ? Color.accentRedNormal : Color.labelAssitive)
              
              Spacer(minLength: 0)
            }
            .padding(.top, 12)
            
            Rectangle()
              .fill(showToastMessage ? Color.accentRedNormal : Color.secondaryNormal)
              .frame(height: 1)
              .padding(.top, 6)
              .padding(.bottom, 12)
          }
          
          XmarkButton { self.editText = "" }
            .padding(.vertical, 16.5)
            .offset(x: 16)
        }
        Spacer()
      }
    }
    .contentShape(Rectangle())
    .simultaneousGesture(
      TapGesture().onEnded {
        if rowState == .viewing { rowTapAction() }
      }
    )
  }
  
  private func validateTrackName(oldValue: String, newValue: String) -> ProjectNameValidationResult {
    var updated = newValue
    var overText = false
    
    if let first = updated.first, first == " " {
      updated = String(updated.drop(while: { $0 == " " }))
    }
    
    if updated.count > 20 {
      if updated.count == 21 { overText = true }
      updated = String(updated.prefix(20))
    }
    
    return ProjectNameValidationResult(text: updated, overText: overText)
  }
}

#Preview {
  ZStack {
    Color.backgroundNormal.ignoresSafeArea()
    TrackRow(
      viewModel: ProjectListViewModel(),
      track: .init(
        tracksId: UUID(),
        projectId: "project",
        creatorId: "creator",
        trackName: "Aespa - Rich Man"
      ),
      rowState: .viewing,
      deleteAction: {
      },
      editAction: {},
      rowTapAction: {},
      editText: .constant(""),
      showToastMessage: .constant(false)
    )
    .padding()
  }
}
