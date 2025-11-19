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
      Color.backgroundNormal.ignoresSafeArea()
      VStack {
        topTitleView.padding(.horizontal, 16)
        drawingView
      }
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
    LabeledContent {
      HStack(spacing: 16) {
        
        // 되돌리기
        Button {
          self.feedbackPaperDrawingData.undo()
        } label: {
          Image(systemName: "arrow.uturn.backward")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(Color.labelStrong)
        }
        
        /// 앞으로 가기
        Button {
          self.feedbackPaperDrawingData.redo()
        } label: {
          Image(systemName: "arrow.uturn.forward")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(Color.labelStrong)
        }
        
        
        // 이미지 삽입
        Button {
          self.showImagePicker = true
        } label: {
          Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(Color.labelStrong)
        }
        
        
        // 텍스트 삽입
        Button {
          // 기본 스타일의 NSAttributedString 생성
          let attributed = NSAttributedString(string: "텍스트를 입력해 주세요.", attributes: [
            .font: UIFont.systemFont(ofSize: 18, weight: .regular),
            .foregroundColor: UIColor.label
          ])
          
          // 기본 텍스트 박스 크기와 시작 위치를 정의 (상단 중앙 근처)
          let boxWidth: CGFloat = 200
          let boxHeight: CGFloat = 60
          // 화면 기준 적당한 위치 (여기서는 상단에서 100pt 아래, 가로 중앙 정렬)
          let originX: CGFloat = UIScreen.main.bounds.width/2 - boxWidth/2
          let originY: CGFloat = 100
          let rect = CGRect(x: originX, y: originY, width: boxWidth, height: boxHeight)
          
          self.feedbackPaperDrawingData.insertText(
            attributed,
            rect: rect
          )
        } label: {
          Image(systemName: "t.square")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(Color.labelStrong)
        }
        
        
        
        // 팬슬 툴
        Button {
          showTools.toggle()
          feedbackPaperDrawingData.showPencilKitTools(showTools)
        } label: {
          if showTools {
            Image(systemName: "pencil.circle.fill")
              .resizable()
              .scaledToFit()
              .frame(width: 24, height: 24)
              .foregroundStyle(Color.labelStrong)
          }
          else {
            Image(systemName: "pencil.circle")
              .resizable()
              .scaledToFit()
              .frame(width: 24, height: 24)
              .foregroundStyle(Color.labelStrong)
          }
        }
        
        
        // 완료 버튼
        Button {
          Task { @MainActor in
            // markup 데이터 먼저 export
            let markupData = try? await feedbackPaperDrawingData.exportMarkupData()

            // 최종 이미지 export (배경 + 드로잉 합성)
            if let image = await feedbackPaperDrawingData.exportAsImage(
              scale: displayScale,
              backgroundColor: UIColor(Color.materialDimmer)
            ) {
              onComplete?(image, markupData) // 이미지 + markup 데이터를 콜백으로 전달
              dismiss()
            } else {
              print("이미지 캡쳐 실패")
              dismiss()
            }
          }
        } label: {
          Image(systemName: "checkmark.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(Color.labelStrong)
        }
        
      }
    } label: {
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .resizable()
          .frame(width: 24, height: 24) // FIXME: - 크기 수정
          .foregroundStyle(Color.labelStrong)
      }
    }
    .font(.headline)
    .foregroundStyle(.black)
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

