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
      Image(systemName: "folder.fill.badge.gearshape")
        .font(.system(size: 20))
        .foregroundStyle(.primitiveStrong)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .sectionIcon()
//        .background(
//          Capsule()
//            .fill(Color.black)
//        )
//        .clearGlassButtonIfAvailable()
    }
//    .glassEffect(.clear.tint(Color.purple.opacity(0.5)).interactive(), in: Capsule())
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
//        .background(
//          Capsule()
//            .fill(vm.selectedSection?.sectionId == id ? .secondaryNormal : Color.black)
//        )
//        .clearGlassButtonIfAvailable()
    }
//    .glassEffect(.clear.tint(Color.purple.opacity(0.5)).interactive(), in: Capsule())
  }
}

//#Preview {
//  SectionChip(vm: .constant(VideoListViewModel()))
//}
