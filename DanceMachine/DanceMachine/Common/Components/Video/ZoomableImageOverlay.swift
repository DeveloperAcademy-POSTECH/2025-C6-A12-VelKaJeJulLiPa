//
//  ZoomableImageOverlay.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/12/25.
//

import SwiftUI

struct ZoomableImageOverlay<Content: View>: View {
  @Binding var isPresented: Bool
  let backgroundColor: Color
  let content: () -> Content   // 실제 이미지는 밖에서 넣어줌 (UIImage든 KFImage든)

  @State private var scale: CGFloat = 1.0
  @State private var baseScale: CGFloat = 1.0
  @State private var offset: CGSize = .zero
  @State private var baseOffset: CGSize = .zero

  var body: some View {
    GeometryReader { proxy in
      if isPresented {
        ZStack {
          backgroundColor.ignoresSafeArea()
            .onTapGesture {
              close()
            }

          VStack {

            Spacer()

            let magnification = MagnificationGesture()
              .onChanged { value in
                let newScale = baseScale * value
                scale = min(max(newScale, 1.0), 8.0)
                if scale == 1.0 {
                  offset = .zero
                  baseOffset = .zero
                }
              }
              .onEnded { _ in
                baseScale = scale
              }

            let drag = DragGesture()
              .onChanged { value in
                guard scale > 1.0 else {
                  offset = .zero
                  return
                }
                let newOffset = CGSize(
                  width: baseOffset.width + value.translation.width,
                  height: baseOffset.height + value.translation.height
                )
                offset = newOffset
              }
              .onEnded { _ in
                if scale > 1.0 {
                  baseOffset = offset
                } else {
                  offset = .zero
                  baseOffset = .zero
                }
              }

            let isLandscape = proxy.size.width > proxy.size.height
            let maxWidthRatio: CGFloat = isLandscape ? 0.5 : 0.9
            let maxHeightRatio: CGFloat = isLandscape ? 0.95 : 0.8

            content()
              .frame(
                maxWidth: proxy.size.width * maxWidthRatio,
                maxHeight: proxy.size.height * maxHeightRatio
              )
              .clipShape(RoundedRectangle(cornerRadius: 12))
              .scaleEffect(scale)
              .offset(offset)
              .gesture(
                magnification.simultaneously(with: drag)
              )

            Spacer()
          }
        }
        .overlay(alignment: .topLeading, content: {
          Button {
            close()
          } label: {
            Image(systemName: "xmark.circle.fill")
              .resizable()
              .scaledToFit()
              .frame(width: 44, height: 44)
              .foregroundStyle(Color.labelStrong)
          }
          .drawingButton()
          .padding()
        })
        .transition(.opacity)
        .zIndex(999)
      }
    }
  }

  private func close() {
    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
      isPresented = false
      scale = 1.0
      baseScale = 1.0
      offset = .zero
      baseOffset = .zero
    }
  }
}

//#Preview {
//  ZoomableImageOverlay<<#Content: View#>>()
//}
