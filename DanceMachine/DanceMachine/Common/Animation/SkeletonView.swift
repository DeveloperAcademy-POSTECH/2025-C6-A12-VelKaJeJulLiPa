//
//  SkeletonView.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/1/25.
//

import SwiftUI

/**
 스켈레톤 애니메이션 효과를 제공하는 제네릭 뷰입니다.
 
 로딩 중인 콘텐츠 대신 임시로 표시되어 사용자에게 비동기 데이터 로딩 중임을 시각적으로 알려줍니다.
 `Shape` 프로토콜을 채택한 어떤 도형이든 인자로 받아 동일한 형태로 스켈레톤을 그립니다.
 
 - Parameters:
 - shape: 스켈레톤의 모양을 정의하는 `Shape` 인스턴스 (예: `Circle()`, `RoundedRectangle(cornerRadius:)`)
 - color: 스켈레톤의 기본 색상. 기본값은 `.gray.opacity(0.3)`
 
 - note:
 **사용 방법 예시**
 ```swift
 // 원형 스켈레톤
 SkeletonView(Circle())
  .frame(width: 60, height: 60)
 
 // 둥근 모서리 사각형 스켈레톤
 SkeletonView(RoundedRectangle(cornerRadius: 8))
  .frame(width: 120, height: 20)
 
 
 // 리스트 로딩 중 UI 예시
 VStack {
  ForEach(0..<5, id: \.self) { _ in
    SkeletonView(RoundedRectangle(cornerRadius: 10))
      .frame(height: 48)
      .padding(.horizontal, 16)
  }
 }
 */
struct SkeletonView<S: Shape>: View {
  
  var shape: S
  var color: Color
  
  init(
    _ shape: S,
    _ color: Color = .gray.opacity(0.6) // FIXME: - 컬러 수정
  ) {
    self.shape = shape
    self.color = color
  }
  
  @State private var isAnimation: Bool = false
  
  /// Customizable Properties
  var rotation: Double {
    return 5
  }
  
  var animation: Animation {
    .easeInOut(duration: 1.5).repeatForever(autoreverses: false)
  }
  
  
  var body: some View {
    shape
      .fill(color)
    // Skeleton Effect
      .overlay {
        GeometryReader { // Shape 모양의 오버레이에 GeomeryReader가 있다는 것.
          let size = $0.size
          let skeletonWidth = size.width / 2
          
          let blurRadius = max(skeletonWidth / 1.5, 40)
          let blurDiameter = blurRadius * 2
          
          let minX = -(skeletonWidth + blurDiameter)
          let maxX = size.width + skeletonWidth + blurDiameter
          
          
          Rectangle()
//            .fill(.gray)
//            .frame(width: skeletonWidth, height: size.height * 2)
            .fill(
              LinearGradient(
                colors: [
                  .white.opacity(0.6),
                  .white.opacity(0.25),
                  .white.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .frame(width: skeletonWidth * 1.5, height: size.height * 2)
            .frame(height: size.height)
            .blur(radius: blurRadius)
            .rotationEffect(.init(degrees: rotation)) // rotation(도 단위) 값만큼 사각형을 회전시킴 (애니메이션용)
            .blendMode(.softLight) // softLight 블렌드 모드 적용 (밑 배경과 자연스럽게 섞임)
            .offset(x: isAnimation ? maxX : minX) // isAnimation 값에 따라 왼쪽에서 오른쪽으로 이동시킴 (스켈레톤 애니메이션 효과)
          
        }
      }
      .clipShape(shape)
      .compositingGroup()
      .task {
        guard !isAnimation else { return }
        withAnimation(animation) {
          isAnimation = true
        }
      }
      .onDisappear {
        isAnimation = false
      }
      .transaction {
        if $0.animation != animation {
          $0.animation = .none
        }
      }
  }
}

#Preview("원") {
  @Previewable
  @State var isTapped: Bool = false
  
  SkeletonView(.circle)
    .frame(width: 100, height: 100)
    .onTapGesture {
      withAnimation(.smooth) {
        isTapped.toggle()
      }
    }
    .padding(.bottom, isTapped ? 15 : 0)
}

#Preview("사각형") {
  @Previewable
  @State var isTapped: Bool = false
  
  SkeletonView(.rect)
    .frame(width: 100, height: 100)
    .onTapGesture {
      withAnimation(.smooth) {
        isTapped.toggle()
      }
    }
    .padding(.bottom, isTapped ? 15 : 0)
}

#Preview("캡슐") {
  @Previewable
  @State var isTapped: Bool = false
  
  SkeletonView(.capsule)
    .frame(width: 100, height: 100)
    .onTapGesture {
      withAnimation(.smooth) {
        isTapped.toggle()
      }
    }
    .padding(.bottom, isTapped ? 15 : 0)
}
