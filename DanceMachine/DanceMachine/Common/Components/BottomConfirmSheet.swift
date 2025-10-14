//
//  BottomConfirmSheet.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/14/25.
//

import SwiftUI

struct BottomConfirmSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let titleText: String
    let primaryText: String
    let primaryAction: () -> Void
    
    var body: some View {
        VStack {
            Text(titleText)
                .font(Font.system(size: 18, weight: .semibold)) // FIXME: - 폰트 수정
                .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            
            Spacer().frame(height: 32)
            
            Button(action: { primaryAction() ; dismiss() }) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red) // FIXME: - 컬러 수정
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .overlay {
                        Text(primaryText)
                            .font(Font.system(size: 21, weight: .semibold)) // FIXME: - 폰트 수정
                            .foregroundStyle(Color.white) // FIXME: - 컬러 수정
                    }
            }
            
            Spacer().frame(height: 8)
            
            Button(action: { dismiss() }) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray) // FIXME: - 컬러 수정
                    .overlay {
                        Text("취소")
                            .font(Font.system(size: 21, weight: .semibold)) // FIXME: - 폰트 수정
                            .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                    }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
    }
}


#Preview {
    BottomConfirmSheet(
        titleText: "벨카제줄리파\n팀스페이스를 삭제하시겠어요?",
        primaryText: "팀 스페이스 삭제") {
            
        }
}
