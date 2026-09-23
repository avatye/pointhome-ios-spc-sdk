# SPCPointHome iOS SDK

현재 버전 **2.2.0**

---

## 요구사항

| | |
|---|---|
| iOS | 15.0 이상 |
| Xcode | **26.6 이상** |
| 인증 | 불필요 (공개 저장소) |

이 SDK 의 XCFramework 는 Xcode 26.6 (Swift 6.3.3) 으로 빌드되었습니다.

---

## 1. 패키지 추가

### Xcode

**File → Add Package Dependencies** 에서 아래 URL 을 입력하고, Dependency Rule 을 **Up to Next Major Version `2.2.0`** 으로 지정합니다.

```
https://github.com/avatye/pointhome-ios-spc-sdk.git
```

Add 후 `SPCPointHome` 라이브러리를 앱 타깃에 추가합니다.

### Package.swift 를 사용하는 경우

```swift
dependencies: [
    .package(url: "https://github.com/avatye/pointhome-ios-spc-sdk.git", from: "2.2.0")
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

> ⚠️ **2.1.x 를 쓰고 계셨다면 어댑터 추가 방법이 바뀌었습니다.** 기존 `ap-APSSPSDK-SPM` 패키지를 제거하고 아래대로 다시 추가해 주세요. 자세한 절차는 **5. 2.1.x 에서 올리는 경우** 를 참고하세요.

2.2.0 부터 어댑터는 **매체마다 저장소가 따로 있습니다.** 사용하는 매체의 패키지만 추가하시면 됩니다.

```
https://github.com/IGAWorksDev/ap-APSSPSDK-APSSPMediation<매체>Adapter-SPM
```

`APSSPSDK` 코어는 이 SDK 가 함께 제공하므로 **따로 추가하지 않으셔도 됩니다.** 어댑터 패키지가 코어를 의존하고 있어 버전도 자동으로 맞춰집니다.

### Xcode

1. **File → Add Package Dependencies** 에 사용할 매체의 URL 입력 (아래 표)
2. Dependency Rule 을 **Exact Version** 으로 두고 표의 버전을 입력
3. Add 후 표시되는 `APSSPMediation<매체>` 라이브러리를 앱 타깃에 추가

매체를 추가하거나 빼려면 이 과정을 매체 단위로 반복합니다.

### Package.swift 를 사용하는 경우

```swift
dependencies: [
    .package(url: "https://github.com/avatye/pointhome-ios-spc-sdk.git", from: "2.2.0"),
    // 사용하는 매체만
    .package(url: "https://github.com/IGAWorksDev/ap-APSSPSDK-APSSPMediationNAMAdapter-SPM",
             exact: "8240300.0.0"),
    .package(url: "https://github.com/IGAWorksDev/ap-APSSPSDK-APSSPMediationAppLovinAdapter-SPM",
             exact: "13060400.0.0")
]
```

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "SPCPointHome", package: "pointhome-ios-spc-sdk"),
        .product(name: "APSSPMediationNAM",
                 package: "ap-APSSPSDK-APSSPMediationNAMAdapter-SPM"),
        .product(name: "APSSPMediationAppLovin",
                 package: "ap-APSSPSDK-APSSPMediationAppLovinAdapter-SPM")
    ]
)
```

### 매체별 패키지

저장소 URL 은 `https://github.com/IGAWorksDev/` 뒤에 아래 이름을 붙이시면 됩니다.

| 매체 | 저장소 이름 | 버전 | 함께 고정되는 매체 SDK |
|---|---|---|---|
| 네이버 (NAM) | `ap-APSSPSDK-APSSPMediationNAMAdapter-SPM` | `8240300.0.0` | nam-sdk-ios 8.24.3 |
| AppLovin | `ap-APSSPSDK-APSSPMediationAppLovinAdapter-SPM` | `13060400.0.0` | AppLovin 13.6.4 |
| AppLovin MAX | `ap-APSSPSDK-APSSPMediationAppLovinMaxAdapter-SPM` | `13060400.0.0` | AppLovin 13.6.4 |
| Vungle | `ap-APSSPSDK-APSSPMediationVungleAdapter-SPM` | `7070700.0.0` | Vungle 7.7.7 |
| Pangle | `ap-APSSPSDK-APSSPMediationPangleAdapter-SPM` | `8020100.0.0` | AdsGlobalPackage 8.2.1-release.0 |
| Google (AdMob) | `ap-APSSPSDK-APSSPMediationAdMobAdapter-SPM` | `13090000.0.0` | GoogleMobileAds 13.9.0 |
| Google (GAM) | `ap-APSSPSDK-APSSPMediationGAMAdapter-SPM` | `13090000.0.0` | GoogleMobileAds 13.9.0 |
| ADOP | `ap-APSSPSDK-APSSPMediationADOPAdapter-SPM` | `13090000.0.0` | GoogleMobileAds 13.9.0 |
| AdForus | `ap-APSSPSDK-APSSPMediationAdForusAdapter-SPM` | `13090000.0.0` | GoogleMobileAds 13.9.0 |
| 카카오 AdFit | `ap-APSSPSDK-APSSPMediationAdFitAdapter-SPM` | `3212400.0.0` | adfit-spm 3.21.24 |
| Mintegral | `ap-APSSPSDK-APSSPMediationMintegralAdapter-SPM` | `8010700.0.0` | Mintegral 8.1.7 |
| Moloco | `ap-APSSPSDK-APSSPMediationMolocoAdapter-SPM` | `4100000.0.0` | moloco 4.10.0 |
| Cauly | `ap-APSSPSDK-APSSPMediationCaulyAdapter-SPM` | `3012200.0.0` | CaulySPM 3.1.22 |
| Mezzo | `ap-APSSPSDK-APSSPMediationMezzoAdapter-SPM` | `3000000.0.0` | (자체 포함) |

> 위 값은 2026-09-02 기준 최신입니다. 각 저장소의 태그 목록에서 최신 버전을 확인하실 수 있습니다.
> 지원 매체와 광고 형식(배너·네이티브·전면·보상)별 대응 여부는 [공식 문서의 지원 중인 업체 목록](https://adpopcornssp.gitbook.io/ssp-sdk/undefined-1/ap/ap-ios/ios-3.x.x)을 확인해 주세요.

### ⚠️ 버전 번호가 일반적인 형식이 아닙니다

어댑터의 버전 번호는 **그 어댑터가 대응하는 매체 SDK 버전을 인코딩한 값**입니다. `8240300.0.0` 은 NAM SDK **8.24.3** 을 뜻합니다 (`8` · `24` · `03` + 어댑터 리비전 `00`).

앞자리 전체가 semver 의 major 로 해석되기 때문에 **`Up to Next Major` 로 지정해도 사실상 한 버전만 잡힙니다.** 매체 SDK 나 어댑터 리비전이 올라가면 이 값을 직접 바꿔주셔야 합니다. 혼선을 줄이려면 **Exact Version** 으로 지정하시는 편이 명확합니다.

각 어댑터는 자신이 대응하는 매체 SDK 를 **고정(exact)** 합니다. 같은 매체 SDK 를 앱에서 직접 사용 중이시라면 위 표의 버전과 맞춰 주세요.

### SPM 으로 제공되지 않는 매체

**UnityAds · FAN(Meta) · InMobi · Fyber · Maio 는 SPM 어댑터가 없습니다.** CocoaPods 에만 있습니다.

어댑터가 없으면 빌드가 실패하는 것이 아니라 **해당 지면의 워터폴에서 그 매체가 제외**됩니다. 즉 오류 없이 노출 기회만 줄어들 수 있으니, 사용하실 매체가 위 표에 있는지 먼저 확인해 주세요.

### 선택하지 않은 매체는 내려오지도 않습니다

2.1.x 까지는 어댑터가 패키지 하나에 모여 있어, 한 매체만 쓰더라도 **모든 매체의 SDK 를 내려받고 버전 제약도 전부 적용**받았습니다. 2.2.0 부터는 추가한 패키지의 것만 해석됩니다. 해석 시간과 디스크 사용량이 크게 줄고, 사용하지 않는 매체 때문에 앱의 광고 SDK 버전이 묶이는 일도 없습니다.

`APSSPMediationNAM` 과 `APSSPMediationAppLovin` 두 개만 추가한 경우 링크되는 프레임워크는 다음과 같습니다.

```
SPCPointHome.framework          ← 이 SDK
AdCashFramework.framework       ← 함께 제공
APSSPSDK.framework              ← 함께 제공
BuzzvilSDK.framework
BuzzAdBenefitSDK.framework
AppLovinSDK.framework           ← APSSPMediationAppLovin
GFPSDK.framework                ← APSSPMediationNAM
NaverAdsServices.framework
OMSDK_Navercorp.framework
GFPSDK_*.bundle
```

> **네이버(NAM) 네이티브 렌더링은 SDK 가 자동 처리합니다.** `APSSPMediationNAM` 만 추가하시면 되고, 앱에서 렌더러를 구성하실 필요가 없습니다.

---

## 5. 2.1.x 에서 올리는 경우

**앱 코드는 변경하실 것이 없습니다.** API 가 동일합니다. 어댑터를 사용하지 않으신다면 패키지 버전만 `2.2.0` 으로 올리시면 끝입니다.

어댑터를 사용 중이시라면 두 가지를 변경해 주세요.

### ① 기존 APSSP 패키지 제거

```diff
- .package(url: "https://github.com/IGAWorksDev/ap-APSSPSDK-SPM", exact: "3.2.2")
```

```diff
  .product(name: "SPCPointHome", package: "pointhome-ios-spc-sdk"),
- .product(name: "APSSPMediationNAM", package: "ap-APSSPSDK-SPM"),
- .product(name: "APSSPMediationAppLovin", package: "ap-APSSPSDK-SPM")
```

Xcode 를 쓰신다면 **Package Dependencies 에서 `ap-APSSPSDK-SPM` 항목을 제거**합니다. 코어는 이제 SDK 가 함께 제공하므로 직접 추가하실 필요가 없습니다.

### ② 사용하는 매체의 어댑터 패키지를 각각 추가

위 **4. 미디에이션 어댑터** 를 참고해 주세요.

### 함께 개선된 것

2.1.x 까지는 SPM 으로 연동하시면 **미디에이션을 쓰지 않으셔도** 아래 매체 SDK 의 버전이 앱에 강제됐습니다.

```
GoogleMobileAds >= 13.5.0 · AppLovin >= 13.6.3 · Vungle >= 7.7.3 · Mintegral >= 8.1.1
NAM >= 8.22.1 · AdFit >= 3.21.24 · Cauly >= 3.1.22 · Moloco >= 4.5.1
AdsGlobalPackage(Pangle) == 8.1.0-release.9
```

특히 Pangle 은 단일 버전 고정이라 우회할 방법이 없었고, GoogleMobileAds 12.x 를 쓰시는 앱은 SPM 연동 자체가 불가능했습니다. **2.2.0 부터는 실제로 추가하신 어댑터의 제약만 적용됩니다.** 어댑터를 추가하지 않으시면 강제되는 버전이 하나도 없습니다.

---

## 6. CocoaPods 에서 이전

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

> **2.1.0 이후로는 SPM 으로만 제공합니다.** CocoaPods 배포는 지원하지 않습니다.

---

## License

MIT. 자세한 내용은 [LICENSE](LICENSE) 를 참고해 주세요.
