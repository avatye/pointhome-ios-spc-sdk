#
# SPCPointHome 배포 podspec.
#
# 소스가 아니라 XCFramework 를 배포한다. 소스는 비공개 저장소(avatye/secta9ine-ios-sdk)에 있고,
# 수정은 거기서 하고 build_xcframework.sh 로 산출물을 갱신한다.
#
# 의존 버전은 XCFramework 가 실제로 링크된 것과 같아야 한다. 소스 저장소의 podspec 과
# 이 파일의 dependency 를 함께 올려야 한다.
#
Pod::Spec.new do |s|
  s.name = "SPCPointHome"
  s.version = "2.1.0"
  s.summary = "Avatye SPC PointHome SDK."

  s.description = <<-DESC
포인트홈 웹 서비스를 WKWebView 로 띄우고, 웹 브릿지를 통해 배너/네이티브/전면 광고와
버즈빌 베네핏허브를 네이티브로 노출하는 SDK. 광고는 AvatyeAdCash(내부 미디에이션 APSSP)를 쓴다.
  DESC

  s.homepage = "https://github.com/avatye/pointhome-ios-spc-sdk"
  s.license = {:type => "MIT", :file => "LICENSE"}
  s.author = {"LimJaeHyuk" => "lim0202jh@avatye.com"}
  # 태그는 접두어 없이 버전 그대로다. sdk_adcash_ios / sdk_pointhome_ios 와 같은 규칙.
  # (소스 저장소 secta9ine-ios-sdk 는 `v` 접두어를 쓰므로 혼동하지 말 것)
  s.source = {:git => "https://github.com/avatye/pointhome-ios-spc-sdk.git", :tag => s.version.to_s}

  s.ios.deployment_target = "13.0"
  s.swift_versions = ["5.0"]

  s.vendored_frameworks = "SPCPointHome.xcframework"

  s.dependency("AvatyeAdCash", "~> 4.1.0")
  s.dependency("BuzzvilSDK/BuzzvilSpecs", "~> 6.7.5")
  # NAM(네이버)은 의존으로 넣지 않는다.
  # 렌더러 조립은 SDK 내부의 NAMNativeRenderer 가 리플렉션으로 처리하므로, 연동사가
  # APSSPMediationNAM 을 넣으면 자동 활성되고 넣지 않으면 APSSP 가 NAM 을 후보에서 제외한다.
end
