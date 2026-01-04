// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DancePoseAnalysis",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "DancePoseAnalysis",
            targets: ["DancePoseAnalysis"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/google-gemini/generative-ai-swift",
            from: "0.5.6"
        )
    ],
    targets: [
        .target(
            name: "DancePoseAnalysis",
            dependencies: [
                .product(name: "GoogleGenerativeAI", package: "generative-ai-swift")
            ]
        ),
        .testTarget(
            name: "DancePoseAnalysisTests",
            dependencies: ["DancePoseAnalysis"]
        ),
    ]
)
