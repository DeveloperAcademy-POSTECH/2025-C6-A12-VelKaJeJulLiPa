//
//  TrackAddButtonRow.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/21/25.
//

import SwiftUI

struct TrackAddButtonRow: View {
  
  let isEmptyTracks: Bool
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image("musicPlus")
          .resizable()
          .scaledToFit()
          .frame(width: 17, height: 17)
        
        Text("곡 추가하기")
          .font(.headline2Medium)
          .foregroundStyle(Color.labelStrong)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 47)
      .background(
        RoundedRectangle(cornerRadius: 15)
          .fill(isEmptyTracks ? Color.secondaryStrong : Color.fillAssitive)
      )
    }
    .buttonStyle(.plain)
  }
}


#Preview {
  TrackAddButtonRow(isEmptyTracks: false) {
    
  }
}
