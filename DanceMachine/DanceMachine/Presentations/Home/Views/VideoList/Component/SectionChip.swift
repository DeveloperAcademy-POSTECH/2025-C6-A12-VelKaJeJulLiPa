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
        .background(
          Capsule()
            .fill(Color.clear)
        )
        .overlay(
          Capsule()
            .stroke(Color.black, lineWidth: 1.5)
        )
    }
  }
}

struct SectionChip: View {
  @Binding var vm: VideoListViewModel
  
  var body: some View {
    Button {
      vm.selectedSection = nil
    } label: {
      Text("전체")
        .font(.system(size: 15)) // FIXME: 폰트 수정
        .fontWeight(vm.selectedSection == nil ? .semibold : .regular) // FIXME: 폰트 수정
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
          Capsule()
            .fill(vm.selectedSection == nil ? Color.blue.opacity(0.15) : Color.white.opacity(0.1))
        )
        .overlay(
          Capsule()
          .stroke(vm.selectedSection == nil ? Color.blue : Color.clear, lineWidth: 1.5)
        )
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
        .font(.system(size: 15)) // FIXME: 폰트 수정
        .fontWeight(vm.selectedSection?.sectionId == id ? .semibold : .regular) // FIXME: 폰트 수정
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
          Capsule()
            .fill(vm.selectedSection?.sectionId == id ? Color.blue.opacity(0.15) : Color.white.opacity(0.1))
        )
        .overlay(
          Capsule()
            .stroke(vm.selectedSection?.sectionId == id ? Color.blue : Color.clear, lineWidth: 1.5)
        )
    }
  }
}

#Preview {
  SectionChip(vm: .constant(VideoListViewModel()))
}
