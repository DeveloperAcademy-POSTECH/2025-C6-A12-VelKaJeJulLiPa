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
      Image(systemName: "folder.badge.gearshape") // FIXME: 아이콘 수정?
        .foregroundStyle(.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
//        .background(
//          Capsule()
//            .fill(Color.clear)
//        )
//        .overlay(
//          Capsule()
//            .stroke(Color.black, lineWidth: 1.5)
//        )
    }
    .glassEffect(.clear.tint(Color.purple.opacity(0.5)).interactive(), in: Capsule())
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
        .font(.system(size: 18)) // FIXME: 폰트 수정
        .fontWeight(vm.selectedSection?.sectionId == id ? .semibold : .regular) // FIXME: 폰트 수정
        .foregroundStyle(vm.selectedSection?.sectionId == id ? Color.blue : Color.black) // FIXME: 폰트 수정
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
//        .background(
//          Capsule()
//            .fill(vm.selectedSection?.sectionId == id ? Color.blue.opacity(0.15) : Color.white.opacity(0.1))
//        )
//        .overlay(
//          Capsule()
//            .stroke(vm.selectedSection?.sectionId == id ? Color.blue : Color.black, lineWidth: 1.5)
//        )
    }
    .glassEffect(.clear.tint(Color.purple.opacity(0.5)).interactive(), in: Capsule())
  }
}

//#Preview {
//  SectionChip(vm: .constant(VideoListViewModel()))
//}
