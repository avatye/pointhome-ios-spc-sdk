# SPCPointHome iOS SDK

현재 버전 **2.1.1**

---

## 요구사항

| | |
|---|---|
| iOS | 13.0 이상 |
| Xcode | **26.6 이상** |
| 인증 | 불필요 (공개 저장소) |

이 SDK 의 XCFramework 는 Xcode 26.6 (Swift 6.3.3) 으로 빌드되었습니다.

---

## 1. 패키지 추가

### Xcode

**File → Add Package Dependencies** 에서 아래 URL 을 입력하고, Dependency Rule 을 **Up to Next Major Version `2.1.1`** 으로 지정합니다.

```
https://github.com/avatye/pointhome-ios-spc-sdk.git
```

Add 후 `SPCPointHome` 라이브러리를 앱 타깃에 추가합니다.

### Package.swift 를 사용하는 경우

```swift
dependencies: [
    .package(url: "https://github.com/avatye/pointhome-ios-spc-sdk.git", from: "2.1.1")
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

> `AvatyeAdCash`(광고)와 `BuzzvilSDK`(베네핏허브)는 이 패키지가 함께 제공합니다. **별도로 추가하지 않으셔도 됩니다.**

---

## 2. Info.plist 설정

### 필수 — `NSUserTrackingUsageDescription`

SDK 는 광고 식별자(IDFA)가 필요한 시점에 `ATTrackingManager.requestTrackingAuthorization` 으로 추적 권한을 요청합니다. **이 키가 없으면 권한 팝업이 표시되지 않으며** 추적 미허용 상태로 동작해 광고 매칭률이 낮아집니다.

```xml
<key>NSUserTrackingUsageDescription</key>
<string>맞춤 광고를 제공하기 위해 기기 식별자를 사용합니다.</string>
```

문구는 앱 정책에 맞게 작성해 주세요. 앱 심사에서 문구의 적절성을 확인합니다.

### 미디에이션 어댑터를 추가하는 경우

어댑터마다 요구하는 키가 다릅니다. 예를 들어 AppLovin 은 `AppLovinSdkKey`, NAM 은 `NAMSdkKey`, AdMob 은 `GADApplicationIdentifier` 를 요구합니다. **`SKAdNetworkItems` 등록도 필요합니다.**

매체별 키와 SKAdNetworkId 는 아래 문서를 참고해 주세요.

**[AdPopcorn SSP iOS 3.x.x 미디에이션 가이드](https://adpopcornssp.gitbook.io/ssp-sdk/undefined-1/ap/ap-ios/ios-3.x.x)**

---

## 3. 초기화와 사용

```swift
import SPCPointHome
```

> 모듈 이름은 `SPCPointHome`, 진입 타입은 `PointHome` 입니다.

### 초기화

앱 시작 시 한 번 호출합니다. 이후 모든 API 가 이 값을 사용합니다.

```swift
PointHome.setting(appId: "<발급받은 appId>",
                  appSecretKey: "<발급받은 appSecretKey>")
```

로그 레벨을 지정할 수 있습니다. 기본값은 `.info` 입니다.

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

연속 호출 시 중복 화면이 노출되지 않도록 SDK 내부에서 차단하며, 두 번째 호출은 실패로 응답합니다.

### 네이티브 광고 로더

```swift
final class MyViewController: UIViewController, PHAdLoaderDelegate {
    private var loader: PointHomeAdLoader?

    func loadAd(placementId: String) {
        let loader = PointHomeAdLoader(rootVC: self,
                                      placementId: placementId,
                                      width: view.bounds.width)
        loader.delegate = self
        self.loader = loader          // delegate 가 weak 이므로 로더 보관이 필요합니다.
        loader.requestAd()
    }

    // 모든 콜백은 메인 스레드로 전달됩니다.
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

**SDK 는 광고 어댑터를 포함하지 않습니다.** 필요한 매체만 선택해 추가해 주세요. 추가하지 않은 매체는 런타임 탐색에서 제외되므로, 어댑터를 하나도 추가하지 않아도 SDK 는 정상 동작합니다.

> ### 📖 미디에이션 공식 문서
>
> **[AdPopcorn SSP iOS 3.x.x 미디에이션 가이드](https://adpopcornssp.gitbook.io/ssp-sdk/undefined-1/ap/ap-ios/ios-3.x.x)**
>
> 지원 매체 목록, SPM 지원 현황, **매체별 상세 설정**, 네이티브 광고 미디에이션, **SKAdNetworkId 등록**을 다룹니다. 아래는 이 SDK 에서 SPM 으로 연동하는 방법만 정리한 것이므로, 매체별 설정은 위 문서를 확인해 주세요.

어댑터는 `ap-APSSPSDK-SPM` 패키지에 product 단위로 제공됩니다. **패키지를 추가한 뒤 필요한 product 만 앱 타깃에 추가**하시면 됩니다.

```
https://github.com/IGAWorksDev/ap-APSSPSDK-SPM
```

### Xcode

1. **File → Add Package Dependencies** 에 위 URL 입력
2. Dependency Rule 을 **Exact Version `3.2.2`** 로 지정
3. Add 후 표시되는 product 목록에서 **필요한 `APSSPMediation*` 만 선택** (앱 타깃 지정)

추가 후 매체를 변경하려면 앱 타깃의 **General → Frameworks, Libraries, and Embedded Content** 에서 추가·제거합니다.

### Package.swift 를 사용하는 경우

```swift
dependencies: [
    .package(url: "https://github.com/avatye/pointhome-ios-spc-sdk.git", from: "2.1.1"),
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

### APSSPSDK 버전은 `3.2.2` 로 지정합니다

`AvatyeAdCash` 가 APSSPSDK 를 `exact: "3.2.2"` 로 고정하고 있습니다. 다른 버전을 지정하면 **의존성 해석이 실패합니다.** Dependency Rule 은 **Exact Version `3.2.2`** 로 지정해 주세요.

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

위 표는 SPM product 이름 확인용입니다. 지원 매체와 광고 형식(배너·네이티브·전면·보상)별 대응 여부는 [공식 문서의 지원 중인 업체 목록](https://adpopcornssp.gitbook.io/ssp-sdk/undefined-1/ap/ap-ios/ios-3.x.x)을 확인해 주세요.

### 선택하지 않은 매체는 앱에 포함되지 않습니다

SPM 은 의존성 해석 단계에서 그래프 전체의 바이너리를 내려받습니다. 따라서 선택하지 않은 매체의 SDK 도 **디스크에는 내려오지만, 링크되지 않으므로 앱 바이너리에는 포함되지 않습니다.** 앱 용량과는 무관하며 해석 시간과 디스크만 사용합니다.

`APSSPMediationNAM` 과 `APSSPMediationAppLovin` 두 개만 선택한 경우 링크되는 프레임워크는 다음과 같습니다.

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

Vungle · Pangle · Moloco · Mintegral · Google · Cauly · AdFit 은 내려오기만 하고 링크되지 않습니다.

> **네이버(NAM) 네이티브 렌더링은 SDK 가 자동 처리합니다.** `APSSPMediationNAM` 만 추가하시면 되고, 앱에서 렌더러를 구성하실 필요가 없습니다.

---

## 5. CocoaPods 에서 이전

기존 `pod 'PointHome'` 2.0.x 를 사용하고 계셨다면 세 가지를 변경해 주세요.

### ① Podfile 에서 제거

```diff
- pod 'PointHome', '~> 2.0'
```

`pod install` 로 정리한 뒤 위 1번대로 SPM 패키지를 추가합니다.

### ② import 치환

```diff
- import PointHome
+ import SPCPointHome
```

**호출부는 변경하지 않으셔도 됩니다.** `PointHome.setting`, `PointHome.openService`, `PointHomeAdLoader` 모두 이름이 동일합니다.

패키지·모듈 이름을 `PointHome` 에서 `SPCPointHome` 으로 변경한 것은 별도 제품인 `AvatyePointHome` 과 구분하기 위한 것입니다.

### ③ 미디에이션 어댑터 추가

2.1.0 부터 어댑터 추가가 연동사 측 작업으로 변경되었습니다. 이전에는 SDK 가 함께 제공했습니다. 위 4번을 참고해 주세요.

### 그 외 2.1.x 변경사항

- `PointHomeAdLoader` 의 `logLevel` · `namConfiguration` 파라미터가 제거되었습니다. 두 파라미터 모두 기본값이 있어 전달하지 않으셨다면 변경할 사항이 없습니다. 로그 레벨은 `PointHome.setting(logLevel:)` 로 지정합니다
- 광고 팝업의 닫기 버튼이 비활성화되었습니다

> **2.1.x 는 SPM 으로만 제공합니다.** CocoaPods 배포는 지원하지 않습니다.

---

## License

MIT. 자세한 내용은 [LICENSE](LICENSE) 를 참고해 주세요.
