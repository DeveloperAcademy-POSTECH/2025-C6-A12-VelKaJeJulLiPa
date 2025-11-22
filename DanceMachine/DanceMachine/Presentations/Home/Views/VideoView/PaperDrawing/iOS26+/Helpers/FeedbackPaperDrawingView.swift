//
//  FeedbackPaperDrawingView.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/6/25.
//

import SwiftUI
import PhotosUI

@available(iOS 26.0, *)
struct FeedbackPaperDrawingView: View {
  
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.displayScale) private var displayScale
  
  @State private var feedbackPaperDrawingData: FeedbackPaperDrawingData = .init()
  
  @Binding var image: UIImage?
  
  @State private var showTools: Bool = false
  
  
  /// 이미지
  @State private var showImagePicker: Bool = false
  @State private var photoItem: PhotosPickerItem?
  
  /// 완료 시 만들어진 이미지를 넘겨줄 콜백 (필요 없으면 nil)
  var onComplete: ((UIImage, Data?) -> Void)? // markup 데이터도 넣어줌
  var initialMarkupData: Data? = nil // markup 데이터
  
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      VStack {
        topTitleView.padding(.horizontal, 16)
        drawingView
      }
    }
    .onAppear {
      self.showTools = true
    }
    .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
    .onChange(of: photoItem) { oldValue, newValue in
      guard let newValue else { return }
      Task {
        guard let data = try? await newValue.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
          return
        }
        self.feedbackPaperDrawingData.insertImage(image, rect: .init(origin: .zero, size: .init(width: 200, height: 200)))
        photoItem = nil
      }
    }
  }
  
  // MARK: - 탑 타이틀
  private var topTitleView: some View {
    HStack(spacing: 12) {
      // X 버튼
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(Color.labelStrong)
      }
      .frame(width: 44, height: 44)
      .drawingButton()

      Spacer()

      // 버튼 그룹들
      HStack(spacing: 12) {
        // 그룹 1: Undo/Redo
        HStack(spacing: 0) {
          Button {
            self.feedbackPaperDrawingData.undo()
          } label: {
            Image(systemName: "arrow.uturn.backward")
              .font(.system(size: 22, weight: .medium))
              .foregroundStyle(Color.labelStrong)
          }
          .frame(width: 44, height: 44)

          Button {
            self.feedbackPaperDrawingData.redo()
          } label: {
            Image(systemName: "arrow.uturn.forward")
              .font(.system(size: 22, weight: .medium))
              .foregroundStyle(Color.labelStrong)
          }
          .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 4)
        .drawingButtonGroup()

        // 그룹 2: Image/Text/Pencil
        HStack(spacing: 12) {
          Button {
            self.showImagePicker = true
          } label: {
            Image(systemName: "photo.badge.plus")
              .font(.system(size: 22, weight: .medium))
              .foregroundStyle(Color.labelStrong)
          }
          .frame(width: 44, height: 44)

          Button {
            let attributed = NSAttributedString(string: "텍스트를 입력해 주세요.", attributes: [
              .font: UIFont.systemFont(ofSize: 22, weight: .regular),
              .foregroundColor: UIColor.white
            ])

            let boxWidth: CGFloat = 200
            let boxHeight: CGFloat = 60
            let originX: CGFloat = UIScreen.main.bounds.width/2 - boxWidth/2
            let originY: CGFloat = 100
            let rect = CGRect(x: originX, y: originY, width: boxWidth, height: boxHeight)

            self.feedbackPaperDrawingData.insertText(attributed, rect: rect)
          } label: {
            Image(systemName: "character.textbox")
              .font(.system(size: 22, weight: .medium))
              .foregroundStyle(Color.labelStrong)
          }
          .frame(width: 44, height: 44)

          Button {
            showTools.toggle()
            feedbackPaperDrawingData.showPencilKitTools(showTools)
          } label: {
            Image(systemName: showTools ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle")
              .font(.system(size: 22, weight: .medium))
              .foregroundStyle(Color.labelStrong)
          }
          .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 4)
        .drawingButtonGroup()

        // 그룹 3: 완료
        Button {
          Task { @MainActor in
            let markupData = try? await feedbackPaperDrawingData.exportMarkupData()

            if let image = await feedbackPaperDrawingData.exportAsImage(
              scale: displayScale,
              backgroundColor: UIColor(Color.materialDimmer)
            ) {
              onComplete?(image, markupData)
              dismiss()
            } else {
              print("이미지 캡쳐 실패")
              dismiss()
            }
          }
        } label: {
          Image(systemName: "checkmark")
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(Color.white)
        }
        .frame(width: 44, height: 44)
        .drawingSubmitButton()
      }
    }
    .padding(.horizontal, 16)
  }
  
  
  // MARK: - DrawingView
  private var drawingView: some View {
    GeometryReader { proxy in
      FeedbackPaperDrawingEditView(
        size: proxy.size,
        image: self.image,
        feedbackPaperDrawingData: feedbackPaperDrawingData,
        initialMarkupData: initialMarkupData
      )
    }
  }
}

#Preview {
  if #available(iOS 26.0, *) {
    NavigationStack {
      FeedbackPaperDrawingView(image: .constant(nil))
    }
  } else {
    // Fallback on earlier versions
  }
}

