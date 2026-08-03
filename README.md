# SPCPointHome iOS SDK

포인트홈 웹 서비스를 `WKWebView` 로 띄우고, 웹 브릿지를 통해 배너·네이티브·전면 광고와 버즈빌 베네핏허브를 네이티브로 노출한다. 광고는 AvatyeAdCash(내부 미디에이션 APSSP)를 사용한다.

**Swift Package Manager 로 배포한다.** 이 저장소는 빌드 산출물(`SPCPointHome.xcframework`)만 담는 배포 저장소이며, 소스는 비공개 저장소 `avatye/secta9ine-ios-sdk` 에 있다. 여기에 직접 코드를 커밋하지 않는다.

현재 버전 **2.1.0**

---

## 요구사항

| | |
|---|---|
| iOS | 13.0 이상 |
| Xcode | **26.6 에서 빌드·검증됨.** 하위 버전은 미검증 — 아래 참고 |
| 인증 | 불필요 — 공개 저장소 |

### Xcode 버전에 대해

XCFramework 는 **Xcode 26.6 (Swift 6.3.3)** 으로 빌드했고 같은 버전에서 해석·빌드를 확인했다.

`.swiftinterface` 는 같거나 더 새로운 컴파일러가 읽는 것을 전제로 한다. 따라서 **더 낮은 Xcode 에서는 모듈 임포트가 실패할 수 있다** — `failed to build module 'SPCPointHome'` 형태로 나타난다. 하위 버전은 실측하지 않았다.

사용하는 Xcode 버전을 알려주면 확인한다. 필요하면 해당 버전으로 다시 빌드해 배포할 수 있다.

> 패키지 매니페스트 자체는 `swift-tools-version: 5.10` 이라 SwiftPM 요구사항은 낮다. 위 제약은 매니페스트가 아니라 **바이너리를 만든 컴파일러** 때문이다.

---

## 1. 패키지 추가

### Xcode

**File → Add Package Dependencies** 에서 아래 URL 을 입력하고, Dependency Rule 을 **Up to Next Major Version `2.1.0`** 으로 둔다.

```
https://github.com/avatye/pointhome-ios-spc-sdk.git
```

Add 후 `SPCPointHome` 라이브러리를 앱 타깃에 체크한다.

### Package.swift 를 쓰는 경우

```swift
dependencies: [
    .package(url: "https://github.com/avatye/pointhome-ios-spc-sdk.git", from: "2.1.0")
]
```

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "SPCPointHome", package: "pointhome-ios-spc-sdk")
    ]
)
```

> `AvatyeAdCash`(광고)와 `BuzzvilSDK`(베네핏허브)는 이 패키지가 함께 가져온다. **따로 추가하지 않는다.**

---

## 2. Info.plist 설정

### 필수 — `NSUserTrackingUsageDescription`

SDK 는 광고 식별자(IDFA)가 필요할 때 `ATTrackingManager.requestTrackingAuthorization` 으로 추적 권한을 요청한다. **이 키가 없으면 권한 팝업이 표시되지 않고** 추적 미허용 상태로 동작한다(광고 매칭률이 떨어진다).

```xml
<key>NSUserTrackingUsageDescription</key>
<string>맞춤 광고를 제공하기 위해 기기 식별자를 사용합니다.</string>
```

문구는 앱 정책에 맞게 작성한다. 심사에서 문구 적절성을 본다.

### 불필요 — ATS 우회

SDK 의 모든 엔드포인트가 **HTTPS** 다. `NSAppTransportSecurity` / `NSAllowsArbitraryLoads` 를 넣을 필요가 없다.

> 아바티 테스트 앱의 `Info.plist` 에 `NSAllowsArbitraryLoads = true` 가 있으나 이는 사내 개발 서버 접속용이다. **그대로 복사하지 말 것.** 불필요한 ATS 우회는 심사에서 사유를 요구받는다.

### 미디에이션 어댑터를 추가하는 경우

어댑터마다 요구하는 키가 다르다. 각 어댑터 문서를 따른다. 예를 들어 AppLovin 은 `AppLovinSdkKey`, NAM 은 `NAMSdkKey`, AdMob 은 `GADApplicationIdentifier` 를 요구한다.

---

## 3. 초기화와 사용

```swift
import SPCPointHome
```

> 모듈 이름은 `SPCPointHome`, 진입 타입은 `PointHome` 이다. 서로 다르다.

### 초기화

앱 시작 시 한 번 호출한다. 이후 API 는 이 값을 사용한다.

```swift
PointHome.setting(appId: "<발급받은 appId>",
                  appSecretKey: "<발급받은 appSecretKey>")
```

로그 레벨을 조정할 수 있다. 기본값은 `.info` 다.

```swift
PointHome.setting(appId: "...", appSecretKey: "...", logLevel: .debug)
```

### 포인트홈 화면 열기

```swift
PointHome.openService(rootVC: self, userKey: "<사용자 식별자>") { result in
    switch result {
    case .success(let message):
        print("열기 성공: \(message)")
    case .failure(let error):
        print("열기 실패: \(error.message)")
    }
}
```

연속 호출 시 중복 화면이 뜨지 않도록 SDK 내부에서 막고, 두 번째 호출은 실패로 응답한다.

### 피드 조회

```swift
let param = PHFeedParamModel(/* ... */)
PointHome.getFeed(userKey: "<사용자 식별자>", param: param) { result in
    switch result {
    case .success(let response): // PointHomeFeedResponseModel
        break
    case .failure(let error):
        break
    }
}
```

### 네이티브 광고 로더

```swift
final class MyViewController: UIViewController, PHAdLoaderDelegate {
    private var loader: PointHomeAdLoader?

    func loadAd(placementId: String) {
        let loader = PointHomeAdLoader(rootVC: self,
                                      placementId: placementId,
                                      width: view.bounds.width)
        loader.delegate = self
        self.loader = loader          // 로더를 강하게 보관해야 한다 (delegate 는 weak)
        loader.requestAd()
    }

    // 모든 콜백은 메인 스레드로 전달된다. UI 를 바로 다뤄도 된다.
    func onBannerLoaded(_ apid: String, adView: UIView, size: CGSize) { }
    func onBannerFailed(_ apid: String, error: PointHomeError) { }
    func onBannerClicked(_ apid: String) { }
    func onBannerRemoved(_ apid: String) { }

    deinit {
        loader?.stopAd()
        loader?.release()
    }
}
```

---

## 4. 미디에이션 어댑터 (선택)

**SDK 는 광고 어댑터를 포함하지 않는다.** 필요한 매체만 직접 고른다. 추가하지 않은 매체는 런타임 탐색에서 제외되므로, 하나도 넣지 않아도 SDK 는 정상 동작한다.

어댑터는 `ap-APSSPSDK-SPM` 패키지에 product 단위로 들어 있다. **패키지를 추가한 뒤 원하는 product 만 앱 타깃에 링크**하면 된다.

```
https://github.com/IGAWorksDev/ap-APSSPSDK-SPM
```

### Xcode

1. **File → Add Package Dependencies** 에 위 URL 입력
2. Dependency Rule 을 **Exact Version `3.2.2`** 로 지정
3. Add 후 나오는 product 목록에서 **필요한 `APSSPMediation*` 만 체크** (앱 타깃에 지정)

이미 추가한 뒤 매체를 바꾸려면 앱 타깃의 **General → Frameworks, Libraries, and Embedded Content** 에서 추가·제거한다.

### Package.swift 를 쓰는 경우

```swift
dependencies: [
    .package(url: "https://github.com/avatye/pointhome-ios-spc-sdk.git", from: "2.1.0"),
    .package(url: "https://github.com/IGAWorksDev/ap-APSSPSDK-SPM", exact: "3.2.2")
]
```

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "SPCPointHome", package: "pointhome-ios-spc-sdk"),
        // 필요한 매체만
        .product(name: "APSSPMediationNAM", package: "ap-APSSPSDK-SPM"),
        .product(name: "APSSPMediationAppLovin", package: "ap-APSSPSDK-SPM")
    ]
)
```

### 선택 가능한 product

| product | 매체 |
|---|---|
| `APSSPMediationNAM` | 네이버 |
| `APSSPMediationAppLovin` · `APSSPMediationAppLovinMax` | AppLovin |
| `APSSPMediationVungle` | Vungle |
| `APSSPMediationPangle` | Pangle |
| `APSSPMediationAdMob` · `APSSPMediationGAM` · `APSSPMediationADOP` | Google |
| `APSSPMediationMoloco` | Moloco |
| `APSSPMediationMintegral` | Mintegral |
| `APSSPMediationCauly` | Cauly |
| `APSSPMediationAdFit` | 카카오 AdFit |
| `APSSPMediationMezzo` · `APSSPMediationAdForus` | 그 외 |

### 버전은 `3.2.2` 로 고정해야 한다

`AvatyeAdCash` 가 APSSPSDK 를 `exact: "3.2.2"` 로 못박고 있다. 다른 버전을 지정하면 **의존성 해석이 실패**한다. `Exact Version 3.2.2` 로 두는 것이 안전하다.

### 고르지 않은 매체는 앱에 포함되지 않는다

SPM 은 의존성 해석 단계에서 그래프 전체의 바이너리를 내려받는다. 그래서 고르지 않은 매체의 SDK 도 **디스크에 내려오지만, 링크되지 않으므로 앱 바이너리에는 들어가지 않는다.** 앱 용량과는 무관하고 해석 시간·디스크만 쓴다(→ 6번 CI 캐시 참고).

`APSSPMediationNAM` + `APSSPMediationAppLovin` 두 개만 고른 경우 실제로 링크되는 것은 다음과 같다.

```
SPCPointHome.framework          ← 이 SDK
AdCashFramework.framework       ← 함께 제공
APSSPSDK.framework
BuzzvilSDK.framework
BuzzAdBenefitSDK.framework
AppLovinSDK.framework           ← APSSPMediationAppLovin
GFPSDK.framework                ← APSSPMediationNAM
NaverAdsServices.framework
OMSDK_Navercorp.framework
GFPSDK_*.bundle
```

Vungle · Pangle · Moloco · Mintegral · Google · Cauly · AdFit 은 내려오기만 하고 링크되지 않는다.

> **네이버(NAM) 네이티브 렌더링은 SDK 가 자동 처리한다.** `APSSPMediationNAM` 만 추가하면 되고 앱에서 렌더러를 조립할 필요가 없다.

---

## 5. CocoaPods 에서 이전

기존 `pod 'PointHome'` 2.0.x 를 쓰고 있었다면 세 가지를 바꾼다.

### ① Podfile 에서 제거

```diff
- pod 'PointHome', '~> 2.0'
```

`pod install` 로 정리한 뒤 위 1번대로 SPM 패키지를 추가한다.

### ② import 치환

```diff
- import PointHome
+ import SPCPointHome
```

**호출부는 바꾸지 않는다.** `PointHome.setting`, `PointHome.openService`, `PointHomeAdLoader` 모두 이름이 그대로다.

패키지·모듈 이름이 `PointHome` 에서 `SPCPointHome` 으로 바뀐 것은 별도 제품인 `AvatyePointHome` 과 구분하기 위한 변경이다.

### ③ 미디에이션 어댑터를 직접 추가

2.1.0 부터 어댑터 추가가 연동사 책임으로 바뀌었다. 이전에는 SDK 가 함께 내려받았다. 위 4번 참고.

### 그 외 2.1.0 변경사항

- `PointHomeAdLoader` 의 `logLevel` · `namConfiguration` 파라미터가 제거됐다. 둘 다 기본값이 있어 넘기지 않았다면 수정할 것이 없다. 로그 레벨은 `PointHome.setting(logLevel:)` 로 지정한다
- 광고 팝업의 닫기 버튼이 비활성이다

> **2.1.0 은 CocoaPods 로 배포하지 않는다.** SPM 만 지원한다.

---

## 6. CI 설정 — **SPM 캐시를 반드시 캐싱할 것**

이 SDK 는 광고 미디에이션 SDK 들을 의존 그래프에 포함한다. 캐시가 없는 상태에서 해석하면 **약 1.3GB** 를 내려받는다(실제로 링크되는 것은 일부지만 SPM 이 그래프 전체의 바이너리를 받는다).

개발자 머신은 최초 1회지만 **CI 는 캐시를 설정하지 않으면 매 빌드마다** 이 비용을 낸다.

캐시할 경로:

```
~/Library/Caches/org.swift.swiftpm
```

Xcode 빌드라면 `-clonedSourcePackagesDirPath` 로 체크아웃 위치를 지정해 그 디렉터리를 함께 캐싱하는 방법도 있다.

```bash
xcodebuild -clonedSourcePackagesDirPath .spm-checkouts ...
```

`Package.resolved` 를 저장소에 커밋해 두면 해석 결과가 고정되어 빌드 재현성이 올라간다.

---

## 문의

연동 중 문제가 생기면 아래를 함께 전달하면 진단이 빠르다.

- Xcode 버전, iOS 버전, 기기/시뮬레이터 구분
- `PointHome.setting(logLevel: .debug)` 로 설정한 뒤의 콘솔 로그
- `Package.resolved` 의 `pointhome-ios-spc-sdk` 항목

## License

MIT. 자세한 내용은 [LICENSE](LICENSE) 참고.
