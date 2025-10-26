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
                TabView(selection: $tabcase, content: {
                    ForEach(TabCase.allCases, id: \.rawValue) { tab in
                        Tab(
                            value: tab,
                            content: {
                              NavigationStack(path: $router.destination) {
                                tabView(tab: tab)
                                  .navigationDestination(
                                    for: AppRoute.self,
                                    destination: { destination in
                                      NavigationRoutingView(
                                        destination: destination
                                      )
                                      .environmentObject(router)
                                    })
                              }
                                    .tag(tab)
                            },
                            label: {
                                tabLabel(tab)
                            })
                    }
                  Tab(value: tabcase, role: .search) {
                    Color.clear
                  } label: {
                    Image(systemName: "plus.circle.fill")
//                    Text("영상 추가하기")
                  }
//                  Tab(value: TabCase.myPage, role: .search) {
//                    Image(systemName: "plus.circle.fill")
//                  }
                })
                .tint(Color.red)
//                .tabBarMinimizeBehavior(.onScrollDown)
//                .tabViewBottomAccessory {
////                  bottomAccessory(for: .home)
//                  HStack {
//                    Spacer()
//                    uploadButton
//                      .frame(width: 180)
//                    Spacer()
//                  }
//                }
                .onChange(of: tabcase) { oldValue, newValue in
                     if oldValue != newValue {
                         router.destination.removeAll()
                     }
                 }


                
    }

    @ViewBuilder
    private var homeTabAccessory: some View {
      if router.destination.isEmpty {
        EmptyView()
      } else if let current = router.destination.last {
        switch current {
        case .video:
          uploadButton
        default:
          EmptyView()
        }
      }
    }
  
  @ViewBuilder
  private func bottomAccessory(for tab: TabCase) -> some View {
      switch tab {
      case .home:
        homeTabAccessory
      case .inbox:
          EmptyView()
      case .myPage:
          EmptyView()
      }
  }
  
  private var uploadButton: some View {
      Button {
        print("비디오 피커 버튼")
        NotificationCenter.default.post(
          name: .showVideoPicker,
          object: nil
        )
      } label: {
        Text("동영상 업로드")
          .font(.system(size: 17)) // FIXME: 폰트 수정
          .foregroundStyle(Color.white)
          .padding(.horizontal, 20)
      }
      .frame(maxWidth: .infinity)
    .frame(height: 47)
//    .glassEffect(.clear.tint(Color.purple.opacity(0.8)).interactive(), in: Capsule())
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
