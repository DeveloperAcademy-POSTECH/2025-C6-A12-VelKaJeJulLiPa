//
//  SectionEditView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/17/25.
//

import SwiftUI

struct SectionEditView: View {
  @EnvironmentObject private var router: NavigationRouter
  @Binding var vm: VideoListViewModel
  
  let trackName: String
  
  var body: some View {
    VStack {
      customHeader
      text
      Spacer().frame(height: 15)
      listView
      Spacer()
    }
    .padding(.horizontal, 16)
  }
  
  private var customHeader: some View {
    HStack(alignment: .top, spacing: 16) {
      Button {
        router.pop()
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.black)
      }
      VStack(alignment: .leading, spacing: 4) {
        Text("섹션 관리")
          .font(.system(size: 17, weight: .semibold))
        Text(trackName)
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
      }
      .onTapGesture {
        router.pop()
      }
      Spacer()
    }
    .padding(.vertical, 12)
  }
  
  
  private var text: some View {
    HStack {
      Text("섹션 리스트")
        .font(Font.system(size: 14, weight: .semibold)) // FIXME: 폰트 수정
        .foregroundStyle(Color.gray.opacity(0.8))
      Spacer()
    }
  }
  
  private var listView: some View {
    ScrollView {
      ForEach(vm.section, id: \.sectionId) { section in
        RoundedRectangle(cornerRadius: 5)
          .fill(Color.gray.opacity(0.2)) // FIXME: 컬러 수정
          .frame(maxWidth: .infinity)
          .frame(height: 43)
          .overlay {
            HStack {
              Text(section.sectionTitle)
                .font(Font.system(size: 14, weight: .medium)) // FIXME: 폰트 수정
              Spacer()
              editLabel
            }
            .padding(.horizontal, 16)
          }
      }
    }
  }
  
  private var editLabel: some View {
    HStack(spacing: 16) {
      Button {
        // TODO: 삭제 기능
      } label: {
        Text("삭제")
          .font(Font.system(size: 14, weight: .medium)) // FIXME: 폰트 수정
          .foregroundStyle(Color.red) // FIXME: 컬러 수정
      }
      Button {
        // TODO: 수정 기능
      } label: {
        Text("수정")
          .font(Font.system(size: 14, weight: .medium)) // FIXME: 폰트 수정
          .foregroundStyle(Color.blue) // FIXME: 컬러 수정
      }
    }
  }
}

#Preview {
  @Previewable @State var vm: VideoListViewModel = .preview
  NavigationStack {
    SectionEditView(vm: $vm, trackName: "벨코의 리치맨")
  }
  .environmentObject(NavigationRouter())
}
