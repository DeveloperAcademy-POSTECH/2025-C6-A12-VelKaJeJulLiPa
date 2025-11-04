//
//  SkeletonChipVIew.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/4/25.
//

import SwiftUI

struct SkeletonChipVIew: View {
  var body: some View {
    SkeletonView(Capsule())
    .frame(width: 64, height: 36)
  }
}

#Preview {
  SkeletonChipVIew()
}
