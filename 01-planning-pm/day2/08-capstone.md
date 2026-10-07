# 08. 캡스톤 프로젝트 — "사내 도서 추천 서비스" 신규 기획 A~Z

**완성 후 Azure로:** 아래 산출물 검증을 마치면 [공통 배포 캡스톤](../../09-azure-capstone/README.md)에서 프로토타입을 웹에 게시합니다. [직군별 요구사항·프롬프트](../../09-azure-capstone/roles.md)를 사용하며, 아래 예상 시간과 별도 편성입니다.

## 학습 목표

- Day 1~2에서 배운 모든 기술을 하나의 실제 기획 흐름에 통합 적용한다
- PRD → 사용자 스토리 → 와이어프레임 → API 명세 이해 → PR 리뷰 → 회의록 → 스프린트 티켓까지 end-to-end를 경험한다
- Copilot 없이는 하루 이상 걸릴 산출물을 80분 안에 완성하는 감각을 체득한다

**예상 소요**: 80분 (실습 70분 + 리뷰 10분)

---

## 프로젝트 배경

**회사**: 가상의 테크 회사 "테코(Teco)" — 직원 약 200명

**문제**: 사내 도서관에 700권의 책이 있는데, 어떤 책이 있는지 모르는 직원이 80%. 인사팀이 월 1회 뉴스레터로 추천 도서를 공유하지만 클릭율이 3%에 불과.

**제안**: 직원들이 읽은 책을 기록하고, 동료의 추천을 볼 수 있는 사내 웹 서비스 구축.

**PM 역할**: 여러분이 이 서비스의 PM입니다. 오늘 신규 기획 문서 세트를 완성해야 합니다.

---

## 캡스톤 산출물 목록

```
teco-books/
├── prd.md                          # 전체 서비스 PRD
├── user-stories.md                 # 사용자 스토리 15개 + 인수 조건
├── wireframe-description.md        # 와이어프레임 텍스트 명세
├── prototype.html                  # 3화면 HTML 프로토타입
├── api-spec-review.md              # API 명세 이해 노트
├── sprint-planning/
│   ├── meeting-notes.md            # 킥오프 회의록
│   └── sprint-1-tickets.md        # Sprint 1 JIRA 티켓 8개
└── stakeholder-summary.md         # 임원 보고용 1페이지 요약
```

---

## Step 1. PRD 작성 (15분)

### 폴더 및 파일 준비

`teco-books` 폴더를 만들고 `.github/copilot-instructions.md`를 설정하세요.

```markdown
# Teco Books 기획 작업 공간

## 서비스 개요
사내 도서 추천 서비스 "TecoBooks"
- 사용자: 테코 직원 200명
- 플랫폼: 웹 (React, 모바일 반응형)
- 백엔드: REST API
- DB: 도서 정보, 사용자 독서 기록, 추천/리뷰

## PRD 규칙
- 성공 지표는 수치로 명시
- 스코프 In/Out 모두 작성
- 리스크 항목에 발생가능성/영향도/대응방안 포함

## 용어 정의
- "사용자" = 테코 임직원
- "관리자" = 인사팀 또는 도서 담당자
- "리뷰" = 별점 + 코멘트
- "추천" = 동료에게 이 책 읽어보라는 액션
```

### PRD 생성 프롬프트

`prd.md` 파일을 만들고 다음 프롬프트를 실행하세요:

```
테코(Teco) 사내 도서 추천 서비스 "TecoBooks"의 PRD를 Markdown으로 작성해줘.

서비스 배경:
- 사내 도서관 700권 보유, 활용률 낮음
- 현재 월 1회 뉴스레터 추천, 클릭율 3%
- 슬랙에서 비공식적으로 "이 책 좋아요" 공유는 있지만 검색 불가
- 직원 200명, 연령대 25~40세, 기술직 + 비기술직 혼합

서비스 목적:
- 사내 도서 검색 및 대출 현황 확인
- 읽은 책 기록 + 별점/리뷰 작성
- 동료 추천 피드 (누가 어떤 책을 읽었는지)
- 팀/부서별 추천 도서 리스트

다음 섹션 포함:
1. 배경 및 문제 정의 (데이터 포함, 가상 수치)
2. 목표 및 성공 지표 (Primary 1개, Secondary 2개, Guardrail 1개)
3. 사용자 페르소나 (2개: 기술직 개발자 / 비기술직 HR담당자)
4. 사용자 스토리 (5개 핵심 스토리)
5. 기능 명세 (MVP 기준 12개 항목, 우선순위 포함)
6. 비기능 요구사항 (성능/보안/접근성 각 2개)
7. 스코프 (In-Scope 6개, Out-of-Scope 4개)
8. 리스크 (4개)
9. 마일스톤 (MVP 기준 3단계)
```

PRD 생성 후 반드시 검토하세요:
- 성공 지표가 측정 가능한가?
- 두 페르소나가 서로 다른 니즈를 가지고 있는가?
- Out-of-Scope가 현실적인가?

---

## Step 2. 사용자 스토리 작성 (10분)

`user-stories.md` 파일을 만들고:

```
TecoBooks 서비스의 사용자 스토리를 작성해줘.

사용자 유형:
- 일반 직원 (독자)
- 관리자 (인사팀/도서 담당자)

카테고리:
1. 도서 검색 및 상세 조회 — 3개
2. 독서 기록 및 리뷰 — 3개
3. 동료 추천 피드 — 3개
4. 대출/반납 — 3개
5. 관리자 기능 (도서 등록/수정/재고 관리) — 3개

형식:
### ST-[번호]: [스토리 제목]
**As a** [사용자 유형],
**I want to** [행동],
**so that** [가치].

**인수 조건**:
- Given [상태] / When [행동] / Then [결과]
- [두 번째 조건]

INVEST 원칙 위반 여부도 각 스토리 아래에 표시.
```

---

## Step 3. 와이어프레임 텍스트 명세 (10분)

`wireframe-description.md` 파일을 만들고:

```
TecoBooks의 핵심 화면 4개를 와이어프레임 텍스트 명세로 작성해줘.

각 화면에 대해:
- 화면 이름 및 URL
- 화면 목적 (1문장)
- 레이아웃 구조 (상/중/하 또는 좌/우)
- 각 UI 컴포넌트 목록 + 역할
- 인터랙션 설명 (버튼/링크 클릭 시 어떤 변화)
- 데이터 의존성 (어떤 API 필요)
- 빈 상태(Empty State) 처리

화면 목록:
1. 홈 피드 (동료 최근 독서 활동)
2. 도서 검색 결과
3. 도서 상세 (리뷰 + 추천 + 대출 상태)
4. 내 독서 기록

텍스트 기반 ASCII 레이아웃 다이어그램도 각 화면마다 포함.
```

---

## Step 4. HTML 프로토타입 (15분)

`prototype.html` 파일을 만들고 3화면 프로토타입을 생성하세요.

**화면 구성**:

```
화면 1: 홈 피드
  - 상단: 검색바 + "TecoBooks" 로고
  - 중간: 동료 활동 피드 (카드형, 3개)
    각 카드: 프로필 이미지 자리(이니셜) + 이름 + "이 책을 읽었어요" + 책 제목 + 별점
  - 하단: 탭바 (홈/검색/내 기록/프로필)

화면 2: 도서 상세
  - 상단: 뒤로가기 + 책 제목
  - 표지 이미지 자리 (배경색 블록)
  - 책 정보: 저자, 출판사, 분야
  - 대출 상태: "대출 가능 (2권 중 1권)" + 대출 신청 버튼
  - 별점 평균 + 리뷰 수
  - 리뷰 목록 (2개 예시)
  - 동료 추천 섹션 (누가 추천했는지)

화면 3: 내 독서 기록
  - 상단: "내 독서 기록" 제목
  - 통계 카드: 올해 읽은 책 수, 총 리뷰 수
  - 읽은 책 목록 (3개, 날짜 + 별점 포함)
  - + 기록 추가 버튼
```

프롬프트:

```
TecoBooks 사내 도서 추천 서비스의 HTML 프로토타입을 만들어줘.

위의 3화면 구성으로:
- 단일 HTML 파일 (CSS 포함)
- 모바일 390px 중앙 정렬
- 화면 전환: showScreen 함수
- 메인 컬러: #0EA5E9 (하늘색)
- 한국어 플레이스홀더 (실제 책 제목 사용: "그릿", "아토믹 해빗", "클린 코드")
- 상단에 "⚠️ 기획 목적 프로토타입" 배너

화면 1 → 카드 클릭 → 화면 2
화면 2 → 뒤로가기 → 화면 1
화면 3 → 하단 탭 "내 기록" 클릭으로 접근
```

---

## Step 5. API 명세 이해 (10분)

다음 TecoBooks의 가상 API 명세를 Chat에 붙이고 PM 관점 설명을 받으세요.

`api-spec-review.md` 파일에 이해한 내용을 정리하세요.

```yaml
openapi: 3.0.0
paths:
  /books:
    get:
      summary: 도서 목록 조회 및 검색
      parameters:
        - name: q
          in: query
          description: 제목/저자 검색어
          schema:
            type: string
        - name: available
          in: query
          description: true이면 대출 가능한 책만 조회
          schema:
            type: boolean
        - name: page
          in: query
          schema:
            type: integer
            default: 1
      responses:
        '200':
          description: 성공
          content:
            application/json:
              schema:
                type: object
                properties:
                  books:
                    type: array
                  pagination:
                    type: object
                    properties:
                      total: { type: integer }
                      page: { type: integer }
                      hasMore: { type: boolean }
        '429':
          description: 검색 요청 과다 (분당 30회 초과)

  /books/{bookId}/reviews:
    post:
      summary: 리뷰 작성
      parameters:
        - name: bookId
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [rating]
              properties:
                rating:
                  type: integer
                  minimum: 1
                  maximum: 5
                comment:
                  type: string
                  maxLength: 500
                  nullable: true
      responses:
        '201':
          description: 리뷰 작성 성공
        '409':
          description: 이미 리뷰를 작성한 책
        '403':
          description: 대출 기록이 없는 책 (대출 후 리뷰 가능)
```

**API 명세 이해 프롬프트**:

```
위 TecoBooks API 명세를 PM 관점에서 분석해줘.

분석 항목:
1. 각 API가 하는 일 (비기술적 설명)
2. 에러 코드별 사용자에게 보여줄 메시지 제안
3. 기획서에 반드시 추가해야 할 케이스
4. UX 관점에서 고려해야 할 제약 (rate limit, maxLength 등)
5. 이 API 명세에서 발견되는 비즈니스 규칙 (예: "대출 후에만 리뷰 가능")
```

`api-spec-review.md`에 다음 내용을 정리하세요:
- 발견한 비즈니스 규칙 목록
- 기획서에 추가해야 할 케이스 목록
- 에러별 사용자 메시지 초안

---

## Step 6. 킥오프 회의록 → 스프린트 티켓 (10분)

`sprint-planning/meeting-notes.md`를 만들고 다음 회의록 내용을 붙여넣으세요.

```markdown
# TecoBooks 프로젝트 킥오프 회의
- 일시: 2026-07-20 오후 2시
- 참석: 김PM, 이프론트(FE 리드), 박백엔드(BE 리드), 정디자인(UI/UX)
- 목적: MVP 개발 Sprint 1 계획

## 논의

### 1. MVP 스코프 합의
- 이프론트: 홈 피드 + 도서 검색 + 도서 상세 3화면이 Sprint 1 목표
- 박백엔드: 도서 목록 API + 검색 API + 리뷰 API 3개 Sprint 1 완료 예정
- 정디자인: 디자인 시스템 먼저 잡아야 함, 컬러/타이포/컴포넌트 기준 1주차에

### 2. 인증 방식 결정
- 사내 Google Workspace 계정으로 소셜 로그인 (OAuth 2.0)
- 박백엔드: Google OAuth 연동 경험 있음, 1일 내 완료 가능
- 별도 회원가입 화면 불필요

### 3. 기술 이슈
- 도서 표지 이미지: 직접 업로드 vs 외부 API (Google Books API) 논의
- 정디자인: 표지 없는 책은 제목 이니셜로 대체하는 디자인 준비할게요
- 박백엔드: Google Books API 무료 quota 확인 필요 (Spike 필요)

### 4. 일정
- Sprint 1: 7/21 ~ 8/3 (2주)
- 중간 공유: 7/28 (내부 데모)
- MVP 데모: 8/4 (인사팀 + 경영진)

## 결정 사항
- Sprint 1 범위: 홈 피드 / 검색 / 도서 상세 / Google OAuth
- 표지 이미지는 Spike 결과에 따라 Sprint 2에서 결정
- 디자인 시스템 1주차 우선 완료 후 개발 착수
```

`sprint-planning/sprint-1-tickets.md`를 만들고 다음 프롬프트를 실행하세요:

```
위 킥오프 회의록에서 Sprint 1 JIRA 티켓을 추출해줘.

맥락:
- 프로젝트: TecoBooks
- 스프린트: Sprint 1 (7/21 ~ 8/3)
- 에픽: EP-001 TecoBooks MVP
- 팀원: 이프론트(FE), 박백엔드(BE), 정디자인(Design)

우선순위 기준:
- Highest: Sprint 1 MVP 데모 블로킹
- High: Sprint 1 범위 내 핵심 작업
- Medium: Sprint 1 내 완료 목표지만 이월 가능
- Low: 기술 조사 / 품질 개선

각 티켓 형식:
## [제목]
- **타입**: Story / Task / Design / Spike / Bug
- **우선순위**: Highest / High / Medium / Low
- **담당자**: [이름]
- **스토리 포인트**: [숫자]
- **설명**: 2~3문장
- **인수 조건**: 2~3개 구체적 항목
- **에픽**: EP-001
```

생성된 티켓을 검토하세요:
- Google Books API Spike 티켓이 포함됐는가?
- 디자인 시스템 태스크가 개발 티켓과 의존성이 표시됐는가?
- 인수 조건이 구체적인가?

---

## Step 7. 임원 보고용 요약 (5분)

`stakeholder-summary.md`를 만들고:

```
위에서 작성한 TecoBooks PRD와 Sprint 1 계획을 기반으로
인사팀 팀장 및 경영진을 위한 1페이지 보고 요약을 작성해줘.

요구사항:
- 600자 이내
- 기술 용어 없이 비즈니스 언어
- 구조: 문제 현황(수치) → 솔루션 개요 → MVP 출시 일정 → 기대 효과(수치) → 필요한 의사결정
- 톤: 자신감 있고 명확하게
- 마지막에 "승인 필요 사항" 박스 (있다면)
```

---

## Step 8. 전체 검토 및 일관성 확인 (5분)

모든 산출물이 완성됐으면, 마지막 검토를 수행하세요.

```
위에서 작성한 TecoBooks 기획 산출물 전체를 검토해줘.

확인 항목:
1. PRD의 성공 지표가 사용자 스토리에 반영됐는가?
2. API 명세에서 발견한 비즈니스 규칙이 기능 명세에 포함됐는가?
   (특히 "대출 후에만 리뷰 가능" 규칙)
3. Sprint 1 티켓이 MVP 스코프와 일치하는가?
4. 와이어프레임 명세와 HTML 프로토타입의 화면이 일치하는가?
5. 임원 요약의 일정이 마일스톤과 일치하는가?

불일치 항목이 있으면 어느 문서에서 무엇을 수정해야 하는지 목록으로.
```

---

## 캡스톤 완성 체크리스트

```
□ prd.md — 9개 섹션 완성, 성공 지표 수치화
□ user-stories.md — 15개 스토리 + 각 인수 조건 2개 이상
□ wireframe-description.md — 4화면 텍스트 명세 + ASCII 레이아웃
□ prototype.html — 3화면 HTML, 화면 전환 작동
□ api-spec-review.md — 비즈니스 규칙 + 기획 반영 필요 항목 정리
□ sprint-planning/meeting-notes.md — 킥오프 회의록
□ sprint-planning/sprint-1-tickets.md — 8개 이상 티켓, 인수 조건 구체적
□ stakeholder-summary.md — 600자 이내, 비기술적 언어

□ 전체 일관성 검토 완료
□ 불일치 항목 수정 완료
```

---

## 완성 후 회고

캡스톤을 마쳤으면 이것을 생각해보세요.

**시간 비교**:
- 오늘 실제로 걸린 시간: ___분
- Copilot 없이 같은 산출물을 만든다면: 예상 ___시간

**가장 유용했던 Copilot 활용**:
1. ___
2. ___

**다음 월요일 출근해서 바로 써볼 것** (최소 1개):
- ___

---

## 수료 메시지

2일 과정을 모두 마쳤습니다.

Day 1에서는 PRD 초안 생성, 사용자 스토리 대량 생성, INVEST 검증을 익혔습니다.
Day 2에서는 코드 읽기, 회의록 티켓 변환, HTML 프로토타입, 그리고 오늘 캡스톤으로 end-to-end를 경험했습니다.

Copilot은 이제 여러분의 기획 업무에서 초안을 잡아주는 든든한 짝꿍입니다. 처음에는 어색하지만, 2주만 써보면 "이전엔 어떻게 했지?"라는 생각이 드는 수준이 됩니다.

다음 할 일:
- [prompts.md](../prompts.md)를 북마크하고 실무에서 꺼내 쓰기
- [cheatsheet.md](../cheatsheet.md)를 모니터 옆에 인쇄해두기
- 이번 주 실제 업무 하나를 Copilot으로 해보기

---

**처음으로**: [README.md](../README.md)
