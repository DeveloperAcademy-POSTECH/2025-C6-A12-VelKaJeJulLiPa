//
//  TeamMemberRow.swift
//  DanceMachine
//
//  Created by Paidion on 11/8/25.
//

import SwiftUI

struct TeamMemberRow: View {
  let member: TeamMember
  
  var body: some View {
    HStack(alignment: .center, spacing: 53) {
      Image(member.imageName)
        .frame(width: 85, height: 85)
        .background(Color.secondaryAssitive)
        .clipShape(Circle())
      
      VStack(alignment: .leading, spacing: 7) {
        // 이름
        Text("\(member.nameKor)/\(member.nameEng)")
          .font(.heading1SemiBold)
          .foregroundStyle(.secondaryNormal)
        
        // 역할
        Text(member.role)
          .font(.heading1SemiBold)
          .foregroundStyle(.labelNormal)
          .fixedSize(horizontal: true, vertical: false)
      }
      Spacer()
    }
    .padding(.top, 16)
    .padding(.bottom, 22)
    .padding(.horizontal, 26)
  }
}


#Preview {
  ZStack {
    Color.backgroundNormal.ignoresSafeArea()
    VStack(spacing: 0) {
      TeamMemberRow(member: .velko)
      TeamMemberRow(member: .kadan)
      TeamMemberRow(member: .paidion)
      TeamMemberRow(member: .jacob)
      TeamMemberRow(member: .julianne)
      TeamMemberRow(member: .libby)
    }
  }
}
