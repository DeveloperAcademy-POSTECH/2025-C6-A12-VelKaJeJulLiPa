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
    HStack(alignment: .center, spacing: 40) { //FIXME: spacing 간격 수정
      Image(member.imageName)
        .resizable()
        .scaledToFill()
        .frame(width: 100, height: 100) //FIXME: 이미지 크기 수정
        .background(member.backgroundColor) //FIXME: 이미지 배경색 확인
        .clipShape(Circle())
      
      VStack(alignment: .leading, spacing: 8) { //FIXME: spacing 간격 수정
        // 이름
        Text("\(member.nameKor) / \(member.nameEng)")
          .font(.heading1SemiBold)
          .foregroundStyle(.secondaryNormal)
        
        // 역할
        Text(member.role)
          .font(.heading1SemiBold)
          .foregroundStyle(.labelNormal)
        
      }
      
      Spacer()
    }
    .padding(.vertical, 16) //FIMXE: 패딩 수정
    .padding(.horizontal, 26) //FIMXE: 패딩 수정
  }
}


#Preview {
  ZStack {
    Color.backgroundNormal.ignoresSafeArea()
    VStack(spacing: 0) {
      TeamMemberRow(member: .paidion)
      TeamMemberRow(member: .julianne)
      TeamMemberRow(member: .libby)
    }
  }
  
}
