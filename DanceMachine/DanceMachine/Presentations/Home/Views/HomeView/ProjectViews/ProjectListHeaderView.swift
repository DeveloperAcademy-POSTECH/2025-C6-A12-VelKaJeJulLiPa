//
//  ProjectListHeaderView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/28/25.
//

import SwiftUI

struct ProjectListHeaderView: View {
  
  @Bindable var viewModel: ProjectListViewModel
  
  let labelText: String
  let isPrimaryDisabled: Bool
  let isEditing: Bool
  let onPrimaryUpdate: () -> Void
  
  var body: some View {
    LabeledContent {
      HStack(spacing: 16) {
        Button {
          // viewing일 때만 + 동작
          if !isEditing {
            viewModel.presentationState.presentingCreateProjectSheet = true
          }
        } label: {
          Group {
            if !isEditing {
              HStack(spacing: 4) {
                Image(systemName: "plus")
                  .font(.system(size: 17, weight: .medium))
                Text("추가")
                  .font(.headline2SemiBold)
              }
              .foregroundStyle(Color.secondaryNormal)
              .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
              CheckmarkButton(disable: isPrimaryDisabled) {
                onPrimaryUpdate()
              }
              .transition(.move(edge: .bottom).combined(with: .opacity))
            }
          }
        }
      }
    } label: {
      Group {
        if !isEditing {
          Text("프로젝트")
            .font(.headline2SemiBold)
            .foregroundStyle(Color.labelAssitive)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
          Text(labelText)   // "프로젝트 목록" or "트랙 목록"
            .font(.title2SemiBold)
            .foregroundStyle(Color.labelStrong)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
    }
    .animation(
      .easeInOut(duration: 0.25),
      value: isEditing
    )
  }
}

#Preview {
  ProjectListHeaderView(
    viewModel: ProjectListViewModel(),
    labelText: "하이",
    isPrimaryDisabled: true,
    isEditing: false) {
      
    }
}

