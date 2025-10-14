//
//  GridCell.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/15/25.
//

import SwiftUI

struct GridCell: View {
  let size: CGFloat
  
  let title: String
  let duration: Double
  let uploadDate: Date
  
  var body: some View {
    Rectangle()
      .fill(Color.gray.opacity(0.5))
      .frame(width: size, height: size)
      .overlay {
        content
      }
  }
  
  private var content: some View {
    VStack {
      Text("동영상 썸네일")
      Text(title)
      HStack {
        Text("\(duration)")
        Text("\(uploadDate)")
      }
      .padding(.horizontal, 5)
    }
  }
}

#Preview {
  GridCell(
    size: 168,
    title: "제목",
    duration: 14.1414141414,
    uploadDate: Date()
  )
}
