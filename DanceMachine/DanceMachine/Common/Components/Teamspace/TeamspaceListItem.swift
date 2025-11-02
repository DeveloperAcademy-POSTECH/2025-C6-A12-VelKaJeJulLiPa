//
//  TeamspaceListItem.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/31/25.
//

import SwiftUI

struct TeamspaceListItem: View {
    
    let title: String
    
    var body: some View {
        
        Text(title)
            .padding(.vertical, 12)
            .padding(.leading, 16)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color.black) // FIXME: - 컬러 수정
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.gray) // FIXME: - 컬러 수정
            )// FIXME: - 컬러 수정
    }
}


#Preview {
    TeamspaceListItem(title: "벨카제줄리파")
    .frame(height: 43)
    .padding(.horizontal, 16)
}

