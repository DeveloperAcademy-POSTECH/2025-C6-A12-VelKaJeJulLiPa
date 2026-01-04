# DanceMachine

춤 동작 분석 및 피드백 iOS 앱

## 주요 기능

- MediaPipe를 활용한 실시간 포즈 추출
- Google Gemini AI 기반 춤 동작 분석 및 피드백
- Firebase 기반 협업 비디오 피드백 시스템
- 팀스페이스를 통한 프로젝트 관리

## 기술 스택

- **언어**: Swift 5.9+
- **UI**: SwiftUI
- **아키텍처**: MVVM + @Observable
- **백엔드**: Firebase (Auth, Firestore, Storage, Messaging)
- **포즈 분석**: MediaPipe Tasks Vision
- **AI 피드백**: Google Gemini AI (generative-ai-swift)
- **의존성 관리**: CocoaPods + Swift Package Manager

## 시작하기

### 필수 요구사항

- macOS 14.0+
- Xcode 15.0+
- iOS 17.0+ (타겟 디바이스)
- CocoaPods

### 설치

#### 방법 1: 자동 설치 (추천 ⭐)

```bash
# 1. 저장소 클론
git clone <repository-url>
cd DanceMachine

# 2. 설치 스크립트 실행
chmod +x setup.sh
./setup.sh
```

#### 방법 2: 수동 설치

```bash
# 1. 저장소 클론
git clone <repository-url>
cd DanceMachine

# 2. CocoaPods 의존성 설치
pod install

# 3. Xcode Workspace 열기 ⚠️ 중요!
open DanceMachine.xcworkspace
```

> ⚠️ **주의**: 반드시 `DanceMachine.xcworkspace`로 열어야 합니다!
> `DanceMachine.xcodeproj`로 열면 CocoaPods 라이브러리를 찾을 수 없습니다.

### 빌드 및 실행

1. Xcode에서 시뮬레이터 또는 실제 기기 선택
2. `⌘R`로 빌드 및 실행

## 프로젝트 구조

```
DanceMachine/
├── DanceMachine/              # 메인 앱 소스
│   ├── App/                   # 앱 진입점
│   ├── Presentations/         # MVVM Views & ViewModels
│   │   ├── Home/
│   │   ├── Inbox/
│   │   ├── MyPage/
│   │   └── Login/
│   ├── Service/               # Singleton 서비스 매니저
│   │   ├── FirebaseAuthManager.swift
│   │   ├── FirestoreManager.swift
│   │   └── NotificationManager.swift
│   ├── Models/                # 데이터 모델 (DTOs)
│   ├── Common/                # 재사용 컴포넌트, 유틸리티
│   ├── Navigation/            # 라우터 기반 네비게이션
│   └── Resource/              # 에셋, 폰트, 컬러
│
├── Packages/                  # 로컬 Swift Package
│   └── DancePoseAnalysis/     # 포즈 분석 모듈 (MediaPipe + Gemini)
│       ├── Package.swift
│       └── Sources/
│
├── Pods/                      # CocoaPods 의존성 (자동 생성, git 제외)
├── Podfile                    # CocoaPods 설정
├── Podfile.lock               # 버전 고정
└── DanceMachine.xcworkspace   # Xcode Workspace (자동 생성)
```

## 주요 아키텍처

### MVVM + @Observable Pattern

```swift
// ViewModel
@Observable
final class HomeViewModel {
    var state: HomeState = .idle

    func loadProjects() async {
        // 비즈니스 로직
    }
}

// View
struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        // UI
    }
}
```

### 네비게이션: Type-Safe Router

```swift
// MainRouter
enum MainRoute {
    case home
    case video(VideoRoute)
    case inbox(InboxRoute)
}

// 사용
mainRouter.push(to: .video(.play(videoId: id)))
```

### 데이터 플로우

```
Views → ViewModels → Managers (Singleton) → Firebase / Local Cache
```

## 의존성

### CocoaPods

```ruby
pod 'MediaPipeTasksVision', '~> 0.10.14'
```

### Swift Package Manager

- `DancePoseAnalysis` (로컬 패키지)
  - Google Generative AI Swift SDK
- Firebase iOS SDK
  - FirebaseAuth
  - FirebaseFirestore
  - FirebaseStorage
  - FirebaseMessaging
  - FirebaseRemoteConfig
- Kingfisher (이미지 캐싱)
- Lottie (애니메이션)


### Git Workflow

```bash
# 1. 최신 코드 받기
git checkout dev
git pull origin dev

# 2. 기능 브랜치 생성
git checkout -b feature/your-feature

# 3. 작업 후 커밋
git add .
git commit -m "feat: Add new feature"

# 4. Push
git push origin feature/your-feature

# 5. Pull Request 생성 (GitHub에서)
```

## 트러블슈팅

### "No such module 'DancePoseAnalysis'" 에러

```bash
# 1. Xcode 종료
# 2. 패키지 캐시 삭제
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 3. Xcode 재시작
open DanceMachine.xcworkspace

# 4. Xcode에서
File → Packages → Reset Package Caches
File → Packages → Resolve Package Versions
```

### CocoaPods 관련 에러

```bash
# Pods 재설치
pod deintegrate
pod install
```

### "xcworkspace 파일을 찾을 수 없음" 에러

```bash
# CocoaPods 설치가 안 된 경우
pod install
```


## 라이선스

Copyright © 2025 DirAct_Crew

## 기여

이슈나 개선 사항이 있다면 Issue를 생성해주세요.

---

