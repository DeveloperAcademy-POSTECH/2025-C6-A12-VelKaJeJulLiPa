#!/bin/bash

# DanceMachine 프로젝트 초기 설정 스크립트
# 이 스크립트는 프로젝트를 처음 클론한 후 필요한 모든 설정을 자동으로 수행합니다.

set -e  # 에러 발생 시 스크립트 중단

echo "🚀 DanceMachine 프로젝트 설정을 시작합니다..."
echo ""

# 1. CocoaPods 설치 확인
echo "📦 CocoaPods 확인 중..."
if ! command -v pod &> /dev/null; then
    echo "⚠️  CocoaPods가 설치되어 있지 않습니다."
    echo "📥 CocoaPods를 설치합니다..."
    sudo gem install cocoapods
    echo "✅ CocoaPods 설치 완료!"
else
    echo "✅ CocoaPods가 이미 설치되어 있습니다. ($(pod --version))"
fi
echo ""

# 2. Podfile 존재 확인
if [ ! -f "Podfile" ]; then
    echo "❌ Podfile을 찾을 수 없습니다."
    echo "   현재 위치: $(pwd)"
    echo "   DanceMachine 프로젝트 루트에서 실행해주세요."
    exit 1
fi

# 3. CocoaPods 의존성 설치
echo "📥 CocoaPods 의존성을 설치합니다..."
echo "   (MediaPipe 등 라이브러리 다운로드 - 약 1-2분 소요)"
pod install

if [ $? -eq 0 ]; then
    echo "✅ CocoaPods 의존성 설치 완료!"
else
    echo "❌ CocoaPods 설치 중 에러가 발생했습니다."
    exit 1
fi
echo ""

# 4. Swift Package 의존성 확인
echo "📦 Swift Package 의존성 확인 중..."
if [ -d "Packages/DancePoseAnalysis" ]; then
    echo "✅ DancePoseAnalysis 로컬 패키지 확인 완료"
else
    echo "⚠️  DancePoseAnalysis 패키지를 찾을 수 없습니다."
fi
echo ""

# 5. Workspace 파일 확인
if [ -f "DanceMachine.xcworkspace/contents.xcworkspacedata" ]; then
    echo "✅ Xcode Workspace 생성 완료"
else
    echo "⚠️  Workspace 파일을 찾을 수 없습니다. pod install이 제대로 실행되지 않았을 수 있습니다."
fi
echo ""

# 6. 프로젝트 열기
echo "🎉 모든 설정이 완료되었습니다!"
echo ""
echo "📂 Xcode Workspace를 엽니다..."
open DanceMachine.xcworkspace

echo ""
echo "✨ 설정 완료! Xcode에서 ⌘R을 눌러 앱을 실행하세요."
echo ""
echo "💡 참고:"
echo "   - 앞으로는 항상 DanceMachine.xcworkspace로 열어야 합니다."
echo "   - .xcodeproj 파일로 열지 마세요!"
echo ""
