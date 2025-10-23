//
//  TrackRow.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/22/25.
//

import SwiftUI

/// 트랙 셀 (ListCell 과 동일한 분기/바인딩 패턴)
struct TrackRow: View {
    let track: Tracks
    var rowState: TracksRowState = .viewing

    let deleteAction: () -> Void       // 삭제 버튼 탭
    let editAction: () -> Void         // “수정” 버튼 탭 → 상위에서 .editing(.update)로 전환
    let rowTapAction: () -> Void       // 보기 모드에서 행 탭

    // 상위(HomeView 등)와 텍스트 동기화
    @Binding var editText: String
    var onTextChanged: (String) -> Void = { _ in }

    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "music.note.list")

            switch rowState {
            case .viewing:
                Text(track.trackName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                Spacer()
                Image(systemName: "chevron.right")

            case .editing(let action):
                switch action {
                case .none, .delete:
                    Text(track.trackName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                    Spacer()
                    HStack(spacing: 16) {
                        Button("삭제", action: deleteAction)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.red)
                            .buttonStyle(.plain)

                        Button("수정", action: editAction)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.blue)
                            .buttonStyle(.plain)
                    }

                case .update:
                    VStack(spacing: .zero) {
                        TextField("곡 이름", text: $editText)
                            .font(.system(size: 16, weight: .semibold))
                            .textFieldStyle(.plain)
                            .focused($nameFieldFocused)
                            // update 모드로 바뀌는 순간 1회 초기화
                            .onChange(of: rowState) { _, new in
                                if case .editing(.update) = new {
                                    editText = track.trackName
                                    nameFieldFocused = true
                                    onTextChanged(editText)
                                }
                            }
                            .onChange(of: editText) { _, new in
                                onTextChanged(new)
                            }

                        Rectangle()
                            .fill(Color.blue)
                            .frame(height: 1)
                    }

                    Spacer()

                    XmarkButton { self.editText = "" }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if case .viewing = rowState { rowTapAction() }
        }
    }
}

#Preview {
    TrackRow(
        track: .init(
            trackId: UUID(),
            projectId: "project",
            creatorId: "creator",
            trackName: "Aespa - Rich Man"
        ),
        rowState: .viewing,
        deleteAction: {},
        editAction: {},
        rowTapAction: {},
        editText: .constant("")
    )
    .padding()
}
