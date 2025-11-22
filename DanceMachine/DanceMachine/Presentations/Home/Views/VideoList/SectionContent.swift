//
//  SectionContent.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/19/25.
//

import SwiftUI

struct SectionContent: View {
  @EnvironmentObject private var router: MainRouter
  @Binding var vm: VideoListViewModel
  
  let tracksId: String
  let trackName: String
  let sectionId: String
  
  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        SectionChipIcon(
          vm: $vm,
          action: {
            router.push(
              to: .video(
                .section(
                  section: vm.section,
                  tracksId: tracksId,
                  trackName: trackName,
                  sectionId: sectionId
                )
              )
            )
          }
        )
        if vm.isLoading {
          ForEach(0..<5, id: \.self) { _ in
            SkeletonChipVIew()
          }
        } else {
          ForEach(vm.section, id: \.sectionId) { section in
            CustomSectionChip(
              vm: $vm,
              action: { vm.selectedSection = section },
              title: section.sectionTitle,
              id: section.sectionId
            )
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 24)
      .padding(.bottom, 16)
    }
    .scrollDisabled(vm.isLoading)
  }
}

//#Preview {
//  SectionContent()
//}
