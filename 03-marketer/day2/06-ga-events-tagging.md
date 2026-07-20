# 06. GA4 이벤트 태깅 설계

## 학습 목표

- GA4 이벤트 구조와 명명 규칙(snake_case)을 이해하고 직접 설계
- 파라미터 설계와 dataLayer JSON 구조를 Copilot으로 생성
- GTM(Google Tag Manager) 연동 개념과 태그 스니펫 생성
- E-commerce 이벤트 5개 스키마를 완성 문서로 만들기

**예상 소요**: 70~85분

---

## 6.1 GA4 이벤트란 무엇인가

GA4(Google Analytics 4)는 모든 사용자 행동을 **이벤트(Event)**로 측정합니다. Universal Analytics(이전 버전 — 지금은 지원 종료)와 달리 페이지뷰도, 전환도, 스크롤도 모두 이벤트입니다.

**이벤트 구조**

```json
{
  "event_name": "add_to_cart",
  "parameters": {
    "currency": "KRW",
    "value": 199000,
    "items": [
      {
        "item_id": "TIMEX-PRO-001",
        "item_name": "TimeX Pro 스마트워치",
        "price": 199000,
        "quantity": 1
      }
    ]
  }
}
```

이벤트는 **이름(event_name)**과 **파라미터(parameters)**로 구성됩니다. 이름으로 "무슨 행동"인지, 파라미터로 "그 행동의 세부 정보"를 담습니다.

---

## 6.2 GA4 이벤트 명명 규칙

이름을 잘못 짓는 것이 가장 흔한 실수입니다. 처음부터 규칙을 정해두지 않으면 나중에 데이터가 뒤죽박죽이 됩니다.

### 필수 규칙

| 규칙 | 올바른 예 | 잘못된 예 |
|------|-----------|-----------|
| **snake_case** (소문자 + 밑줄) | `add_to_cart` | `AddToCart`, `add-to-cart` |
| **영문자, 숫자, 밑줄만** | `view_item_list` | `장바구니담기`, `btn-click` |
| **40자 이내** | `begin_checkout` | `user_clicked_the_checkout_button_on_product_page` |
| **동사_명사 형태** | `purchase`, `sign_up` | `cart`, `checkout_button` |
| **GA4 예약어 사용 금지** | — | `app_exception`, `first_visit` 등 |

### GA4 권장 표준 이벤트 이름 (E-commerce)

GA4가 자동으로 인식하고 분석 리포트에 연결하는 표준 이벤트입니다. 가능하면 이 이름을 우선 사용하세요.

| 이벤트 이름 | 트리거 시점 |
|-------------|-------------|
| `view_item` | 상품 상세 페이지 조회 |
| `add_to_cart` | 장바구니 담기 |
| `remove_from_cart` | 장바구니에서 제거 |
| `view_cart` | 장바구니 페이지 조회 |
| `begin_checkout` | 결제 시작 |
| `add_payment_info` | 결제 수단 입력 |
| `add_shipping_info` | 배송 정보 입력 |
| `purchase` | 결제 완료 |
| `refund` | 환불 |
| `view_item_list` | 상품 목록 조회 |
| `select_item` | 상품 목록에서 클릭 |
| `sign_up` | 회원가입 |
| `login` | 로그인 |
| `search` | 검색 |

---

## 6.3 파라미터 설계 원칙

파라미터는 이벤트의 "세부 정보"입니다. GA4 표준 파라미터 이름도 따로 정해져 있어서 가능하면 표준을 따라야 GA4 분석 기능과 연동이 됩니다.

### 표준 파라미터 이름 (E-commerce)

| 파라미터 이름 | 타입 | 설명 | 예시 |
|---------------|------|------|------|
| `currency` | string | 통화 코드 (ISO 4217) | `"KRW"` |
| `value` | number | 이벤트의 금액 | `199000` |
| `transaction_id` | string | 주문 번호 | `"ORD-20260721-001"` |
| `coupon` | string | 쿠폰 코드 | `"SUMMER20"` |
| `discount` | number | 할인 금액 | `39800` |
| `shipping` | number | 배송비 | `0` |
| `tax` | number | 세금 | `0` |
| `items` | array | 상품 배열 | 아래 참고 |

**items 배열 표준 파라미터**

| 파라미터 이름 | 설명 |
|---------------|------|
| `item_id` | 상품 고유 ID |
| `item_name` | 상품 이름 |
| `item_brand` | 브랜드 |
| `item_category` | 카테고리 |
| `price` | 단가 |
| `quantity` | 수량 |
| `item_variant` | 옵션 (색상, 사이즈 등) |
| `index` | 목록에서의 순서 |
| `coupon` | 상품별 쿠폰 |
| `discount` | 상품별 할인액 |

---

## 6.4 dataLayer 구조와 GTM 연동

GA4 이벤트는 보통 **GTM(Google Tag Manager)**을 통해 측정합니다. GTM은 개발자 없이 태그를 관리할 수 있는 도구이고, `dataLayer`는 웹사이트와 GTM 사이의 데이터 통로입니다.

**데이터 흐름**

```
사용자 행동 (장바구니 담기 클릭)
    ↓
웹사이트 JavaScript가 dataLayer.push() 실행
    ↓
GTM이 dataLayer 변화를 감지
    ↓
GTM 태그가 GA4로 이벤트 전송
    ↓
GA4 리포트에 데이터 집계
```

**기본 dataLayer.push() 패턴**

```javascript
window.dataLayer = window.dataLayer || [];

dataLayer.push({
  'event': 'add_to_cart',         // GTM 트리거용 이벤트 이름
  'ecommerce': {                   // GA4 E-commerce 표준 구조
    'currency': 'KRW',
    'value': 199000,
    'items': [{
      'item_id': 'TIMEX-PRO-001',
      'item_name': 'TimeX Pro 스마트워치',
      'item_brand': 'TimeX',
      'item_category': 'wearables',
      'price': 199000,
      'quantity': 1
    }]
  }
});
```

---

## 6.5 Copilot으로 이벤트 스키마 문서 생성

### 스키마 문서 생성 프롬프트

```
E-commerce 사이트의 GA4 이벤트 스키마 문서를 Markdown으로 작성.

사이트: TimeX 스마트워치 쇼핑몰

이벤트 5개:
1. view_item (상품 상세 조회)
2. add_to_cart (장바구니 담기)
3. begin_checkout (결제 시작)
4. purchase (구매 완료)
5. sign_up (회원가입)

각 이벤트마다:
## [이벤트 이름]
- 트리거 시점
- 비즈니스 목적 (이 이벤트로 답할 수 있는 질문)
- 파라미터 표 (파라미터명 | 타입 | 필수 여부 | 예시값 | 설명)
- GTM 설정 방법 한 줄
- 주의사항 (있으면)

GA4 표준 파라미터 이름 우선 사용.
snake_case 준수.
```

---

## 6.6 Copilot으로 JavaScript 태그 스니펫 생성

### 각 이벤트별 dataLayer 코드

```
아래 5개 GA4 이벤트의 dataLayer.push() JavaScript 코드를 생성해줘.

이벤트들:
1. view_item
2. add_to_cart
3. begin_checkout
4. purchase
5. sign_up

공통 요구사항:
- window.dataLayer = window.dataLayer || []; 초기화 포함
- 모든 파라미터는 가상 데이터로 채운 예시 포함
- 동적으로 채워야 할 값은 // TODO: 실제 값으로 교체 주석 표시
- 각 스니펫 앞에 // === [이벤트명] === 구분 주석

purchase 이벤트에는 반드시:
- transaction_id, value, currency, items 배열 (2개 상품 예시)
- coupon, shipping, tax 파라미터도 포함
```

---

## 6.7 E-commerce 이벤트 5개 완성 예시

### 이벤트 1. view_item

```javascript
// === view_item: 상품 상세 페이지 조회 시 발화 ===
window.dataLayer = window.dataLayer || [];

dataLayer.push({ ecommerce: null }); // 이전 ecommerce 데이터 초기화 (중요!)
dataLayer.push({
  event: 'view_item',
  ecommerce: {
    currency: 'KRW',
    value: 199000,                    // TODO: 실제 상품 가격으로 교체
    items: [{
      item_id: 'TIMEX-PRO-001',       // TODO: 실제 상품 ID로 교체
      item_name: 'TimeX Pro 스마트워치', // TODO: 실제 상품명으로 교체
      item_brand: 'TimeX',
      item_category: 'wearables',
      item_category2: 'smartwatch',
      price: 199000,                  // TODO: 실제 가격으로 교체
      quantity: 1,
      index: 0                        // 상품 목록에서의 순서 (상세 페이지면 0)
    }]
  }
});
```

### 이벤트 2. add_to_cart

```javascript
// === add_to_cart: 장바구니 담기 버튼 클릭 시 발화 ===
dataLayer.push({ ecommerce: null });
dataLayer.push({
  event: 'add_to_cart',
  ecommerce: {
    currency: 'KRW',
    value: 199000,                    // TODO: 수량 × 단가
    items: [{
      item_id: 'TIMEX-PRO-001',       // TODO: 상품 ID
      item_name: 'TimeX Pro 스마트워치',
      item_brand: 'TimeX',
      item_category: 'wearables',
      item_variant: '블랙',            // TODO: 선택된 옵션 (색상/사이즈)
      price: 199000,
      quantity: 1                     // TODO: 선택 수량
    }]
  }
});
```

### 이벤트 3. begin_checkout

```javascript
// === begin_checkout: 결제하기 버튼 클릭 시 발화 ===
dataLayer.push({ ecommerce: null });
dataLayer.push({
  event: 'begin_checkout',
  ecommerce: {
    currency: 'KRW',
    value: 199000,                    // TODO: 장바구니 총액
    coupon: '',                       // TODO: 적용된 쿠폰 코드 (없으면 빈 문자열)
    items: [{
      item_id: 'TIMEX-PRO-001',
      item_name: 'TimeX Pro 스마트워치',
      item_brand: 'TimeX',
      item_category: 'wearables',
      price: 199000,
      quantity: 1
    }]
  }
});
```

### 이벤트 4. purchase

```javascript
// === purchase: 결제 완료 페이지 로드 시 발화 (한 번만!) ===
dataLayer.push({ ecommerce: null });
dataLayer.push({
  event: 'purchase',
  ecommerce: {
    transaction_id: 'ORD-20260721-001', // TODO: 실제 주문번호 (중복 방지 필수)
    currency: 'KRW',
    value: 199000,                      // TODO: 최종 결제 금액 (할인 후)
    coupon: 'SUMMER20',                 // TODO: 사용된 쿠폰 코드
    shipping: 0,                        // TODO: 배송비
    tax: 0,                             // TODO: 세금
    items: [
      {
        item_id: 'TIMEX-PRO-001',
        item_name: 'TimeX Pro 스마트워치',
        item_brand: 'TimeX',
        item_category: 'wearables',
        item_variant: '블랙',
        price: 199000,
        quantity: 1,
        coupon: '',
        discount: 39800                 // TODO: 상품별 할인액
      }
    ]
  }
});
```

### 이벤트 5. sign_up

```javascript
// === sign_up: 회원가입 완료 시 발화 ===
dataLayer.push({
  event: 'sign_up',
  method: 'email',                    // TODO: 가입 방식 (email/kakao/naver/google)
  // 주의: 이메일 주소 등 개인정보는 절대 파라미터에 포함 금지
});
```

---

## 6.8 자주 하는 GA4 태깅 실수

| 실수 | 결과 | 수정 방법 |
|------|------|-----------|
| ecommerce 초기화 누락 | 이전 이벤트 데이터가 현재 이벤트에 합산 | `dataLayer.push({ ecommerce: null })` 먼저 |
| purchase 이벤트 중복 발화 | 전환이 2배로 잡힘 | 주문 완료 페이지에서 1회만, 서버사이드 중복 방지 |
| item_id가 일관되지 않음 | 상품별 분석 불가 | 상품 ID 체계 먼저 확립 후 태깅 |
| 카멜케이스 이름 사용 | GA4가 별도 이벤트로 인식 | 철저한 snake_case |
| 개인정보를 파라미터에 포함 | GDPR/개인정보보호법 위반 | customer_id (익명)만 사용 |
| Universal Analytics 이벤트 구조 사용 | GA4에서 인식 안 됨 | GA4는 ecommerce 객체 구조가 다름 |

```
위 GA4 이벤트 태깅에서 자주 발생하는 오류를 찾아주는 체크리스트 작성.

개발팀에 공유할 수 있는 수준으로:
1. 코드 레벨 체크 (JavaScript 문법, dataLayer 구조)
2. 데이터 레벨 체크 (파라미터 타입, 필수값 누락)
3. 비즈니스 로직 체크 (중복 발화, 타이밍 문제)
4. 개인정보 체크 (민감 정보 파라미터 포함 여부)

Markdown 체크리스트 형식.
```

---

## 실습: E-commerce 이벤트 5개 스키마 완성

### 준비

1. VS Code에서 `ga4-events-schema.md` 파일 생성
2. `ga4-events.js` 파일 생성

### Step 1. 스키마 문서 생성 (15분)

`ga4-events-schema.md`에서 Inline Chat(`Ctrl+I`):

```
TimeX 스마트워치 E-commerce 사이트용 GA4 이벤트 스키마 문서 작성.

이벤트 5개:
1. view_item
2. add_to_cart
3. begin_checkout
4. purchase
5. sign_up

각 이벤트 섹션:
### [이벤트 이름]
**트리거**: [시점]
**목적**: [이 이벤트로 답할 수 있는 비즈니스 질문]

**파라미터 표**:
| 파라미터명 | 타입 | 필수 | 예시값 | 설명 |

**주의사항**: [있으면]

GA4 표준 E-commerce 파라미터 이름 사용. snake_case 준수.
```

### Step 2. JavaScript 스니펫 생성 (15분)

`ga4-events.js`에서 Inline Chat:

```
위 5개 GA4 이벤트의 dataLayer.push() 코드 생성.
모든 스니펫:
- ecommerce: null 초기화 포함 (purchase/cart 이벤트)
- 실제값 교체 필요한 곳은 // TODO 주석
- 각 스니펫 상단에 이벤트 설명 주석
- 개인정보 관련 주의사항 주석 포함
```

### Step 3. 검증 (10분)

```
위 ga4-events.js 파일의 dataLayer 코드를 검토해줘.

체크 항목:
1. GA4 표준 E-commerce 파라미터 이름 준수 여부
2. ecommerce: null 초기화 위치 확인
3. snake_case 이름 규칙 위반 여부
4. 개인정보(이메일, 전화번호 등) 파라미터 포함 여부
5. purchase 이벤트에 transaction_id 있는지

발견된 문제마다 수정 코드 제시.
```

### Step 4. GTM 설정 가이드 생성 (5분)

```
위 5개 이벤트를 GTM에서 설정하는 방법을 단계별로 설명해줘.

형식: 각 이벤트별로
1. GTM 트리거 설정 (어떤 조건에서 발화)
2. GTM 태그 설정 (GA4 이벤트 태그 유형)
3. 테스트 방법 (GTM 미리보기 모드)

개발팀이 없어도 마케터가 이해할 수 있는 수준으로.
```

---

## 핵심 포인트

1. **GA4는 모든 것이 이벤트** — Universal Analytics와 구조가 완전히 다름
2. **snake_case 철저히** — 대소문자, 하이픈, 한글 사용 시 별도 이벤트로 집계됨
3. **ecommerce: null 먼저** — 초기화 없으면 이전 이벤트 데이터가 합산됨
4. **purchase 중복 방지** — 주문 완료 페이지에서 1회만 발화
5. **개인정보는 파라미터에 절대 금지** — 이메일, 전화번호, 실명은 GA4 데이터에 들어가면 안 됨

---

**다음**: [07-report-automation.md](./07-report-automation.md) — 캠페인 리포트 자동화
