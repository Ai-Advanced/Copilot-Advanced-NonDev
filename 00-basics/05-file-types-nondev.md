# 05. 비개발자가 만나는 파일 형식 — .md / .csv / .json / .sql / .yaml

## 학습 목표

- 비개발자 업무에서 실제로 마주치는 **5가지 파일 형식**의 정체와 용도 이해
- 각 형식을 **VS Code + Copilot**으로 다루는 최소한의 감각 획득
- **엑셀·워드가 아닌 파일**을 겁내지 않게 되기

**예상 소요**: 15분 (실습 포함 25분)

---

## 5.1 왜 이 5가지를 알아야 하나

여러분이 개발자와 협업하거나 자동화 스크립트를 쓰면, 결국 이 파일들을 만나게 됩니다.

| 형식 | 실제 만나는 상황 |
|------|-------------------|
| `.md` (Markdown) | README, 위키, 회의록, 릴리즈 노트, JIRA 티켓 본문, 이 커리큘럼 자체 |
| `.csv` | 광고 데이터 다운로드, DB 내보내기, 엑셀 원본, GA 리포트 |
| `.json` | API 응답, 설정 파일, 광고 태그 JSON, 데이터 교환 |
| `.sql` | DB 쿼리, 리포트 자동화, 데이터 추출 |
| `.yaml` (또는 `.yml`) | GitHub Actions, 각종 설정 파일, docker-compose |

**핵심**: 이 파일들은 **모두 텍스트**입니다. 즉 VS Code + Copilot으로 편집·생성·이해가 가능합니다.

---

## 5.2 Markdown (`.md`) — 문서의 표준

### 왜 쓰나

- GitHub, JIRA, Notion, Slack 모두 Markdown을 인식
- 서식(굵게, 목록, 표)을 **문법으로** 표현 → 어떤 도구에서 열어도 동일
- Copilot이 가장 잘 다루는 형식

### 최소 문법 10개

```markdown
# 대제목 (H1)
## 소제목 (H2)
### 소소제목 (H3)

**굵게** *기울임* ~~취소선~~

- 불릿 목록
- 다음 항목
  - 중첩 항목

1. 번호 목록
2. 다음

[링크 이름](https://example.com)
![이미지 설명](path/to/image.png)

`인라인 코드`

​```python
# 코드 블록
print("hello")
​```

| 열1 | 열2 |
|-----|-----|
| A | B |

> 인용문
```

### VS Code에서 미리보기

- `Ctrl+K V` (Mac: `Cmd+K V`) → 우측에 렌더링된 미리보기 창

### Copilot 활용 예시

```
Chat 프롬프트:
스마트워치 X 제품 소개 페이지 초안을 Markdown으로 작성.
섹션: 개요, 주요 기능(표 3열), 스펙(표), FAQ (5개, <details> 접기 사용).
```

---

## 5.3 CSV (`.csv`) — 엑셀의 오픈 형식

### 왜 쓰나

- 엑셀은 `.xlsx` (Microsoft 전용), CSV는 어디서든 열림
- Google Analytics·광고 플랫폼·DB가 대부분 CSV로 데이터 내보내기 제공
- 텍스트라서 스크립트로 조작 쉬움

### 구조

```csv
이름,부서,입사일
김철수,마케팅,2024-03-15
이영희,개발,2023-11-01
"박,민수",영업,2025-01-10
```

- 첫 줄은 **헤더**, 이후 각 줄이 **행**
- 값에 쉼표가 있으면 **큰따옴표**로 감쌈
- 값에 큰따옴표가 있으면 `""`로 이스케이프

### VS Code 확장 추천

- **Rainbow CSV**: 컬럼별 색상 표시 → 눈에 잘 들어옴
- 설치 후 `.csv` 파일 열면 자동 적용

### Copilot 활용 예시

**시나리오**: 광고 리포트 CSV에서 특정 열만 뽑아 정리

```
Chat 프롬프트:
아래 CSV 헤더에서 [campaign_id, impressions, clicks, ctr, cost] 5개 열만 뽑고,
ctr이 2% 이상인 행만 남기는 Python 스크립트 작성 (pandas 사용).
입력 파일: report.csv, 출력 파일: filtered.csv

[헤더]
campaign_id,campaign_name,date,impressions,clicks,ctr,cost,conversions,revenue
```

---

## 5.4 JSON (`.json`) — API와 설정의 언어

### 왜 쓰나

- 대부분의 API가 JSON으로 데이터 주고받음 (예: 광고 API, 사내 시스템 API)
- 각종 설정 파일이 JSON (VS Code settings, Node.js 등)
- 구조화된 데이터를 **표현하기 좋음** (중첩, 배열)

### 구조

```json
{
  "campaign": {
    "id": "CMP-2026-001",
    "name": "여름 세일",
    "budget": 5000000,
    "active": true,
    "channels": ["facebook", "instagram", "youtube"],
    "targeting": {
      "age": [20, 35],
      "gender": "female",
      "interests": ["fashion", "beauty"]
    }
  }
}
```

**규칙**
- **키는 항상 큰따옴표**
- 문자열도 큰따옴표 (작은따옴표 X)
- 마지막 항목 뒤에 **쉼표 금지**
- 주석 불가 (있으면 JSON5 또는 JSONC)

### VS Code의 강점

- JSON 문법 오류를 **실시간 빨간 밑줄**로 알려줌
- `Ctrl+Shift+I` → JSON 자동 정렬(포맷팅)
- 중괄호 접기 지원

### Copilot 활용 예시

```
Chat 프롬프트:
아래 캠페인 정보를 JSON으로 정리. 3개 캠페인 배열로.

캠페인1: 이름 "여름 세일", 예산 500만원, 채널 페북/인스타
캠페인2: 이름 "가을 신상", 예산 300만원, 채널 유튜브만
캠페인3: 이름 "블프", 예산 1000만원, 채널 전 채널
```

---

## 5.5 SQL (`.sql`) — 데이터를 뽑는 언어

### 왜 쓰나

- **DB에서 데이터를 뽑는 표준 언어**
- 마케팅·재무·데이터 분석의 필수 도구
- 배우면 개발자에게 매번 요청하지 않아도 됨

### 최소 문법

```sql
-- 특정 열 선택 + 조건 + 정렬
SELECT name, department, hired_at
FROM employees
WHERE department = 'Marketing'
ORDER BY hired_at DESC
LIMIT 10;

-- 집계
SELECT department, COUNT(*) AS 인원수, AVG(salary) AS 평균연봉
FROM employees
GROUP BY department;

-- 조인 (두 테이블 합치기)
SELECT o.id, c.name, o.amount
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE o.created_at >= '2026-06-01';
```

### VS Code에서 SQL 다루기

- **SQLTools** 확장 설치 → DB 연결 → 파일 안에서 바로 실행
- 회사 DB에 접근 가능한 경우, 개발자에게 read-only 계정 요청

### Copilot 활용 예시 (매우 강력)

Copilot은 SQL에 매우 강합니다. 표준 SQL은 물론 PostgreSQL/MySQL 방언도 잘 이해.

```
Chat 프롬프트:
PostgreSQL 쿼리 작성.

테이블:
- orders(id, customer_id, product_id, amount, created_at)
- products(id, name, category)

요구: 2026-06 매출 카테고리별 집계.
결과 열: 카테고리, 총매출, 주문건수, 평균주문가
정렬: 총매출 내림차순.
```

**주의**: Copilot의 SQL을 **바로 프로덕션 DB에 실행하지 마세요**. 항상 **개발/스테이징 환경 또는 read-only 계정**에서 먼저 확인.

---

## 5.6 YAML (`.yaml` / `.yml`) — 사람이 읽기 좋은 설정

### 왜 쓰나

- GitHub Actions, docker-compose, Kubernetes 등 **설정 파일 표준**
- JSON보다 사람이 읽기 편함 (괄호가 없고 들여쓰기로 계층 표현)

### 구조

```yaml
campaign:
  id: CMP-2026-001
  name: 여름 세일
  budget: 5000000
  active: true
  channels:
    - facebook
    - instagram
    - youtube
  targeting:
    age: [20, 35]
    gender: female
    interests:
      - fashion
      - beauty
```

**주의**
- **들여쓰기는 반드시 스페이스** (탭 금지)
- 들여쓰기 개수가 문법의 일부 (엑셀보다 엄격)
- 콜론(`:`) 다음에 반드시 **스페이스 1칸**

### VS Code에서 YAML 다루기

- 확장 **YAML** (Red Hat 제공) 설치 → 문법 검증·자동완성
- 잘못된 들여쓰기를 빨간 물결로 표시

### Copilot 활용 예시

```
Inline Chat (docker-compose.yml 파일에서):
Redis와 PostgreSQL을 함께 띄우는 docker-compose 서비스 정의 추가.
- Redis: 포트 6379, alpine 이미지
- PostgreSQL 15, 볼륨 마운트, 초기 DB "myapp"
```

---

## 5.7 파일 형식 선택 결정 트리

새 문서를 만들 때 어떤 형식을 선택할지:

```
텍스트 문서 (README·회의록·기획서)
  → .md (Markdown)

표 형태 데이터 (엑셀 대체)
  → .csv (가벼움, 어디서든 열림)
  → .xlsx (수식·차트 필요 시)

시스템 간 데이터 교환 or API 응답
  → .json

DB에서 데이터 추출
  → .sql

CI/CD, 인프라 설정
  → .yaml
```

---

## 5.8 파일 형식별 Copilot 궁합표

| 형식 | Tab 자동완성 | Inline Chat | Chat 사이드바 |
|------|:-------------:|:------------:|:--------------:|
| `.md` | ★★★★★ | ★★★★★ | ★★★★★ |
| `.csv` | ★★★☆☆ | ★★★★☆ | ★★★★★ |
| `.json` | ★★★★★ | ★★★★★ | ★★★★★ |
| `.sql` | ★★★★☆ | ★★★★★ | ★★★★★ |
| `.yaml` | ★★★★★ | ★★★★★ | ★★★★★ |

**결론**: 5가지 모두 Copilot이 잘 다룹니다. 겁먹지 말고 열어보세요.

---

## 실습

### 실습 1. Markdown으로 자기소개 페이지 만들기

`about-me.md` 파일 생성 후, Inline Chat으로:

```
자기소개 Markdown 페이지 만들어줘.

섹션: 이름, 소속, 관심사(불릿), 최근 프로젝트(표 3열), 연락처.
표는 반드시 Markdown 표 문법.
```

→ 결과에 실제 정보로 교체 후 미리보기(`Ctrl+K V`).

### 실습 2. CSV → JSON 변환

`sample.csv` 파일 생성:

```csv
name,age,city
Alice,30,Seoul
Bob,25,Busan
Charlie,35,Incheon
```

Chat에:
```
위 CSV 데이터를 JSON 배열로 변환해줘. 결과만 붙여넣기 가능한 형태로.
```

→ 결과를 `sample.json`으로 저장.

### 실습 3. SQL 초안 생성

Chat에:
```
회원 테이블 users(id, email, signup_date, plan) 가 있어.
이번 달 신규 가입자를 plan별로 집계하는 SQL 쿼리 작성.
결과: plan, 가입자수. 정렬: 가입자수 내림차순.
```

→ 결과 SQL을 `signup.sql`로 저장. (실제 DB 없이 문법만 확인)

### 실습 4. YAML 이해

Chat에:
```
GitHub Actions YAML 워크플로우 예시:
- 트리거: main 브랜치 push
- 잡: Node.js 20 설치 → npm install → npm test
초보자용으로 각 줄 옆에 주석 포함.
```

→ 결과를 `.github/workflows/ci.yml` 형식으로 저장 (실제 실행 X, 이해만).

---

## 핵심 포인트

1. **5가지 다 텍스트 파일** → VS Code + Copilot으로 다 다뤄짐
2. **Markdown이 문서의 표준** — 이 커리큘럼 문서 대부분이 `.md`
3. **CSV = 엑셀의 오픈 형식**, JSON = 시스템 간 교환, SQL = DB 데이터, YAML = 설정
4. Copilot은 **5가지 모두에 강함** — 겁내지 말고 열어보기
5. **DB 쿼리는 항상 read-only 환경에서 먼저 검증**

---

## 공통 기초 완료!

이 5개 문서를 다 마쳤다면, 이제 자기 직군 폴더로 이동하세요.

- 기획/PM → [01-planning-pm/](../01-planning-pm/)
- 디자이너 → [02-designer/](../02-designer/)
- 마케터 → [03-marketer/](../03-marketer/)
- 영업/CS → [04-sales-cs/](../04-sales-cs/)
- HR/인사 → [05-hr/](../05-hr/)
- 재무/회계 → [06-finance/](../06-finance/)
- 일반 오피스 → [07-office-worker/](../07-office-worker/)
- 데이터 분석 → [08-data-analyst/](../08-data-analyst/)
