# SPCPointHome iOS SDK — SPM 연동 가이드

버전 **2.1.0** 기준.

## 요구사항

| | |
|---|---|
| iOS | 13.0 이상 |
| Xcode | **16.0 이상** (패키지가 `swift-tools-version: 6.0`) |
| 인증 | 불필요 — 공개 저장소 |

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

**SDK 는 광고 어댑터를 포함하지 않는다.** 필요한 매체만 직접 추가한다. 추가하지 않은 매체는 런타임 탐색에서 제외되므로, 하나도 넣지 않아도 SDK 는 정상 동작한다.

패키지를 하나 더 추가하고 필요한 product 만 앱 타깃에 체크한다.

```
https://github.com/IGAWorksDev/ap-APSSPSDK-SPM
```

| product | 매체 |
|---|---|
| `APSSPMediationNAM` | 네이버 |
| `APSSPMediationAppLovin` | AppLovin |
| `APSSPMediationVungle` | Vungle |
| `APSSPMediationPangle` | Pangle |
| `APSSPMediationAdMob` | AdMob |
| `APSSPMediationMoloco` · `APSSPMediationMintegral` · `APSSPMediationCauly` · `APSSPMediationAdFit` … | 그 외 |

버전은 `AvatyeAdCash` 가 고정한 값(`3.2.2`)을 따르므로 별도로 지정하지 않는다.

> **네이버(NAM) 네이티브 렌더링은 SDK 가 자동 처리한다.** 어댑터만 추가하면 되고 앱에서 렌더러를 조립할 필요가 없다.

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

### ③ 미디에이션 어댑터를 직접 추가

2.1.0 부터 어댑터 추가가 연동사 책임으로 바뀌었다. 이전에는 SDK 가 함께 내려받았다. 위 4번 참고.

### 그 외 2.1.0 변경사항

- `PointHomeAdLoader` 의 `logLevel` · `namConfiguration` 파라미터가 제거됐다. 둘 다 기본값이 있어 넘기지 않았다면 수정할 것이 없다. 로그 레벨은 `PointHome.setting(logLevel:)` 로 지정한다
- 광고 팝업의 닫기 버튼이 비활성이다

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
