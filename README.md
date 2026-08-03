# pointhome-ios-spc-sdk

**SPCPointHome iOS SDK 배포 저장소.** 빌드 산출물(`SPCPointHome.xcframework`)만 담는다.

소스는 비공개 저장소 `avatye/secta9ine-ios-sdk` 에 있다. **이 저장소에 직접 코드를 커밋하지 않는다.** 수정은 소스 저장소에서 하고 `build_xcframework.sh` 로 산출물을 갱신한다.

포인트홈 웹 서비스를 `WKWebView` 로 띄우고, 웹 브릿지를 통해 배너·네이티브·전면 광고와 버즈빌 베네핏허브를 네이티브로 노출한다. 광고는 AvatyeAdCash(내부 미디에이션 APSSP)를 사용한다.

## Requirements

| | |
|---|---|
| iOS | 13.0 이상 |
| Xcode | CocoaPods 는 제한 없음 / **SPM 은 16 이상** |

## Installation

두 채널 모두 모듈 이름은 `SPCPointHome` 으로 같다. 채널을 바꿔도 코드는 그대로다.

```swift
import SPCPointHome
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/avatye/pointhome-ios-spc-sdk.git", from: "2.1.0")
]
```

Xcode 는 **File > Add Package Dependencies** 에서 위 URL 을 입력한다. 공개 저장소라 별도 인증이 필요 없다.

`AvatyeAdCash` 와 Buzzvil 은 이 패키지가 함께 가져오므로 따로 추가하지 않아도 된다.

### CocoaPods

```ruby
source 'https://github.com/CocoaPods/Specs.git'
source 'https://dl.cloudsmith.io/public/avatye/ios-sdk/cocoapods/index.git'

platform :ios, '13.0'
use_frameworks! :linkage => :static

target 'YourApp' do
  pod 'SPCPointHome', '~> 2.1'
end
```

## 미디에이션 어댑터

SDK 는 광고 어댑터를 의존으로 포함하지 않는다. **필요한 매체만 연동사가 직접 추가한다.** 추가하지 않은 매체는 APSSP 가 런타임 탐색에서 제외하므로, 하나도 넣지 않아도 동작한다.

CocoaPods (어댑터는 CocoaPods 트렁크에 있다):

```ruby
pod 'APSSPMediationNAM'
pod 'APSSPMediationAppLovin'
pod 'APSSPMediationVungle'
pod 'APSSPMediationUnityAds'
pod 'APSSPMediationPangle'
```

SPM 은 [`ap-APSSPSDK-SPM`](https://github.com/IGAWorksDev/ap-APSSPSDK-SPM) 패키지를 추가하고 필요한 `APSSPMediation*` product 를 선택한다. 버전은 AvatyeAdCash 가 고정한 값을 따른다.

## Usage

```swift
import SPCPointHome

PointHome.setting(appId: "...", appSecretKey: "...")

PointHome.openService(rootVC: self, userKey: "...") { result in
    // ...
}
```

진입 타입은 `PointHome` 이다. 모듈 이름과 다르다.

## Migration

### 2.0.x → 2.1.0

**1. 패키지 이름** — `PointHome` 에서 `SPCPointHome` 으로 바뀌었다. 별도 제품인 `AvatyePointHome` 과 구분하기 위한 변경이다.

```diff
- pod 'PointHome', '~> 2.0'
+ pod 'SPCPointHome', '~> 2.1'
```

**2. import 치환** — 호출부(`PointHome.setting`, `PointHome.openService` 등)는 바꾸지 않는다.

```diff
- import PointHome
+ import SPCPointHome
```

**3. 미디에이션 어댑터를 직접 추가** — 2.1.0 부터 어댑터 추가가 연동사 책임으로 바뀌었다. 이전에는 SDK 가 함께 내려받았다.

### CocoaPods → SPM

좌표만 교체하면 된다. 모듈 이름이 같으므로 **코드 변경은 없다.**

## License

MIT. 자세한 내용은 [LICENSE](LICENSE) 참고.
