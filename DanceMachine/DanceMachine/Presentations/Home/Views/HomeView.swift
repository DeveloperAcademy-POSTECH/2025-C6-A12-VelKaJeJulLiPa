//
//  ContentView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            //FIXME: - Test code for user authentication.
            Text("\(Auth.auth().currentUser?.email)")
            Text("\(Auth.auth().currentUser?.displayName)")

            Button("Sign out") {
                FirebaseAuthManager.shared.signOut()
            }
            
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
