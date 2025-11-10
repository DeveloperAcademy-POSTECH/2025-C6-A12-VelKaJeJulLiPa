//
//  ProjectListHeaderView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/28/25.
//

import SwiftUI

struct ProjectListHeaderView<S: RowEditingState>: View {
  @Bindable var viewModel: HomeViewModel
  @Binding var state: S
  @Binding var labelText: String
  let isPrimaryDisabled: Bool
  let onPrimaryUpdate: () -> Void
  let onCancelSideEffects: () -> Void
  
  var body: some View {
    LabeledContent {
      HStack(spacing: 16) {
        if state.isViewing {
          Button(state.primaryTitle) {
            state.enterEditingNone()
          }
          .font(.headline1Medium)
          .foregroundStyle(Color.labelStrong)
          .clearGlassButtonIfAvailable()
        }
        else {
          CheckmarkButton(disable: isPrimaryDisabled) {
            if state.isUpdating {
              onPrimaryUpdate()
            }
            else {
              state.enterViewing()
              onCancelSideEffects()
            }
          }
        }
      }
    } label: {
      Text(labelText)
        .font(.title2SemiBold)
        .foregroundStyle(Color.labelStrong)
    }
  }
}


#Preview("Project · viewing") {
  ZStack {
    Color.backgroundNormal.ignoresSafeArea()
    ProjectListHeaderView(
      viewModel: HomeViewModel(),
      state: .constant(ProjectRowState.viewing),
      labelText: .constant("프로젝트 목록"),
      isPrimaryDisabled: false,
      onPrimaryUpdate: {},
      onCancelSideEffects: {}
    )
    .padding()
  }
}

#Preview("Project · updating (enabled)") {
  ZStack {
    Color.backgroundNormal.ignoresSafeArea()
    ProjectListHeaderView(
      viewModel: HomeViewModel(),
      state: .constant(ProjectRowState.editing(.update)),
      labelText: .constant("프로젝트 이름 수정"),
      isPrimaryDisabled: false,
      onPrimaryUpdate: {},
      onCancelSideEffects: {}
    )
    .padding()
  }
}

#Preview("Tracks · editing none (disabled)") {
  ZStack {
    Color.backgroundNormal.ignoresSafeArea()
    ProjectListHeaderView(
      viewModel: HomeViewModel(),
      state: .constant(TracksRowState.editing(.none)),
      labelText: .constant("트랙 목록"),
      isPrimaryDisabled: true,
      onPrimaryUpdate: {},
      onCancelSideEffects: {}
    )
    .padding()
  }
}
