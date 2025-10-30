//
//  FloatingActionButton.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/28/25.
//

import SwiftUI

struct FloatingActionButton: View {
    let mode: FABMode
    let isProjectListEmpty: Bool
    let onAddProject: () -> Void
    let onAddTrack: () -> Void

    var body: some View {
        Group {
            switch mode {
            case .addProject:
                Button(action: onAddProject) {
                    if isProjectListEmpty {
                        HStack(spacing: 4) {
                            Text("프로젝트 추가")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 30).fill(Color.blue)
                        )
                    } else {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 50, height: 50)
                            .overlay {
                                Image(systemName: "plus")
                                    .foregroundStyle(.white)
                            }
                    }
                }

            case .addTrack:
                Button(action: onAddTrack) {
                    HStack(spacing: 4) {
                        Text("곡 추가")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                        Image(systemName: "music.note")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 30).fill(Color.blue)
                    )
                }
            }
        }
        .padding([.trailing, .bottom], 16)
    }
}

#Preview {
    FloatingActionButton(
        mode: .addProject,
        isProjectListEmpty: false,
        onAddProject: {},
        onAddTrack: {}
    )
}
