# 08. 데이터 분석가 (비개발) — GitHub Copilot 2일 심화 과정

**과정 후 추가 실습:** [Copilot CLI로 가상 데이터 대시보드를 Azure에 배포](../09-azure-capstone/README.md) · [직군별 요구사항](../09-azure-capstone/roles.md). 기존 2일 과정 외 별도 편성입니다.

> **대상**: BI 분석가 · 비즈니스 분석가 · 그로스 분석가 · 프로덕트 분석가
> SQL은 쓸 줄 알지만 Python은 부담스러운 분析가, 반복 SQL/pandas 작업을 절반으로 줄이고 싶은 분析가.
>
> **목표**: Copilot으로 반복 SQL/pandas 작업 시간 50% 단축, 분석 → 인사이트 → 리포트 파이프라인 자동화

---

## 이 과정이 필요한 이유

데이터 분석가의 하루를 솔직하게 보면 이렇습니다.

| 실제 시간 배분 | 이상적인 시간 배분 |
|--------------|----------------|
| SQL 작성/디버깅 30% | SQL 작성 10% |
| 데이터 클리닝 25% | 데이터 클리닝 10% |
| 차트/리포트 포맷팅 20% | 분석·해석 50% |
| 인사이트 도출 15% | 커뮤니케이션 20% |
| 커뮤니케이션 10% | 자동화/개선 10% |

Copilot은 **반복 SQL, 클리닝 코드, 차트 코드, 리포트 문장화** 4가지를 대신 씁니다.
여러분은 **"이 숫자가 왜 이렇게 나왔는가"를 해석하는 일**에 집중하면 됩니다.

---

## 대상 독자 상세

### 이 과정이 딱 맞는 분析가

- **BI 분析가**: Tableau/Looker/Metabase 대시보드를 만들고, 스펙 문서를 써야 함
- **비즈니스 分析가**: SQL로 데이터를 뽑고, 엑셀/스프레드시트에서 후처리 중
- **그로스 分析가**: 퍼널·코호트·A/B 테스트 분析을 반복하는데 매번 SQL을 처음부터 씀
- **프로덕트 分析가**: 사용자 행동 데이터를 분析하고, 지표 정의서와 임원 리포트를 써야 함

### 전제 조건

- `SELECT`, `WHERE`, `GROUP BY`, `JOIN` 기본 SQL 작성 가능
- 엑셀/스프레드시트에서 피벗 테이블 경험 있음
- Python/pandas는 몰라도 됨 (이 과정에서 Copilot으로 같이 배움)
- 00-basics/ 5개 파일 완료

### 이 과정에서 배우지 않는 것

- ML/딥러닝 모델링 (별도 AI/ML 커리큘럼에서)
- 프로덕션 데이터 파이프라인 엔지니어링 (dbt, Airflow 등)
- 마케팅 채널 분析 (03-marketer 과정에서)
- 재무 지표 분析 (06-finance 과정에서)

---

## 사전 준비

### 필수 VS Code 확장 (설치 확인)

```
확장 검색창 (Ctrl+Shift+X):
1. GitHub Copilot           → 이미 설치되어 있어야 함
2. GitHub Copilot Chat      → 이미 설치되어 있어야 함
3. SQLTools                 → SQL 파일 실행용
4. Rainbow CSV              → CSV 파일 컬럼 색상 구분
5. Jupyter                  → .ipynb 노트북 실행
6. Python (Microsoft)       → Python 파일 실행
```

### Python 환경 설정

```bash
# Python 3.10 이상 확인
python --version   # 또는 python3 --version

# 필수 패키지 설치
pip install pandas numpy matplotlib seaborn plotly openpyxl jupyter

# 설치 확인
python -c "import pandas; print(pandas.__version__)"
```

### SQLTools 설정 (선택)

실제 DB에 연결하지 않아도 이 과정을 따라올 수 있습니다.
실습 SQL은 모두 PostgreSQL 문법 기준이며, 로컬에서 실행하지 않아도 됩니다.

DB 연결이 가능한 경우:
1. SQLTools 확장 설치
2. Ctrl+Shift+P → "SQLTools: Add New Connection"
3. DB 타입 선택 (PostgreSQL / MySQL / BigQuery 등)
4. **반드시 read-only 계정으로 연결** (분析가용 계정은 SELECT 권한만)

### 실습 파일 다운로드

이 과정의 실습은 가상 "구독 서비스" 시나리오를 사용합니다.
실제 PII(개인식별정보)가 없는 합성 데이터입니다.

```
08-data-analyst/
├── resources/
│   ├── templates/
│   │   ├── sql-patterns.sql          ← 분析 SQL 패턴 15개+
│   │   └── dashboard-spec-template.md ← 대시보드 스펙 템플릿
│   └── examples/
│       └── pandas-recipes.py         ← pandas 실무 레시피 15개+
```

---

## 2일 커리큘럼 구조

### Day 1 (약 4시간) — SQL + 데이터 클리닝

| # | 챕터 | 소요 시간 | 핵심 내용 |
|---|------|----------|----------|
| 01 | 분析가의 Copilot 활용법 개요 | 30분 | 15가지 활용 시나리오, Before/After |
| 02 | SQL 심화 마스터리 | 90분 | Window Function, CTE, 코호트 SQL |
| 03 | 데이터 클리닝 | 60분 | 결측치/이상치/중복, SQL+Python 클리닝 |
| 04 | Day 1 종합 실습 | 60분 | "월간 사용자 리포트" 엔드투엔드 |

### Day 2 (약 4시간) — pandas + 시각화 + 스토리텔링

| # | 챕터 | 소요 시간 | 핵심 내용 |
|---|------|----------|----------|
| 05 | pandas 실전 기초 | 75분 | read_csv/filter/groupby/pivot/merge |
| 06 | 시각화 코드 | 60분 | matplotlib/seaborn/plotly, 차트 6종 |
| 07 | 대시보드 스펙 + 스토리텔링 | 45분 | Tableau/Looker 스펙 문서화, 인사이트 문장화 |
| 08 | 캡스톤 프로젝트 | 60분 | 구독 서비스 딥다이브 전체 파이프라인 |

---

## 학습 시나리오: "구독 서비스 Zeta"

이 과정 전반에서 가상의 B2C 구독 서비스 **Zeta**를 분析합니다.
모든 데이터는 합성(synthetic)이며, 실제 회사·사용자와 무관합니다.

**Zeta 서비스 개요**
- 월정액 구독 서비스 (Basic $9.99 / Pro $19.99 / Enterprise $49.99)
- 사용자 약 50만 명, 월 신규 가입 약 3만 명
- 주요 지표: 신규 가입, 전환율, 리텐션, 이탈률, MRR, LTV

**데이터 스키마 (전 챕터 공통)**

```sql
-- 사용자 테이블
users (
  user_id       BIGINT PRIMARY KEY,
  signup_date   DATE,
  plan          VARCHAR(20),   -- 'basic' | 'pro' | 'enterprise'
  country       VARCHAR(2),    -- ISO 국가 코드
  channel       VARCHAR(30),   -- 유입 채널
  age_group     VARCHAR(10)    -- '18-24' | '25-34' | '35-44' | '45+'
)

-- 구독 이벤트 테이블
subscriptions (
  subscription_id BIGINT PRIMARY KEY,
  user_id         BIGINT,
  event_type      VARCHAR(20),  -- 'subscribe' | 'upgrade' | 'downgrade' | 'cancel'
  plan            VARCHAR(20),
  event_date      DATE,
  mrr             NUMERIC(10,2) -- 이벤트 시점 MRR
)

-- 사용 이벤트 테이블
events (
  event_id    BIGINT PRIMARY KEY,
  user_id     BIGINT,
  event_name  VARCHAR(50),
  event_date  DATE,
  session_id  VARCHAR(36)
)

-- 결제 테이블
payments (
  payment_id  BIGINT PRIMARY KEY,
  user_id     BIGINT,
  amount      NUMERIC(10,2),
  status      VARCHAR(20),  -- 'success' | 'failed' | 'refunded'
  paid_at     TIMESTAMP
)
```

---

## 데이터 프라이버시 원칙

이 과정 전반에서 강조하는 규칙입니다.

| 원칙 | 실천 방법 |
|------|---------|
| **PII를 Copilot에 붙이지 않는다** | 실제 이름·이메일·전화번호가 포함된 데이터를 프롬프트에 직접 넣지 않는다 |
| **샘플 데이터는 익명화 후 사용** | 실제 데이터 분析 시 5~10행 샘플은 PII 열 제거 또는 마스킹 후 사용 |
| **컬럼명·스키마만 공유** | Copilot에게 데이터 구조 설명 시 컬럼명과 타입만, 실제 값은 넣지 않는다 |
| **집계 결과는 공유 가능** | `user_id` 개별 행이 아닌 COUNT/SUM 집계 결과는 상대적으로 안전 |

```
좋은 예:
"users 테이블에서 signup_date, plan, country 컬럼으로 월별 가입자를 집계하는 SQL 작성"

나쁜 예:
"아래 사용자 데이터에서 패턴 분析해줘
user_id, email, 이름, 전화번호가 담긴 실제 CSV 붙여넣기"
```

---

## 이 과정을 마치면

- Window Function(ROW_NUMBER/LAG/LEAD/RANK)을 자유롭게 쓰는 SQL
- 코호트 리텐션, 퍼널, RFM 분析 SQL을 Copilot으로 30분 안에 완성
- 지저분한 CSV를 pandas로 클리닝하는 코드를 프롬프트 3개로 생성
- matplotlib/seaborn/plotly로 대시보드용 차트 6종 코드 작성
- "숫자 나열"이 아닌 "인사이트 스토리"를 담은 임원 리포트 작성
- Tableau/Looker/Metabase용 대시보드 스펙 문서 템플릿 보유

---

## 시작하기

```
Day 1 시작 → day1/01-analyst-copilot-overview.md
```

막히는 부분이 있으면 `prompts.md`의 치트시트를 먼저 확인하세요.
자주 쓰는 프롬프트는 VS Code 스니펫으로 저장해두면 반복 사용이 편합니다.
