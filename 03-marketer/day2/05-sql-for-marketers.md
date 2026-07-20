# 05. 마케터용 SQL 20패턴

## 학습 목표

- 마케터가 실무에서 가장 자주 쓰는 SQL 20개 패턴을 Copilot으로 생성·검증
- GA/광고 데이터 스키마 구조를 이해하고 JOIN 최소 필요분 파악
- GROUP BY 집계, 코호트 분석 기초, 어트리뷰션 SQL 작성
- read-only 환경에서 안전하게 쿼리 실행하는 습관 체득

**예상 소요**: 75~90분

---

## 5.1 마케터가 SQL을 배워야 하는 이유

"SQL은 개발자나 데이터 팀이 하는 거 아닌가요?"

맞습니다. 그런데 지금 이 상황을 생각해보세요.

```
월요일 오전 9시.
팀장이 "지난주 채널별 ROAS가 왜 이렇게 차이 나는지 오전 중으로 파악해줘"라고 합니다.
개발팀장은 휴가 중입니다.
데이터 팀은 다른 프로젝트로 바쁩니다.
BI 대시보드에는 원하는 분류가 없습니다.
```

Copilot + SQL 기본기가 있으면, 직접 DB에서 10분 안에 답을 뽑을 수 있습니다.

**마케터에게 SQL이 필요한 이유**
- BI 도구가 없거나 원하는 segmentation이 없을 때
- 개발팀 요청 → 대기 시간을 없애고 싶을 때
- 광고 API 데이터와 내부 주문 데이터를 조합해서 봐야 할 때
- 정확한 수치로 성과를 증명해야 할 때

---

## 5.2 마케터가 아는 것으로 충분한 SQL 구조

SQL 전체를 배울 필요 없습니다. 마케터에게 필요한 건 이 4가지 구조가 전부입니다.

```sql
-- 기본 구조
SELECT   원하는 열들
FROM     테이블명
WHERE    조건 (기간, 채널, 상태 등)
GROUP BY 묶을 기준
ORDER BY 정렬 기준 DESC
LIMIT    10;

-- JOIN: 두 테이블 연결
SELECT a.열, b.열
FROM   테이블A a
JOIN   테이블B b ON a.공통키 = b.공통키
WHERE  조건;

-- 집계 함수
COUNT(*)        -- 행 수 세기
SUM(열)         -- 합계
AVG(열)         -- 평균
MAX(열)         -- 최대값
MIN(열)         -- 최소값
ROUND(값, 자리) -- 반올림
```

**Copilot 활용 원칙**: 여러분은 "무엇을 알고 싶은지"만 말하면 됩니다. 위 문법은 Copilot이 채웁니다. 단, **결과는 반드시 직접 검증**하세요.

---

## 5.3 마케터용 광고/주문 데이터 스키마

Copilot에게 쿼리를 요청할 때 테이블 구조를 먼저 알려줘야 합니다. 회사 DB의 실제 스키마를 파악하는 것이 첫 번째 숙제입니다. 이 커리큘럼에서는 아래 공통 스키마를 사용합니다.

```sql
-- 광고 성과 테이블
ad_performance (
  id              INT,
  campaign_id     VARCHAR(20),
  campaign_name   VARCHAR(100),
  channel         VARCHAR(30),   -- 'facebook', 'google', 'naver', 'kakao'
  ad_set_name     VARCHAR(100),
  date            DATE,
  impressions     INT,
  clicks          INT,
  cost            DECIMAL(12,2),  -- 원 단위
  conversions     INT,
  revenue         DECIMAL(12,2)
)

-- 주문 테이블
orders (
  id              INT,
  order_id        VARCHAR(30),
  customer_id     VARCHAR(30),
  product_id      VARCHAR(20),
  product_name    VARCHAR(100),
  category        VARCHAR(50),
  amount          DECIMAL(12,2),
  quantity        INT,
  channel         VARCHAR(30),   -- 유입 채널 (라스트터치)
  created_at      TIMESTAMP
)

-- 고객 테이블
customers (
  id              VARCHAR(30),
  email           VARCHAR(100),  -- 개인정보 — 쿼리에서 노출 최소화
  signup_date     DATE,
  plan            VARCHAR(20),
  country         VARCHAR(10)
)

-- 상품 테이블
products (
  id              VARCHAR(20),
  name            VARCHAR(100),
  category        VARCHAR(50),
  price           DECIMAL(12,2),
  cost_price      DECIMAL(12,2)
)
```

---

## 5.4 SQL 20패턴 (Copilot 프롬프트 포함)

### 패턴 1. 기간별 일별 매출

```
PostgreSQL 쿼리:
테이블: orders (id, customer_id, amount, created_at, channel)
목표: 최근 30일 일별 총매출 + 주문건수
결과: date, total_revenue, order_count
정렬: date DESC
```

```sql
SELECT
  DATE(created_at) AS date,
  SUM(amount)      AS total_revenue,
  COUNT(*)         AS order_count
FROM orders
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

---

### 패턴 2. 채널별 매출 + ROAS

```
PostgreSQL 쿼리:
ad_performance와 orders 두 테이블 사용.
목표: 지난 주 채널별 광고비 vs 매출 → ROAS 계산
결과: channel, total_cost, total_revenue, roas
ROAS = total_revenue / total_cost * 100 (%)
```

```sql
SELECT
  a.channel,
  SUM(a.cost)        AS total_cost,
  SUM(o_agg.revenue) AS total_revenue,
  ROUND(SUM(o_agg.revenue) / NULLIF(SUM(a.cost), 0) * 100, 2) AS roas
FROM ad_performance a
LEFT JOIN (
  SELECT channel, SUM(amount) AS revenue
  FROM orders
  WHERE created_at >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '7 days'
    AND created_at <  DATE_TRUNC('week', CURRENT_DATE)
  GROUP BY channel
) o_agg ON a.channel = o_agg.channel
WHERE a.date >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '7 days'
  AND a.date <  DATE_TRUNC('week', CURRENT_DATE)
GROUP BY a.channel
ORDER BY roas DESC;
```

---

### 패턴 3. 캠페인별 CPA

```
PostgreSQL 쿼리:
테이블: ad_performance (campaign_name, cost, conversions)
목표: 캠페인별 CPA (Cost Per Acquisition)
CPA = 총 광고비 / 총 전환수
conversions = 0인 캠페인은 CPA를 NULL로 표시
기간: 이번 달
```

```sql
SELECT
  campaign_name,
  SUM(cost)                                        AS total_cost,
  SUM(conversions)                                 AS total_conversions,
  ROUND(SUM(cost) / NULLIF(SUM(conversions), 0), 0) AS cpa
FROM ad_performance
WHERE date >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY campaign_name
ORDER BY cpa ASC NULLS LAST;
```

---

### 패턴 4. 채널별 CTR

```
PostgreSQL 쿼리:
테이블: ad_performance
목표: 채널별 평균 CTR (클릭수/노출수 × 100)
기간: 최근 7일
CTR 소수점 2자리
```

```sql
SELECT
  channel,
  SUM(impressions)                                             AS total_impressions,
  SUM(clicks)                                                  AS total_clicks,
  ROUND(SUM(clicks) * 100.0 / NULLIF(SUM(impressions), 0), 2) AS ctr
FROM ad_performance
WHERE date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY channel
ORDER BY ctr DESC;
```

---

### 패턴 5. 상품 카테고리별 매출

```
PostgreSQL 쿼리:
테이블: orders + products (JOIN 사용)
목표: 이번 달 카테고리별 매출 합계, 주문건수, 평균 주문가
JOIN: orders.product_id = products.id
```

```sql
SELECT
  p.category,
  COUNT(o.id)     AS order_count,
  SUM(o.amount)   AS total_revenue,
  ROUND(AVG(o.amount), 0) AS avg_order_value
FROM orders o
JOIN products p ON o.product_id = p.id
WHERE o.created_at >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY p.category
ORDER BY total_revenue DESC;
```

---

### 패턴 6. 매출 상위 10개 상품

```
PostgreSQL 쿼리:
테이블: orders + products
목표: 지난 달 매출 합계 기준 상위 10개 상품
결과: 상품명, 카테고리, 판매건수, 총매출
```

```sql
SELECT
  p.name          AS product_name,
  p.category,
  COUNT(o.id)     AS order_count,
  SUM(o.amount)   AS total_revenue
FROM orders o
JOIN products p ON o.product_id = p.id
WHERE o.created_at >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
  AND o.created_at <  DATE_TRUNC('month', CURRENT_DATE)
GROUP BY p.name, p.category
ORDER BY total_revenue DESC
LIMIT 10;
```

---

### 패턴 7. 신규 vs 재구매 고객 비율

```
PostgreSQL 쿼리:
테이블: orders
목표: 이번 달 주문 중 첫 구매 고객(신규) vs 재구매 고객 비율
신규: customer_id가 이번 달 이전에 주문 이력이 없는 경우
```

```sql
WITH this_month_orders AS (
  SELECT DISTINCT customer_id
  FROM orders
  WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)
),
returning_customers AS (
  SELECT DISTINCT o.customer_id
  FROM orders o
  JOIN this_month_orders t ON o.customer_id = t.customer_id
  WHERE o.created_at < DATE_TRUNC('month', CURRENT_DATE)
)
SELECT
  COUNT(t.customer_id)                        AS total_buyers,
  COUNT(r.customer_id)                        AS returning_buyers,
  COUNT(t.customer_id) - COUNT(r.customer_id) AS new_buyers,
  ROUND(COUNT(r.customer_id) * 100.0 / COUNT(t.customer_id), 1) AS returning_rate
FROM this_month_orders t
LEFT JOIN returning_customers r ON t.customer_id = r.customer_id;
```

---

### 패턴 8. 고객 생애 첫 구매 채널 분포

```
PostgreSQL 쿼리:
테이블: orders
목표: 신규 고객의 첫 구매 유입 채널 분포 (이번 달 신규 기준)
신규 = customer_id의 가장 빠른 created_at이 이번 달에 속하는 경우
```

```sql
WITH first_orders AS (
  SELECT
    customer_id,
    channel,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_at ASC) AS rn
  FROM orders
)
SELECT
  channel,
  COUNT(*) AS new_customers
FROM first_orders
WHERE rn = 1
  AND customer_id IN (
    SELECT customer_id
    FROM orders
    GROUP BY customer_id
    HAVING MIN(created_at) >= DATE_TRUNC('month', CURRENT_DATE)
  )
GROUP BY channel
ORDER BY new_customers DESC;
```

---

### 패턴 9. 월별 코호트 재구매율 (기초)

```
PostgreSQL 쿼리:
테이블: orders
목표: 첫 구매 월별 코호트가 이후 달에 얼마나 재구매했는지
결과: cohort_month, months_later, cohort_size, returning_count, retention_rate
DB: PostgreSQL (DATE_TRUNC, WITH 사용)
주석 포함.
```

```sql
-- 각 고객의 첫 구매 월 추출
WITH first_purchase AS (
  SELECT
    customer_id,
    DATE_TRUNC('month', MIN(created_at)) AS cohort_month
  FROM orders
  GROUP BY customer_id
),
-- 각 주문에 코호트 월과 경과 개월수 붙이기
cohort_activity AS (
  SELECT
    f.cohort_month,
    o.customer_id,
    -- 경과 개월수 계산
    EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', o.created_at), f.cohort_month)) * 12
    + EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', o.created_at), f.cohort_month))
      AS months_later
  FROM orders o
  JOIN first_purchase f ON o.customer_id = f.customer_id
)
-- 코호트별 집계
SELECT
  cohort_month,
  months_later,
  COUNT(DISTINCT customer_id) AS active_customers,
  -- 코호트 원래 크기 대비 재구매율
  ROUND(
    COUNT(DISTINCT customer_id) * 100.0 /
    FIRST_VALUE(COUNT(DISTINCT customer_id)) OVER (
      PARTITION BY cohort_month ORDER BY months_later
    ), 1
  ) AS retention_rate
FROM cohort_activity
GROUP BY cohort_month, months_later
ORDER BY cohort_month, months_later;
```

---

### 패턴 10. 이탈 위험 고객 찾기

```
PostgreSQL 쿼리:
테이블: orders
목표: 재구매 이탈 위험 고객 목록
로직:
- 2회 이상 구매한 고객 중
- 마지막 구매일이 평균 구매 간격의 2배 이상 지난 고객
결과: customer_id, last_order_date, avg_days_between, days_since_last
```

```sql
WITH purchase_gaps AS (
  SELECT
    customer_id,
    created_at,
    LAG(created_at) OVER (PARTITION BY customer_id ORDER BY created_at) AS prev_order,
    COUNT(*) OVER (PARTITION BY customer_id) AS total_orders
  FROM orders
),
customer_stats AS (
  SELECT
    customer_id,
    MAX(created_at)                                   AS last_order_date,
    AVG(EXTRACT(DAY FROM created_at - prev_order))    AS avg_days_between,
    COUNT(*)                                          AS order_count
  FROM purchase_gaps
  WHERE prev_order IS NOT NULL
    AND total_orders >= 2
  GROUP BY customer_id
)
SELECT
  customer_id,
  last_order_date,
  ROUND(avg_days_between, 0)                              AS avg_days_between,
  CURRENT_DATE - last_order_date::date                    AS days_since_last
FROM customer_stats
WHERE (CURRENT_DATE - last_order_date::date) > avg_days_between * 2
ORDER BY days_since_last DESC
LIMIT 100;
```

---

### 패턴 11~20. Copilot으로 직접 생성하기

아래 요구사항들은 Copilot Chat에 직접 입력해서 쿼리를 생성하는 실습용입니다. 위에서 배운 스키마를 참고하세요.

**패턴 11. 주간 성과 요약 (전주 대비 증감)**
```
PostgreSQL 쿼리.
ad_performance 테이블 사용.
이번 주 vs 전주 채널별 성과 비교.
결과: channel, 이번주_cost, 전주_cost, 비용_증감률(%), 이번주_roas, 전주_roas
```

**패턴 12. 가장 많이 함께 구매되는 상품 조합**
```
PostgreSQL 쿼리.
orders 테이블에서 같은 customer_id가 같은 날 구매한 상품 조합 집계.
결과: product_a, product_b, pair_count
상위 10개.
```

**패턴 13. 일별 전환율 추이**
```
PostgreSQL 쿼리.
ad_performance 테이블.
일별 전환율 = conversions / clicks × 100
최근 14일 추이.
결과: date, channel, conversion_rate
```

**패턴 14. 할인 효과 분석**
```
PostgreSQL 쿼리.
orders 테이블에 discount_amount 컬럼 있다고 가정.
할인 주문 vs 정가 주문: 평균 주문가, 재구매율 비교.
```

**패턴 15. 시간대별 주문 패턴**
```
PostgreSQL 쿼리.
orders 테이블.
EXTRACT(HOUR FROM created_at)으로 시간대별 주문 건수 집계.
결과: hour, order_count, avg_amount
```

**패턴 16. 고객 LTV(생애가치) 근사 계산**
```
PostgreSQL 쿼리.
orders 테이블.
고객별 총 구매금액 + 구매횟수 + 첫구매~마지막구매 기간(일)
결과: customer_id, total_amount, order_count, customer_lifespan_days
상위 100명.
```

**패턴 17. 광고비 대비 매출 일별 추이**
```
PostgreSQL 쿼리.
ad_performance와 orders 테이블.
일별 총 광고비와 총 주문 매출.
결과: date, total_ad_cost, total_revenue, daily_roas
최근 30일.
```

**패턴 18. 재구매 주기 분포**
```
PostgreSQL 쿼리.
orders 테이블.
2회 이상 구매 고객의 재구매 간격(일) 분포.
결과: days_range, customer_count (예: 0-7일, 8-14일, 15-30일, 31-60일, 60일+)
```

**패턴 19. 채널별 신규 고객 획득 비용(CAC)**
```
PostgreSQL 쿼리.
ad_performance + orders 테이블.
신규 고객(첫 구매 이번 달) 채널별 CAC = 채널 광고비 / 신규 고객 수.
```

**패턴 20. 지역별 매출 (orders에 region 컬럼 있다고 가정)**
```
PostgreSQL 쿼리.
orders 테이블 (region 컬럼 추가 가정).
지역별 매출 합계, 주문건수, 평균 주문가.
```

---

## 5.5 SQL 작성 시 개인정보 주의사항

마케터가 SQL을 쓸 때 가장 많이 실수하는 부분입니다.

| 주의 상황 | 올바른 처리 |
|-----------|------------|
| SELECT * FROM customers | 필요한 컬럼만 명시 (email, phone 제외) |
| 실제 이메일 주소를 WHERE 조건에 | customer_id로 대체 |
| 쿼리 결과를 공용 슬랙에 공유 | 개인 식별 정보 제거 후 공유 |
| Copilot 프롬프트에 실제 데이터 입력 | 스키마 구조만 입력, 실제 데이터 행 금지 |
| SELECT email, phone FROM customers | 이메일·전화번호 포함 결과는 암호화 처리 |

---

## 실습: 매출/유입 SQL 5개 작성

### 준비

1. `sales-queries.sql` 파일 생성
2. 파일 상단에 스키마 주석 붙여넣기 (5.3절 참고)

### 과제

아래 5개 쿼리를 Copilot으로 생성하고 검증하세요.

**쿼리 1. 지난 주 채널별 성과 요약**

```
ad_performance 테이블.
지난 주(월~일) 채널별:
- 총 노출, 클릭, CTR, 광고비, 전환, ROAS, CPA
정렬: ROAS 내림차순
소수점 처리: CTR 소수점 2자리, ROAS 소수점 1자리
```

**쿼리 2. 이번 달 상위 5개 캠페인**

```
ad_performance 테이블.
이번 달 전환 기준 상위 5개 캠페인.
결과: campaign_name, channel, total_conversions, total_cost, cpa
```

**쿼리 3. 재구매율이 가장 높은 채널**

```
orders 테이블.
채널별 재구매 고객 비율 (2회 이상 구매 고객 / 전체 구매 고객).
결과: channel, total_buyers, returning_buyers, repeat_rate
```

**쿼리 4. 최근 30일 일별 매출 추이**

```
orders 테이블.
일별 매출 합계 + 주문건수 + 평균 주문가.
날짜 누락 없이 (주문 없는 날도 0으로 표시하려면 generate_series 활용).
```

**쿼리 5. 고가 고객(VIP) 세그먼트**

```
orders 테이블.
최근 90일 총 구매금액 기준 상위 10% 고객.
결과: customer_id, total_amount, order_count, first_order_date, last_order_date
(email 컬럼은 포함하지 말 것 — 개인정보)
```

### 생성 후 검증 체크리스트

```
위 5개 SQL 쿼리에서 다음을 확인해줘:
1. 실행 시 에러 가능성 있는 문법 (날짜 함수, NULL 처리 등)
2. 성능 문제 가능성 (전체 테이블 풀 스캔, 불필요한 서브쿼리 등)
3. 결과가 의도와 다를 수 있는 로직 오류
4. 개인정보 컬럼 노출 여부
각 항목별로 발견된 문제와 수정 제안.
```

---

## 핵심 포인트

1. **스키마를 먼저 알려줘라** — Copilot은 테이블 구조를 알아야 정확한 쿼리를 씀
2. **NULLIF()는 0 나누기 방지 필수** — 전환 0건인 캠페인에서 CPA 계산 오류 방지
3. **WITH(CTE) 활용** — 복잡한 쿼리를 단계별로 나누면 읽기 쉽고 디버깅도 쉬움
4. **read-only 계정으로만 실행** — SELECT 쿼리라도 실수로 무거운 쿼리가 운영 DB에 부하 줄 수 있음
5. **개인정보 컬럼은 SELECT에서 제외** — email, phone은 필요할 때만, 결과 공유 시 반드시 제거

---

**다음**: [06-ga-events-tagging.md](./06-ga-events-tagging.md) — GA4 이벤트 태깅 설계
