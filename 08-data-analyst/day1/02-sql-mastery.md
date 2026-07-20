# 02. SQL 심화 마스터리 — Window Function, CTE, 코호트 分析

## 학습 목표

- Window Function 4종(ROW_NUMBER / LAG / LEAD / RANK)을 언제 왜 쓰는지 정확히 이해
- CTE(WITH 절)로 복잡한 쿼리를 읽기 쉽게 분해하는 방법 체득
- 서브쿼리 vs JOIN 선택 기준 파악
- 인덱스 개념을 쿼리 작성에 적용하는 수준으로 이해
- Copilot으로 복잡한 SQL을 프롬프팅하고, 생성된 결과를 검증하는 루틴 확립
- 실습 SQL 5개 완성: 유저 코호트 리텐션, 세션 분析(LAG), 퍼널, RFM, MRR 분해

**예상 소요**: 90분

---

## 2.1 Window Function이란: 그룹을 유지하면서 계산하기

### GROUP BY의 한계

`GROUP BY`는 행을 묶어 집계합니다. 묶고 나면 **개별 행 정보를 잃습니다.**

```sql
-- GROUP BY: 사용자별 총 결제 금액
-- 개별 결제 내역은 사라짐
SELECT user_id, SUM(amount) AS total_amount
FROM payments
GROUP BY user_id;
```

분析에서 자주 마주치는 질문: "각 사용자의 개별 결제 내역을 보면서 동시에 해당 사용자의 누적 합계를 보고 싶다" — 이건 `GROUP BY`로 안 됩니다.

### Window Function: 행을 유지하면서 집계

```sql
-- 각 결제 행을 그대로 두면서 사용자별 누적 합계를 옆에 추가
SELECT
    payment_id,
    user_id,
    amount,
    paid_at,
    SUM(amount) OVER (PARTITION BY user_id ORDER BY paid_at) AS cumulative_amount
FROM payments;
```

결과 예시:
```
payment_id | user_id | amount | paid_at    | cumulative_amount
1          | 101     | 19.99  | 2024-01-15 | 19.99
2          | 101     | 19.99  | 2024-02-15 | 39.98
3          | 101     | 19.99  | 2024-03-15 | 59.97
4          | 102     | 9.99   | 2024-01-20 | 9.99
```

### Window Function 문법 구조

```sql
함수명() OVER (
    PARTITION BY 그룹_컬럼    -- GROUP BY와 유사 (없으면 전체를 하나의 윈도우로)
    ORDER BY     정렬_컬럼    -- 윈도우 내 순서
    ROWS BETWEEN ...          -- 범위 지정 (선택)
)
```

---

## 2.2 ROW_NUMBER — 순번 부여 (중복 없음)

### 언제 쓰나

- 사용자별 첫 번째/마지막 이벤트 추출
- 중복 제거 (동일 기준 중 하나만 남기기)
- 순위 부여 (동점은 다른 번호)

### 기본 사용

```sql
-- 각 사용자의 이벤트를 날짜 역순으로 번호 매기기
-- 번호 1 = 가장 최근 이벤트
SELECT
    user_id,
    event_name,
    event_date,
    ROW_NUMBER() OVER (
        PARTITION BY user_id
        ORDER BY event_date DESC
    ) AS rn
FROM events;
```

### 실전 활용: 사용자별 첫 번째 이벤트만 추출

```sql
-- CTE로 번호 부여 후 필터링
WITH ranked AS (
    SELECT
        user_id,
        event_name,
        event_date,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY event_date ASC  -- 오름차순 = 가장 오래된 것이 1번
        ) AS rn
    FROM events
)
SELECT user_id, event_name, event_date
FROM ranked
WHERE rn = 1;  -- 사용자별 첫 번째 이벤트만
```

### 실전 활용: 중복 제거

```sql
-- 동일 (user_id, event_date, event_name) 조합의 중복 제거
-- subscription_id가 큰 것(최신)을 남김
WITH deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY user_id, event_date, event_name
            ORDER BY subscription_id DESC
        ) AS rn
    FROM subscriptions
)
SELECT * FROM deduped WHERE rn = 1;
```

### Copilot 프롬프트

```
PostgreSQL. subscriptions 테이블(subscription_id, user_id, event_type, event_date)에서
동일 user_id + event_date + event_type 조합의 중복을 제거하는 SQL.
subscription_id가 가장 큰 행(최신)을 남기기.
ROW_NUMBER() OVER(PARTITION BY ... ORDER BY ...) 방식.
```

---

## 2.3 LAG / LEAD — 이전/다음 행 참조

### 언제 쓰나

- 이전 이벤트와의 시간 간격 계산 (세션 분析)
- 전월 대비 변화량 계산
- 연속 행동 패턴 탐지 (예: 두 번 연속 이탈 신호)

### LAG: 이전 행 참조

```sql
-- 각 사용자의 이벤트 간격(일수) 계산
SELECT
    user_id,
    event_name,
    event_date,
    LAG(event_date) OVER (
        PARTITION BY user_id
        ORDER BY event_date
    ) AS prev_event_date,
    event_date - LAG(event_date) OVER (
        PARTITION BY user_id
        ORDER BY event_date
    ) AS days_since_last_event
FROM events
ORDER BY user_id, event_date;
```

결과 예시:
```
user_id | event_name   | event_date | prev_event_date | days_since_last_event
101     | login        | 2024-01-05 | NULL            | NULL
101     | feature_use  | 2024-01-07 | 2024-01-05      | 2
101     | login        | 2024-01-10 | 2024-01-07      | 3
101     | login        | 2024-02-15 | 2024-01-10      | 36   ← 휴면 신호
```

### LEAD: 다음 행 참조

```sql
-- 구독 이벤트에서 다음 이벤트까지의 기간 계산
SELECT
    user_id,
    event_type,
    event_date,
    LEAD(event_type) OVER (
        PARTITION BY user_id
        ORDER BY event_date
    ) AS next_event_type,
    LEAD(event_date) OVER (
        PARTITION BY user_id
        ORDER BY event_date
    ) AS next_event_date
FROM subscriptions
ORDER BY user_id, event_date;
```

### 실전 활용: 세션 분리 (30분 기준)

```sql
-- 이전 이벤트로부터 30분 이상 경과하면 새 세션으로 분류
WITH with_gap AS (
    SELECT
        user_id,
        event_name,
        event_date,
        LAG(event_date) OVER (
            PARTITION BY user_id
            ORDER BY event_date
        ) AS prev_event_date
    FROM events
),
with_new_session AS (
    SELECT
        *,
        CASE
            WHEN prev_event_date IS NULL THEN 1  -- 첫 이벤트
            WHEN event_date - prev_event_date > INTERVAL '30 minutes' THEN 1
            ELSE 0
        END AS is_new_session
    FROM with_gap
)
SELECT
    user_id,
    event_name,
    event_date,
    SUM(is_new_session) OVER (
        PARTITION BY user_id
        ORDER BY event_date
    ) AS session_number  -- 세션 번호 (누적 합)
FROM with_new_session
ORDER BY user_id, event_date;
```

### Copilot 프롬프트

```
PostgreSQL. events 테이블(user_id, event_name, event_date TIMESTAMP)에서
세션을 분리하는 SQL.
세션 기준: 동일 user_id 기준 이전 이벤트로부터 30분 이상 간격이면 새 세션.
LAG() + SUM() OVER() 방식으로 session_number 부여.
추가: 세션별 이벤트 수, 세션 시작 시각, 세션 종료 시각, 지속 시간(분) 집계 쿼리도 작성.
```

---

## 2.4 RANK / DENSE_RANK — 순위 (동점 처리 포함)

### ROW_NUMBER vs RANK vs DENSE_RANK 차이

| 점수 | ROW_NUMBER | RANK | DENSE_RANK |
|------|-----------|------|-----------|
| 100  | 1         | 1    | 1         |
| 90   | 2         | 2    | 2         |
| 90   | 3         | 2    | 2         |
| 80   | 4         | 4    | 3         |

- **ROW_NUMBER**: 동점이어도 무조건 다른 번호 (순서는 ORDER BY 기준 임의)
- **RANK**: 동점은 같은 순위, 다음 순위는 건너뜀 (1,2,2,4)
- **DENSE_RANK**: 동점은 같은 순위, 다음 순위는 연속 (1,2,2,3)

### 실전 활용: 월별 상위 10개 상품

```sql
-- 월별로 매출 상위 10개 상품 (동점 있을 경우 RANK 사용)
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', paid_at)::DATE AS month,
        plan,
        SUM(amount) AS total_revenue,
        RANK() OVER (
            PARTITION BY DATE_TRUNC('month', paid_at)
            ORDER BY SUM(amount) DESC
        ) AS revenue_rank
    FROM payments
    GROUP BY DATE_TRUNC('month', paid_at), plan
)
SELECT *
FROM monthly_sales
WHERE revenue_rank <= 10
ORDER BY month, revenue_rank;
```

### NTILE: 동일 크기 버킷으로 분할 (RFM에 필수)

```sql
-- 결제 금액 기준으로 4분위수로 나누기
SELECT
    user_id,
    SUM(amount) AS total_spent,
    NTILE(4) OVER (ORDER BY SUM(amount) DESC) AS spending_quartile
FROM payments
GROUP BY user_id;
-- 1 = 상위 25%, 4 = 하위 25%
```

---

## 2.5 CTE (WITH 절) — 복잡한 쿼리를 분해하기

### CTE를 써야 하는 이유

중첩 서브쿼리는 안에서 밖으로 읽어야 합니다. 사람의 사고 방식과 반대입니다.
CTE는 위에서 아래로 읽습니다. 단계별 로직을 따라가기 쉽습니다.

```sql
-- 나쁜 예: 중첩 서브쿼리
SELECT user_id, cohort_month, month_number, retention_rate
FROM (
    SELECT user_id, cohort_month, month_number,
           COUNT(DISTINCT user_id) / first_count AS retention_rate
    FROM (
        SELECT ...
        FROM (
            SELECT ...
        ) AS innermost
    ) AS middle
) AS outer_query;
-- 안에서부터 읽어야 함

-- 좋은 예: CTE로 분해
WITH
cohort_base AS (
    -- 1단계: 각 사용자의 코호트 월 정의
    ...
),
monthly_activity AS (
    -- 2단계: 월별 활동 사용자 집계
    ...
),
retention_calc AS (
    -- 3단계: 리텐션 계산
    ...
)
SELECT * FROM retention_calc;
-- 위에서 아래로 읽음
```

### CTE 문법

```sql
WITH
cte_name1 AS (
    SELECT ...
    FROM ...
    WHERE ...
),
cte_name2 AS (
    -- cte_name1을 참조 가능
    SELECT *
    FROM cte_name1
    WHERE ...
)
SELECT *
FROM cte_name2;
```

**규칙**
- `WITH` 한 번만, CTE 여러 개는 콤마로 연결
- 각 CTE는 이전 CTE를 참조 가능 (순서 중요)
- 마지막 CTE 뒤에는 콤마 없음
- 실제 테이블처럼 SELECT, JOIN, WHERE 등 자유롭게 사용

---

## 2.6 코호트 리텐션 SQL (핵심 실습)

코호트 리텐션은 분析가가 가장 자주 작성하는 복잡한 SQL입니다.
Copilot으로 뼈대를 생성하고, 검증 포인트를 직접 확인하는 루틴을 익힙니다.

### 코호트 리텐션 정의

- **코호트**: 특정 기간에 처음 가입한 사용자 그룹
- **리텐션**: 코호트 월 이후 N개월째에도 서비스를 사용(구독 유지)하는 비율

| 코호트 | Month 0 | Month 1 | Month 2 | Month 3 |
|--------|---------|---------|---------|---------|
| 2024-01 | 100%   | 72%     | 61%     | 55%     |
| 2024-02 | 100%   | 69%     | 58%     |         |
| 2024-03 | 100%   | 71%     |         |         |

### Copilot 프롬프트

```
PostgreSQL. 월별 코호트 리텐션 분析 SQL.
테이블: subscriptions(user_id, event_type, event_date)
event_type: 'subscribe' (신규/재구독), 'cancel' (해지)

정의:
- 코호트 월: 해당 사용자의 첫 'subscribe' 이벤트가 있는 월
- 리텐션: 코호트 월 이후 N번째 월에도 'subscribe' 상태(cancel이 없거나 재구독)인 사용자 비율

결과 형태:
cohort_month | cohort_size | month_0 | month_1 | month_2 | month_3 | month_6 | month_12
(month_0은 100%, 이후는 비율 0.00~1.00 형식)

WITH 절 사용, 각 CTE에 한국어 주석.
```

### 생성된 SQL 검증 포인트

Copilot이 생성한 코호트 SQL에서 반드시 확인해야 할 사항:

```sql
-- ✅ 확인 1: 코호트 기준이 MIN(event_date) 기준인지
-- 잘못된 예: event_date의 DATE_TRUNC를 코호트로 잡으면 재구독이 새 코호트로 잡힘
WITH cohort_base AS (
    SELECT
        user_id,
        DATE_TRUNC('month', MIN(event_date))::DATE AS cohort_month  -- MIN이 중요
    FROM subscriptions
    WHERE event_type = 'subscribe'
    GROUP BY user_id
)

-- ✅ 확인 2: JOIN 방향이 LEFT JOIN인지 (리텐션 0인 경우도 포함해야 함)
-- INNER JOIN이면 Month N에 아무도 없는 경우 해당 행 자체가 사라짐

-- ✅ 확인 3: month_number 계산
-- PostgreSQL: EXTRACT(YEAR FROM age(activity_month, cohort_month)) * 12
--              + EXTRACT(MONTH FROM age(activity_month, cohort_month))
-- 또는: (DATE_PART('year', activity_month) - DATE_PART('year', cohort_month)) * 12
--      + (DATE_PART('month', activity_month) - DATE_PART('month', cohort_month))
```

### 완성된 코호트 리텐션 SQL

```sql
-- ============================================================
-- 월별 코호트 리텐션 분析
-- 테이블: subscriptions(user_id, event_type, event_date)
-- ============================================================

WITH
-- CTE 1: 각 사용자의 코호트 월 (첫 구독 월)
cohort_base AS (
    SELECT
        user_id,
        DATE_TRUNC('month', MIN(event_date))::DATE AS cohort_month
    FROM subscriptions
    WHERE event_type = 'subscribe'
    GROUP BY user_id
),

-- CTE 2: 각 사용자의 월별 활동 (구독 유지 여부)
monthly_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_TRUNC('month', event_date)::DATE AS activity_month
    FROM subscriptions
    WHERE event_type = 'subscribe'
),

-- CTE 3: 코호트와 활동을 조인하여 month_number 계산
cohort_activity AS (
    SELECT
        c.cohort_month,
        c.user_id,
        m.activity_month,
        (DATE_PART('year', m.activity_month) - DATE_PART('year', c.cohort_month)) * 12
        + (DATE_PART('month', m.activity_month) - DATE_PART('month', c.cohort_month))
        AS month_number
    FROM cohort_base c
    LEFT JOIN monthly_activity m ON c.user_id = m.user_id
),

-- CTE 4: 코호트별 초기 사용자 수 집계
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT user_id) AS cohort_users
    FROM cohort_base
    GROUP BY cohort_month
),

-- CTE 5: 월별 리텐션 집계
retention_by_month AS (
    SELECT
        ca.cohort_month,
        ca.month_number,
        COUNT(DISTINCT ca.user_id) AS retained_users
    FROM cohort_activity ca
    WHERE ca.month_number >= 0
    GROUP BY ca.cohort_month, ca.month_number
)

-- 최종: 리텐션 비율 계산
SELECT
    r.cohort_month,
    cs.cohort_users,
    r.month_number,
    r.retained_users,
    ROUND(r.retained_users::NUMERIC / cs.cohort_users, 4) AS retention_rate
FROM retention_by_month r
JOIN cohort_size cs ON r.cohort_month = cs.cohort_month
ORDER BY r.cohort_month, r.month_number;
```

**피벗 형태로 보고 싶을 때** (Copilot에 추가 요청):

```
위 쿼리 결과를 피벗해서
행=cohort_month, 열=month_0~month_12 형태로 보여주는 쿼리 추가.
PostgreSQL FILTER 또는 CASE WHEN 방식.
```

---

## 2.7 서브쿼리 vs JOIN: 선택 기준

### 언제 서브쿼리를 쓰나

서브쿼리는 결과를 한 값 또는 한 집합으로 비교할 때 직관적입니다.

```sql
-- 평균보다 많이 결제한 사용자
SELECT user_id, SUM(amount) AS total
FROM payments
GROUP BY user_id
HAVING SUM(amount) > (SELECT AVG(total_amount) FROM (
    SELECT SUM(amount) AS total_amount
    FROM payments GROUP BY user_id
) AS sub);
```

### 언제 JOIN을 쓰나

여러 테이블의 컬럼을 함께 봐야 할 때, 특히 대량 데이터에서 JOIN이 서브쿼리보다 빠릅니다.

```sql
-- 사용자 정보와 결제 정보를 함께 보기
SELECT
    u.user_id,
    u.plan,
    u.signup_date,
    p.total_paid,
    p.payment_count
FROM users u
LEFT JOIN (
    SELECT user_id, SUM(amount) AS total_paid, COUNT(*) AS payment_count
    FROM payments
    GROUP BY user_id
) p ON u.user_id = p.user_id;
```

### Copilot이 자주 틀리는 JOIN 실수

```sql
-- ❌ Copilot이 INNER JOIN으로 생성하는 경우
-- 결제 내역이 없는 사용자가 사라짐
SELECT u.user_id, p.amount
FROM users u
INNER JOIN payments p ON u.user_id = p.user_id;  -- 결제 없는 user 누락!

-- ✅ 올바른 LEFT JOIN
SELECT u.user_id, COALESCE(p.amount, 0) AS amount
FROM users u
LEFT JOIN payments p ON u.user_id = p.user_id;   -- 결제 없으면 0
```

**검증 방법**: JOIN 전후 행 수를 항상 비교합니다.

```sql
-- JOIN 전
SELECT COUNT(*) FROM users;         -- 예: 500,000

-- JOIN 후
SELECT COUNT(*) FROM users u
LEFT JOIN payments p ON u.user_id = p.user_id;
-- LEFT JOIN은 500,000 이상 (1:多 관계), INNER JOIN은 더 적을 수 있음
```

---

## 2.8 인덱스 이해: 분析가 수준에서 알아야 할 것

분析가가 인덱스를 직접 만들 필요는 없습니다.
하지만 "이 쿼리가 왜 느린지", "어떤 컬럼에 인덱스를 요청해야 하는지" 파악은 해야 합니다.

### 인덱스가 효과적인 경우

```sql
-- WHERE 조건으로 특정 값을 필터링하는 컬럼
WHERE user_id = 12345           -- user_id에 인덱스가 있으면 빠름
WHERE event_date >= '2024-01-01' -- event_date에 인덱스 필요

-- JOIN 키
JOIN subscriptions s ON u.user_id = s.user_id  -- user_id에 인덱스 필요
```

### 인덱스가 효과 없는 경우

```sql
-- 함수를 씌우면 인덱스 무효화
WHERE DATE_TRUNC('month', event_date) = '2024-01-01'  -- event_date 인덱스 못 씀
-- 해결: 범위 조건으로 변경
WHERE event_date >= '2024-01-01' AND event_date < '2024-02-01'

-- 앞에 %를 붙인 LIKE
WHERE email LIKE '%@gmail.com'   -- 인덱스 못 씀
```

### EXPLAIN ANALYZE 읽기 (기초)

```sql
EXPLAIN ANALYZE
SELECT user_id, COUNT(*) FROM events WHERE event_date >= '2024-01-01' GROUP BY user_id;
```

Copilot에게 결과 해석 요청:
```
다음 PostgreSQL EXPLAIN ANALYZE 결과를 분析가용으로 쉽게 설명해줘.
어떤 부분이 느린지, 어떻게 개선할 수 있는지.
[결과 붙여넣기]
```

---

## 2.9 CTAS와 임시 테이블

### CTAS (Create Table As Select)

분析용 중간 결과를 테이블로 저장할 때:

```sql
-- PostgreSQL
CREATE TABLE cohort_retention_2024 AS
SELECT ...
FROM subscriptions
WHERE event_date >= '2024-01-01';

-- BigQuery
CREATE OR REPLACE TABLE `project.dataset.cohort_retention_2024` AS
SELECT ...

-- Snowflake
CREATE OR REPLACE TABLE cohort_retention_2024 AS
SELECT ...
```

### UNION / INTERSECT / EXCEPT

```sql
-- UNION: 두 결과를 합치기 (중복 제거)
SELECT user_id FROM subscriptions WHERE event_type = 'subscribe' AND event_date >= '2024-01-01'
UNION
SELECT user_id FROM events WHERE event_name = 'direct_signup' AND event_date >= '2024-01-01';

-- UNION ALL: 중복 포함 (UNION보다 빠름)
SELECT user_id, 'subscription' AS source FROM subscriptions
UNION ALL
SELECT user_id, 'event' AS source FROM events;

-- INTERSECT: 두 결과의 교집합 (양쪽 모두에 있는 user_id)
SELECT user_id FROM premium_users
INTERSECT
SELECT user_id FROM active_last_30d;

-- EXCEPT: 차집합 (첫 번째에만 있는 것)
SELECT user_id FROM all_users
EXCEPT
SELECT user_id FROM paying_users;  -- 미결제 사용자
```

---

## 2.10 SQL 방언별 주의사항

같은 로직도 DB마다 문법이 다릅니다. Copilot에 방언을 명시하는 이유입니다.

| 기능 | PostgreSQL | BigQuery | Snowflake |
|------|-----------|---------|----------|
| 날짜 자르기 | `DATE_TRUNC('month', col)` | `DATE_TRUNC(col, MONTH)` | `DATE_TRUNC('MONTH', col)` |
| 날짜 연속 생성 | `GENERATE_SERIES(start, end, '1 day')` | `GENERATE_DATE_ARRAY(start, end)` | `DATEADD` + 재귀 CTE |
| 대소문자 무시 LIKE | `ILIKE` | `LOWER(col) LIKE` | `ILIKE` (Snowflake 지원) |
| 날짜 차이 (일) | `date1 - date2` | `DATE_DIFF(date1, date2, DAY)` | `DATEDIFF(DAY, date1, date2)` |
| 현재 날짜 | `CURRENT_DATE` | `CURRENT_DATE()` | `CURRENT_DATE()` |
| 문자열 잘라내기 | `SUBSTRING(str, 1, 3)` | `SUBSTR(str, 1, 3)` | `SUBSTR(str, 1, 3)` |

**Copilot 프롬프트 팁**: 방언 변환 요청

```
다음 PostgreSQL 쿼리를 BigQuery Standard SQL로 변환해줘.
특히 DATE_TRUNC 인자 순서와 GENERATE_SERIES 대체 방법 포함.
[쿼리 붙여넣기]
```

---

## 2.11 실습: SQL 5개 완성

아래 5개 SQL을 Copilot 프롬프트로 생성하고 검증합니다.
각 실습 후 **검증 포인트**를 반드시 확인하세요.

### 실습 SQL 1. 유저 코호트 리텐션 (2.6 참고)

**목표**: 월별 코호트 × Month 0~12 리텐션 테이블

**프롬프트**: 2.6절의 프롬프트 사용

**검증 포인트**:
- [ ] Month 0이 모두 100%(또는 동일 코호트 크기)인지 확인
- [ ] JOIN이 LEFT JOIN인지 확인
- [ ] 코호트 기준이 MIN(event_date)인지 확인
- [ ] 리텐션율이 0~1 사이인지 확인

### 실습 SQL 2. 세션 붙이기 (LAG 활용)

**목표**: 각 이벤트에 session_number 부여, 세션별 통계 집계

**프롬프트**:
```
PostgreSQL. events 테이블(event_id, user_id, event_name, event_date TIMESTAMP) 기준.

1단계: 각 이벤트에 session_number 부여
- 동일 user_id 기준으로 이전 이벤트와 30분 이상 간격이면 새 세션
- LAG() + SUM() OVER() 방식

2단계: 세션별 통계 집계
- session_number, user_id, 세션 시작 시각, 세션 종료 시각
- 세션 지속 시간(분), 세션 내 이벤트 수

각 단계를 별도 CTE로 분리. 한국어 주석.
```

**검증 포인트**:
- [ ] 첫 이벤트의 prev_event_date가 NULL이고 새 세션(1)으로 처리되는지
- [ ] user_id가 바뀌면 session_number가 초기화되는지 (PARTITION BY user_id)

### 실습 SQL 3. 퍼널 전환율 分析

**목표**: 5단계 퍼널 각 단계 도달 수, 전환율

**프롬프트**:
```
PostgreSQL. events(user_id, event_name, event_date) 기준 퍼널 分析.

퍼널 단계 (순서 무관, 해당 이벤트를 경험한 unique user_id 수):
1. 'landing_view'
2. 'signup_start'
3. 'signup_complete'
4. 'trial_start'
5. 'subscription_start'

기간: 2024-01-01 ~ 2024-03-31
결과 컬럼: step, event_name, users, 직전 단계 대비 전환율(%), 1단계 대비 누적 전환율(%)
```

**검증 포인트**:
- [ ] 각 단계가 이전 단계보다 많을 수 없음 (퍼널 특성상 단조 감소해야 함)
- [ ] 전환율이 0~100% 범위인지

### 실습 SQL 4. RFM 세그먼테이션

**목표**: 사용자를 RFM 기준으로 4개 세그먼트로 분류

**프롬프트**:
```
PostgreSQL. payments(user_id, amount, paid_at) 기준 RFM 분析.
기준일: '2024-04-01'

- R (Recency): 기준일 - MAX(paid_at) 일수
- F (Frequency): 결제 횟수 COUNT(*)
- M (Monetary): 총 결제 금액 SUM(amount)

각 지표를 NTILE(5)로 1~5점 스코어링 (R은 작을수록 높은 점수 주의).
RFM 합산 점수 기준 세그먼트:
- Champions: 13~15점
- Loyal: 10~12점
- At Risk: 6~9점
- Lost: 3~5점

세그먼트별 사용자 수, 평균 금액, 평균 빈도 출력.
```

**검증 포인트**:
- [ ] R 스코어링 방향 확인: Recency 일수가 **작을수록(최근)** 높은 점수여야 함
  → `NTILE(5) OVER (ORDER BY recency_days ASC)` = 1이 가장 최근
  → 하지만 우리는 점수가 높을수록 좋으므로 `6 - NTILE(5) OVER (ORDER BY recency_days ASC)` 또는 `NTILE(5) OVER (ORDER BY recency_days DESC)` 확인

### 실습 SQL 5. MRR 분解 (Waterfall)

**목표**: 월별 MRR 변동을 New / Expansion / Contraction / Churn 으로 분解

**프롬프트**:
```
PostgreSQL. subscriptions(user_id, event_type, plan, event_date, mrr) 기준 월별 MRR 분解.

event_type 별 MRR 기여:
- 'subscribe' (최초): New MRR
- 'upgrade': Expansion MRR (증가분 = 현재 mrr - 이전 mrr)
- 'downgrade': Contraction MRR (감소분, 음수로)
- 'cancel': Churn MRR (이탈 시점의 mrr, 음수로)

Net New MRR = New + Expansion + Contraction + Churn
결과: year_month, new_mrr, expansion_mrr, contraction_mrr, churn_mrr, net_new_mrr, 전월 대비 변화율(%)
```

**검증 포인트**:
- [ ] upgrade/downgrade의 MRR 차이 계산에 LAG()를 올바르게 사용하는지
- [ ] churn_mrr과 contraction_mrr이 음수로 표현되는지

---

## 핵심 포인트

1. **Window Function**: `GROUP BY`는 행을 지우지만, Window Function은 행을 유지하면서 집계. `OVER(PARTITION BY ... ORDER BY ...)` 구조.
2. **ROW_NUMBER**: 순번 부여 및 중복 제거. **LAG/LEAD**: 이전/다음 행 참조 (세션 분析, 전월 비교). **RANK**: 동점 처리가 필요한 순위.
3. **CTE(WITH 절)**: 복잡한 쿼리를 단계별로 분解. 안에서 밖으로 읽는 서브쿼리와 달리 위에서 아래로 읽음.
4. **LEFT JOIN 습관화**: 결제/이벤트 없는 사용자도 포함해야 할 경우가 대부분. JOIN 전후 행 수 비교는 기본 검증.
5. **방언 명시**: PostgreSQL / BigQuery / Snowflake에서 DATE_TRUNC, 날짜 연산 문법이 다름. Copilot 프롬프트에 반드시 명시.

---

**다음 챕터**: [03-data-cleaning.md](./03-data-cleaning.md) — 데이터 클리닝: 결측치/이상치/중복 처리
