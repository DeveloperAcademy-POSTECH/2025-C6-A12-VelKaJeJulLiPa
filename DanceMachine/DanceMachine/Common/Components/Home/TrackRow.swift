//
//  TrackRow.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/22/25.
//

import SwiftUI

struct TrackRow: View {
    let track: Tracks
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "music.note.list")
            Text(track.trackName)
                .font(.system(size: 16, weight: .semibold))
            Spacer()
            Image(systemName: "chevron.right")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

#Preview {
    TrackRow(
        track: .init(
            trackId: UUID(),
            projectId: "아니야",
            creatorId: "아니야",
            trackName: "아니야"
        )
    )
}
