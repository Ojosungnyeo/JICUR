# JICUR

TCA 기반의 산책 지도 프로토타입입니다. API 키가 없으면 앱 자체의 일러스트 프리뷰 지도를, 키가 있으면 스타일을 적용한 Google 지도를 표시합니다.

## Google Maps 인증

1. Google Cloud 프로젝트에 결제 계정을 연결합니다.
2. **Maps SDK for iOS**, **Places API (New)**, **Routes API**를 활성화하고 API 키를 만듭니다.
3. 키의 애플리케이션 제한을 **iOS 앱**으로 지정하고 Bundle ID `sun.JICUR`를 등록합니다.
4. Xcode에서 JICUR Target → Build Settings → `GOOGLE_MAPS_API_KEY`를 찾아 `YOUR_API_KEY`를 실제 키로 교체합니다.

키를 소스 코드에 직접 넣지 않고, 배포 환경에서는 `.xcconfig` 또는 CI secret으로 주입하는 방식을 권장합니다.

현재 프로토타입은 검색과 경로 REST 요청에도 iOS 키와 `X-Ios-Bundle-Identifier`를 사용합니다. 운영 앱에서는 지도 SDK 키와 웹 서비스 키를 분리하고, Routes API 호출은 인증된 백엔드 프록시를 거치면 키 노출 위험을 더 줄일 수 있습니다.

## 구조

- `MapFeature.swift`: 지도 화면의 TCA 상태·액션·리듀서
- `MapDomain.swift`: SDK를 모르는 좌표·장소·경로 모델
- `GoogleMapsClient.swift`: SDK 초기화와 인증 상태를 감싼 TCA dependency
- `PlacesClient.swift`: Places API (New) 텍스트 검색 dependency
- `RoutesClient.swift`: Routes API 도보 동선 dependency
- `JicurMapView.swift`: Google Maps 렌더링 어댑터
- `IllustratedMapView.swift`: 인증 전에도 확인 가능한 SwiftUI 지도 프리뷰
