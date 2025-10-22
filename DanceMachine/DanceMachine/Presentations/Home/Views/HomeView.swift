//
//  ContentView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var router: NavigationRouter
    
    @State private var viewModel: HomeViewModel = .init()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }.task {
            await viewModel.setupNotificationAuthorizationIfNeeded()
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
