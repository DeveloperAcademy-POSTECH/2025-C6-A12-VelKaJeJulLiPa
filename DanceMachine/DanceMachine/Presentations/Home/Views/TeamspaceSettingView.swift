//
//  TeamspaceSettingView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/12/25.
//

import SwiftUI

struct TeamspaceSettingView: View {
    
    @EnvironmentObject private var rotuer: NavigationRouter
    
    var body: some View {
        ZStack {
            Color.white
            
            VStack {
                Text("팀 스페이스 설정")
            }
        }
        .padding(.horizontal, 16)
        .toolbar {
            ToolbarLeadingBackButton()
            ToolbarCenterTitle(text: "팀 스페이스 설정")
        }
    }
}

#Preview {
    NavigationStack {
        TeamspaceSettingView()
            .environmentObject(NavigationRouter())
    }
}
