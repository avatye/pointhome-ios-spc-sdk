// swift-tools-version: 5.10
import PackageDescription

// SPCPointHome 배포 매니페스트.
//
// 소스는 비공개 저장소(avatye/secta9ine-ios-sdk)에 있고, 이 저장소는 거기서 빌드한
// XCFramework 만 담는다. 수정은 소스 저장소에서 하고 build_xcframework.sh 로 산출물을 갱신한다.
//
// binaryTarget 은 의존을 가질 수 없어서 wrapper 타깃으로 묶는다. 소비앱이 SPCPointHome
// 하나만 추가해도 AvatyeAdCash 와 Buzzvil 이 함께 링크된다.
let package = Package(
    name: "SPCPointHome",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "SPCPointHome",
            targets: ["SPCPointHomeWrapper"]
        )
    ],
    dependencies: [
        // podspec 의 `~> 4.2.0` 과 같은 의미. (4.2.0 이상, 5.0.0 미만)
        .package(url: "https://github.com/avatye-developer/sdk_adcash_ios", from: "4.2.0")
    ],
    targets: [
        .binaryTarget(
            name: "SPCPointHomeBinary",
            path: "./SPCPointHome.xcframework"
        ),
        // 소비앱이 import 하는 모듈은 XCFramework 안의 `SPCPointHome` 이다.
        // 이 wrapper 는 의존을 실어 나르기 위한 껍데기이며 소스는 더미 하나뿐이다.
        .target(
            name: "SPCPointHomeWrapper",
            dependencies: [
                "SPCPointHomeBinary",
                .product(name: "AvatyeAdCash", package: "sdk_adcash_ios"),
                "BuzzvilSDK",
                "BuzzAdBenefitSDK"
            ],
            path: "./Sources/SPCPointHomeWrapper"
        ),
        // Buzzvil 6.7.7. XCFramework 가 실제로 링크된 버전과 반드시 일치해야 한다.
        // podspec 은 `~> 6.7.5` 로 떠 있지만 이쪽은 고정이므로, 소스 저장소에서 Buzzvil 이
        // 올라가면 여기 URL·체크섬도 함께 갱신해야 한다.
        .binaryTarget(
            name: "BuzzvilSDK",
            url: "https://storage.googleapis.com/buzzvil-client-app/bab-ios/60707-114/BuzzvilSDK.zip",
            checksum: "c2ef28e3c518ce5105d07a65d22231ef76015f37ac709172403849193baac6f0"
        ),
        .binaryTarget(
            name: "BuzzAdBenefitSDK",
            url: "https://storage.googleapis.com/buzzvil-client-app/bab-ios/60707-114/BuzzAdBenefitSDK.zip",
            checksum: "318545597874b0734ed10a064217e2a8f12229df12fc3779d766160a60343299"
        )
    ]
)
