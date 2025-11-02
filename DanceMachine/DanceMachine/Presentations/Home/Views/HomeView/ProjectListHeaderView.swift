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
                if let sec = state.secondaryTitle {
                    Button(sec) {
                        state.enterViewing()
                        onCancelSideEffects()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(state.secondaryColor)
                }
                Button(state.primaryTitle) {
                    if state.isUpdating {
                        onPrimaryUpdate()
                    } else if state.isViewing {
                        state.enterEditingNone()
                        onCancelSideEffects()
                    } else {
                        state.enterViewing()
                        onCancelSideEffects()
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(state.primaryColor)
                .disabled(isPrimaryDisabled)
                .opacity(isPrimaryDisabled ? 0.5 : 1.0)
            }
        } label: {
            Text(labelText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.gray)
        }
    }
}


#Preview("Project · viewing") {
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

#Preview("Project · updating (enabled)") {
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

#Preview("Tracks · editing none (disabled)") {
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
