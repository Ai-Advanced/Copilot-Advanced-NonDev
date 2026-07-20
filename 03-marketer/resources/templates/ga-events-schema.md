# GA4 이벤트 스키마 문서 템플릿

> **사용 방법**: 이 템플릿을 복사해서 프로젝트별 GA4 이벤트 정의서로 사용하세요.
> 개발팀·마케팅팀 공유용으로 설계되었습니다.

---

## 문서 정보

| 항목 | 내용 |
|------|------|
| 프로젝트명 | {{project_name}} |
| 사이트 URL | {{site_url}} |
| GA4 속성 ID | {{ga4_property_id}} |
| GTM 컨테이너 ID | {{gtm_container_id}} |
| 작성자 | {{author}} |
| 최종 수정일 | {{last_updated}} |
| 버전 | v1.0 |

---

## 이벤트 명명 규칙

| 규칙 | 설명 | 올바른 예 | 잘못된 예 |
|------|------|-----------|-----------|
| snake_case | 소문자 + 밑줄 | `add_to_cart` | `AddToCart`, `add-to-cart` |
| 영문자·숫자·밑줄만 | 한글·특수문자 금지 | `begin_checkout` | `결제시작`, `begin-checkout` |
| 40자 이내 | GA4 제한 | `view_item_list` | `user_clicked_the_view_item_button` |
| 동사_명사 | 행동을 명확히 | `purchase`, `sign_up` | `cart`, `checkout_page` |
| GA4 예약어 사용 금지 | 충돌 방지 | — | `app_exception`, `first_visit` |

---

## 표준 E-commerce 이벤트

### view_item

**설명**: 사용자가 상품 상세 페이지를 조회할 때 발화

**트리거**: 상품 상세 페이지 로드 완료

**비즈니스 목적**: 상품별 조회수, 조회→장바구니 전환율 측정

| 파라미터명 | 타입 | 필수 | 예시값 | 설명 |
|------------|------|:----:|--------|------|
| `currency` | string | ✅ | `"KRW"` | ISO 4217 통화 코드 |
| `value` | number | ✅ | `199000` | 상품 가격 |
| `items` | array | ✅ | 아래 참고 | 상품 배열 |
| `items[].item_id` | string | ✅ | `"PROD-001"` | 상품 고유 ID |
| `items[].item_name` | string | ✅ | `"스마트워치 X"` | 상품명 |
| `items[].item_brand` | string | 선택 | `"TimeX"` | 브랜드명 |
| `items[].item_category` | string | 선택 | `"wearables"` | 카테고리 |
| `items[].price` | number | ✅ | `199000` | 단가 |
| `items[].quantity` | number | ✅ | `1` | 수량 |

**GTM 설정**: GA4 이벤트 태그 → 이벤트 이름 `view_item` → 이벤트 파라미터에 ecommerce 변수 매핑

---

### add_to_cart

**설명**: 사용자가 장바구니에 상품을 담을 때 발화

**트리거**: "장바구니 담기" 버튼 클릭

**비즈니스 목적**: 장바구니 추가율, 상품별 장바구니 전환율

| 파라미터명 | 타입 | 필수 | 예시값 | 설명 |
|------------|------|:----:|--------|------|
| `currency` | string | ✅ | `"KRW"` | 통화 코드 |
| `value` | number | ✅ | `199000` | 수량 × 단가 합계 |
| `items` | array | ✅ | — | 담은 상품 배열 |
| `items[].item_id` | string | ✅ | `"PROD-001"` | 상품 ID |
| `items[].item_name` | string | ✅ | `"스마트워치 X"` | 상품명 |
| `items[].item_variant` | string | 선택 | `"블랙/L"` | 선택한 옵션 |
| `items[].price` | number | ✅ | `199000` | 단가 |
| `items[].quantity` | number | ✅ | `1` | 담은 수량 |

**주의**: 옵션 선택 전에 버튼 클릭 불가하면 item_variant 항상 있음

---

### begin_checkout

**설명**: 결제 프로세스가 시작될 때 발화

**트리거**: "결제하기" 또는 "구매하기" 버튼 클릭

**비즈니스 목적**: 결제 시작율, 장바구니→결제 전환율 측정

| 파라미터명 | 타입 | 필수 | 예시값 | 설명 |
|------------|------|:----:|--------|------|
| `currency` | string | ✅ | `"KRW"` | 통화 코드 |
| `value` | number | ✅ | `199000` | 장바구니 총액 |
| `coupon` | string | 선택 | `"SUMMER20"` | 적용 쿠폰 코드 |
| `items` | array | ✅ | — | 결제 대상 상품 배열 |

---

### purchase

**설명**: 결제가 완료되고 주문이 확정될 때 발화

**트리거**: 결제 완료(주문 완료) 페이지 로드 — **반드시 1회만 발화**

**비즈니스 목적**: 실제 전환 측정, ROAS 계산의 기준

| 파라미터명 | 타입 | 필수 | 예시값 | 설명 |
|------------|------|:----:|--------|------|
| `transaction_id` | string | ✅ | `"ORD-001"` | 주문번호 (중복 방지 핵심) |
| `currency` | string | ✅ | `"KRW"` | 통화 코드 |
| `value` | number | ✅ | `159200` | 실제 결제 금액 (할인 후) |
| `coupon` | string | 선택 | `"SUMMER20"` | 사용된 쿠폰 |
| `shipping` | number | 선택 | `0` | 배송비 |
| `tax` | number | 선택 | `0` | 세금 |
| `items` | array | ✅ | — | 구매 상품 배열 |
| `items[].discount` | number | 선택 | `39800` | 상품별 할인액 |

**주의사항**:
- `transaction_id`가 같으면 GA4가 중복으로 인식 → 반드시 고유한 주문번호 사용
- 결제 완료 페이지에서 페이지 새로고침 시 중복 발화 방지 로직 필요

---

### sign_up

**설명**: 회원가입이 완료될 때 발화

**트리거**: 회원가입 완료 페이지 로드 또는 완료 API 응답 후

**비즈니스 목적**: 신규 회원 수, 가입 채널 분석

| 파라미터명 | 타입 | 필수 | 예시값 | 설명 |
|------------|------|:----:|--------|------|
| `method` | string | 선택 | `"email"` | 가입 방식 (email/kakao/naver/google) |

**개인정보 주의**: 이메일, 이름, 전화번호 등 식별 정보는 파라미터로 절대 전송 금지

---

## 커스텀 이벤트 (비즈니스 특화)

> 아래는 예시입니다. 실제 비즈니스에 맞게 추가/수정하세요.

### earlybird_cta_click

**설명**: 얼리버드 프로모션 CTA 버튼 클릭 시 발화

**트리거**: 얼리버드 배너 또는 버튼 클릭

| 파라미터명 | 타입 | 필수 | 예시값 | 설명 |
|------------|------|:----:|--------|------|
| `button_location` | string | ✅ | `"hero_banner"` | 버튼 위치 |
| `campaign_id` | string | ✅ | `"EARLY_2026_08"` | 캠페인 식별자 |
| `days_remaining` | number | 선택 | `3` | 마감까지 남은 일수 |

---

### video_play

**설명**: 제품 소개 영상 재생 시 발화

**트리거**: 영상 재생 버튼 클릭 (자동 재생 제외)

| 파라미터명 | 타입 | 필수 | 예시값 | 설명 |
|------------|------|:----:|--------|------|
| `video_title` | string | ✅ | `"TimeX Pro 소개 영상"` | 영상 제목 |
| `video_duration` | number | 선택 | `120` | 영상 전체 길이 (초) |
| `page_location` | string | 선택 | `"/product/pro"` | 재생된 페이지 경로 |

---

## GA4 예약 이벤트 이름 (사용 금지 목록)

아래 이름은 GA4가 내부적으로 사용하므로 커스텀 이벤트 이름으로 사용하면 안 됩니다.

```
ad_click           ad_exposure        ad_impression
ad_query           ad_reward
app_clear_data     app_exception      app_remove
app_store_refund   app_store_subscription_cancel
app_store_subscription_convert
app_update         dynamic_link_app_open
firebase_campaign  first_open         first_visit
in_app_purchase    notification_dismiss
notification_foreground  notification_open
notification_receive     os_update
screen_view        session_start      user_engagement
```

---

## 체크리스트 — 태깅 배포 전 검증

```
[ ] 모든 이벤트 이름: snake_case, 40자 이내
[ ] purchase 이벤트: transaction_id 있음, 중복 발화 방지 로직 있음
[ ] ecommerce: null 초기화가 ecommerce 이벤트 직전에 있음
[ ] 개인정보(email, phone, 실명) 파라미터 없음
[ ] GA4 예약 이벤트 이름 충돌 없음
[ ] GTM 미리보기 모드에서 이벤트 발화 확인
[ ] GA4 DebugView에서 파라미터 확인
[ ] currency = "KRW" (대문자 ISO 4217)
[ ] value = 숫자 타입 (문자열 아님)
[ ] items 배열: item_id, item_name, price, quantity 모두 있음
```

---

## Copilot 프롬프트 (이 문서 커스터마이즈용)

```
위 ga-events-schema.md 템플릿을 [서비스명] 에 맞게 커스터마이즈해줘.

서비스: [설명]
추가할 커스텀 이벤트: [이벤트명 + 트리거 조건]
제거할 불필요한 이벤트: [이벤트명]
비즈니스 특화 파라미터: [파라미터명 + 의미]
```
