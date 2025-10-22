//
//  RootView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject private var router: NavigationRouter
    @State var tabcase: TabCase = .home
    
    var body: some View {
        NavigationStack(
            path: $router.destination,
            root: {
                TabView(selection: $tabcase, content: {
                    ForEach(TabCase.allCases, id: \.rawValue) { tab in
                        Tab(
                            value: tab,
                            content: {
                                tabView(tab: tab)
                                    .tag(tab)
                            },
                            label: {
                                tabLabel(tab)
                            })
                    }
                })
                .tint(Color.blue)
                .navigationDestination(
                    for: AppRoute.self,
                    destination: { destination in
                        NavigationRoutingView(
                            destination: destination
                        )
                    .environmentObject(router)
            })
        })
    }
  
  @ViewBuilder
  private func bottomAccessory(for tab: TabCase) -> some View {
      switch tab {
      case .home:
          uploadButton
          .padding(.horizontal, 50)
      case .inbox:
          EmptyView()
      case .myPage:
          EmptyView()
      }
  }
  private var glassButton: some View {
    GlassEffectContainer {
      HStack(spacing: 20) {
//        homeButton
        uploadButton
      }
    }
  }
  
  private var homeButton: some View {
    Button {
      // TODO: 여긴 뭐지?
    } label: {
      Image(systemName: "house.fill")
        .foregroundStyle(Color.purple.opacity(0.8))
    }
    .frame(width: 47, height: 47)
    .glassEffect(.clear.interactive(), in: .circle)
  }
  
  private var uploadButton: some View {
    Button {
      //
    } label: {
      Text("동영상 업로드")
        .font(.system(size: 17)) // FIXME: 폰트 수정
        .foregroundStyle(Color.white)
        .padding(.horizontal, 20)
    }
    .frame(maxWidth: .infinity, alignment: .center)  // 중앙 정렬
                 .padding(.horizontal, 16)
                 .background(.clear)  // 투명!
//    .frame(maxWidth: .infinity)
    .frame(height: 47)
    .glassEffect(.clear.tint(Color.purple.opacity(0.8)).interactive(), in: Capsule())
  }
    
    private func tabLabel(_ tab: TabCase) -> some View {
        VStack(spacing: 8, content: {
            Image(systemName: tab.icon)
            
            Text(tab.rawValue)
                .font(Font.system(size: 12))
                .foregroundStyle(Color.black)
        })
    }
    
    @ViewBuilder
    private func tabView(tab: TabCase) -> some View {
        Group {
            switch tab {
            case .home:
                NavigationRoutingView(
                    destination: .home
                )
            case .inbox:
                NavigationRoutingView(
                    destination: .inbox(.list)
                )
            case .myPage:
                NavigationRoutingView(
                    destination: .mypage(.profile)
                )
            }
        }
        .environmentObject(router)
    }
}

#Preview {
    NavigationStack {
        RootView()
            .environmentObject(NavigationRouter())
    }
}
