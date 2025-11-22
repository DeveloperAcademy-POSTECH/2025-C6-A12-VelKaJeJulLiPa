//
//  SectionChip.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/16/25.
//

import SwiftUI

struct SectionChipIcon: View {
  @Binding var vm: VideoListViewModel
  let action: () -> Void
  
  var body: some View {
    Button {
      action()
    } label: {
      Image(.partEdit)
        .foregroundStyle(.primitiveStrong)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .sectionIcon()
    }
  }
}

struct CustomSectionChip: View {
  @Binding var vm: VideoListViewModel
  let action: () -> Void
  let title: String
  let id: String
  
  var body: some View {
    Button {
      action()
    } label: {
      Text(title)
        .font(.headline1Medium)
        .foregroundStyle(.labelStrong)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .sectionChip(isSelected: vm.selectedSection?.sectionId == id)
    }
  }
}

//#Preview {
//  SectionChip(vm: .constant(VideoListViewModel()))
//}
