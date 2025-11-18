//
//  VideoListContent.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/19/25.
//

import SwiftUI

struct VideoListContent: View {
  let geometry: GeometryProxy
  let tracksId: String
  let videos: [Video]
  let track: [Track]
  let section: [Section]
  let pickerViewModel: VideoPickerViewModel
  @Binding var vm: VideoListViewModel

  var body: some View {
    let horizontalPadding: CGFloat = 16
    let spacing: CGFloat = 16
    let columns = 2

    let totalSpacing = spacing * CGFloat(columns - 1)
    let availableWidth = geometry.size.width - (horizontalPadding * 2) - totalSpacing
    let itemSize = availableWidth / CGFloat(columns)

    VideoGrid(
      size: itemSize,
      columns: columns,
      spacing: spacing,
      tracksId: tracksId,
      videos: videos,
      track: track,
      section: section,
      pickerViewModel: pickerViewModel,
      vm: $vm
    )
    .padding(.horizontal, horizontalPadding)
  }
}

//#Preview {
//    VideoListContent()
//}
