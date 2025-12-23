//
//  TermsROw.swift
//  DanceMachine
//
//  Created by 조재훈 on 12/20/25.
//

import Foundation
import SwiftUI

struct TermsRow: View {
  let text: String
  let tapAction: () -> Void
  let toggleAction: () -> Void
  let isAgreed: Bool
  let isUnderline: Bool
  
  var body: some View {
    HStack(spacing: 0) {
      Text("필수")
        .font(.footnoteMedium)
        .foregroundStyle(.secondaryNormal)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
          RoundedRectangle(cornerRadius: 1000)
            .fill(.fillSubtle)
        }
      Spacer().frame(width: 8)
      Text(text)
        .underline(isUnderline)
        .font(.headline2SemiBold)
        .foregroundStyle(.labelNormal)
        .onTapGesture {
          tapAction()
        }
      Spacer()
      Button {
        toggleAction()
      } label: {
        Image(systemName: "checkmark.circle.fill")
          .resizable()
          .foregroundStyle(
            isAgreed ? .labelStrong : .labelAssitive,
            isAgreed ? .secondaryStrong : .fillAssitive
          )
          .overlay(
            Circle()
              .stroke(
                isAgreed ? .secondaryNormal : .labelAssitive,
                lineWidth: 1
              )
          )
          .frame(width: 23, height: 23)
      }
    }
  }
}

struct TermsAgreeCheckButton: View {
  let action: () -> Void
  let isAllTermsAgreed: Bool
  
  var body: some View {
    Button {
      action()
    } label: {
      Image(systemName: "checkmark.circle.fill")
        .resizable()
        .foregroundStyle(
          isAllTermsAgreed ? .labelStrong : .labelAssitive,
          isAllTermsAgreed ? .secondaryStrong : .fillAssitive
        )
        .overlay(
          Circle()
            .stroke(
              isAllTermsAgreed ? .secondaryNormal : .labelAssitive,
              lineWidth: 1
            )
        )
        .frame(width: 23, height: 23)
    }
  }
}
