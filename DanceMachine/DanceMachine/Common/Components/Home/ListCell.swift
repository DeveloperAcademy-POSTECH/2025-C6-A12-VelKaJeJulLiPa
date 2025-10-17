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
    var isEditing: EditingState = .viewing

    let deleteAction: () -> Void
    let editAction: () -> Void
    let rowTapAction: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Spacer()

            switch isEditing {
            case .editing:
                HStack(spacing: 16) {
                    Button(action: deleteAction) {
                        Text("삭제")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    Button(action: editAction) {
                        Text("수정")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
            case .viewing:
                Image(systemName: "chevron.right")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.gray)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing == .viewing { rowTapAction() }
        }
    }
}

#Preview("수정 x") {
    ListCell(
        title: "2025 가을 축제",
        isEditing: .viewing) {
            print("삭제 액션")
        } editAction: {
            print("수정 액션")
        } rowTapAction: {
            print("셀 영역 터치 액션")
        }
        .padding(.horizontal, 16)
}

#Preview("수정 o") {
    ListCell(
        title: "2025 가을 축제",
        isEditing: .editing) {
            print("삭제 액션")
        } editAction: {
            print("수정 액션")
        } rowTapAction: {
            print("셀 영역 터치 액션")
        }
        .padding(.horizontal, 16)
}
