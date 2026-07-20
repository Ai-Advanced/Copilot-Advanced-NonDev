# 05. 재무용 SQL 20개 패턴

## 학습 목표

- 재무/회계 실무에서 반복되는 **SQL 쿼리 20개 패턴** 습득
- Copilot으로 SQL을 생성하고 **검증하는 방법** 체득
- 매출/원가/판관비 집계, 기간 비교(YoY/QoQ), 환율 조인, 재무제표 뽑기 실전 적용
- 실습: 손익계산서(P&L) SQL 5개 완성

**예상 소요**: 60분 (실습 포함)

---

## 5.1 재무 SQL의 특징

일반 데이터 분석 SQL과 다르게, 재무 SQL에는 몇 가지 특수한 요구사항이 있습니다.

| 특징 | 이유 | 주의 사항 |
|------|------|---------|
| 정확한 숫자 | 1원 오차도 감사 지적 | ROUND 함수 정책 통일 |
| 기간 경계 명확 | 기말 vs 기초 구분 | `< 다음날` 패턴 사용 |
| 차변/대변 구분 | 잔액 방향이 계정마다 다름 | account_type 기준 부호 처리 |
| 전기 비교 | YoY, QoQ 필수 | 같은 기간 정의 일관성 |
| 환율 적용 | 외화 거래 원화 환산 | 고시 환율 날짜 기준 명확히 |

### Copilot SQL 프롬프트 기본 패턴

```
SQL 쿼리 작성. [DB 방언: PostgreSQL / MySQL / MS SQL / Oracle].

테이블:
- [테이블명]([컬럼1 타입, 컬럼2 타입, ...])
- [테이블명2]([컬럼 목록])

목표: [무엇을 조회할 것인가 - 구체적으로]

결과 컬럼: [컬럼명 목록]
조건: [WHERE 절 조건들]
정렬: [ORDER BY 기준]
추가 요구: [ROUND, NULL 처리, 합계 행 등]
```

맥락이 풍부할수록 쿼리 품질이 높아집니다. **테이블 스키마는 반드시 포함**하세요.

---

## 5.2 매출 / 원가 집계 패턴

### 패턴 1. 월별 매출 집계

가장 기본적인 패턴입니다.

```sql
-- 월별 매출 집계
SELECT
    DATE_TRUNC('month', entry_date) AS month,
    SUM(credit - debit)             AS revenue
FROM gl_entries
WHERE account_code LIKE '4%'           -- 수익 계정 (4xxx)
  AND entry_date >= '2026-01-01'
  AND entry_date  < '2027-01-01'
GROUP BY DATE_TRUNC('month', entry_date)
ORDER BY month;
```

**Copilot 프롬프트**:
```
PostgreSQL 쿼리 작성.

테이블: gl_entries(entry_date DATE, account_code VARCHAR, debit NUMERIC, credit NUMERIC)
account_type: 수익 계정은 코드가 '4'로 시작, 비용은 '5'로 시작

목표: 2026년 월별 매출(수익) 집계
결과: 월(YYYY-MM 형식), 매출액 (credit - debit)
정렬: 월 오름차순
0원인 월도 표시 (generate_series로 빈 월 채우기)
```

### 패턴 2. 계정과목별 잔액 (시산표 형태)

```sql
-- 계정별 차변/대변 합계와 잔액
SELECT
    e.account_code,
    m.account_name,
    m.account_type,
    SUM(e.debit)  AS total_debit,
    SUM(e.credit) AS total_credit,
    CASE
        WHEN m.account_type IN ('asset', 'expense')
            THEN SUM(e.debit) - SUM(e.credit)
        ELSE
            SUM(e.credit) - SUM(e.debit)
    END           AS balance
FROM gl_entries e
JOIN account_master m ON e.account_code = m.account_code
WHERE e.entry_date >= '2026-01-01'
  AND e.entry_date  < '2026-07-01'
GROUP BY e.account_code, m.account_name, m.account_type
ORDER BY e.account_code;
```

### 패턴 3. 원가율 계산

```sql
-- 월별 매출원가율
SELECT
    TO_CHAR(DATE_TRUNC('month', entry_date), 'YYYY-MM') AS month,
    SUM(CASE WHEN account_code LIKE '4%' THEN credit - debit ELSE 0 END) AS revenue,
    SUM(CASE WHEN account_code = '5200'  THEN debit - credit ELSE 0 END) AS cogs,
    CASE
        WHEN SUM(CASE WHEN account_code LIKE '4%' THEN credit - debit ELSE 0 END) = 0
            THEN NULL
        ELSE ROUND(
            SUM(CASE WHEN account_code = '5200' THEN debit - credit ELSE 0 END)
            / SUM(CASE WHEN account_code LIKE '4%' THEN credit - debit ELSE 0 END)
            * 100,
            1
        )
    END AS cogs_ratio_pct
FROM gl_entries
WHERE entry_date >= '2026-01-01'
  AND entry_date  < '2027-01-01'
GROUP BY DATE_TRUNC('month', entry_date)
ORDER BY month;
```

**Copilot 함정**: 원가율 계산 시 분모(매출)가 0인 경우를 처리하지 않으면 Division by Zero 오류.
반드시 `NULLIF` 또는 `CASE WHEN` 으로 처리하도록 프롬프트에 명시하세요.

---

## 5.3 계정과목 롤업 (그룹 집계)

재무제표는 개별 계정이 아닌 **계정 그룹**으로 표시됩니다.

### 패턴 4. 손익계산서 구조 집계

```sql
-- 손익계산서 항목별 집계
SELECT
    m.pl_category,
    m.pl_order,
    SUM(
        CASE
            WHEN m.account_type = 'revenue'  THEN e.credit - e.debit
            WHEN m.account_type = 'expense'  THEN e.debit  - e.credit
            ELSE 0
        END
    ) AS amount
FROM gl_entries e
JOIN account_master m ON e.account_code = m.account_code
WHERE e.entry_date >= '2026-01-01'
  AND e.entry_date  < '2026-07-01'
  AND m.pl_category IS NOT NULL
GROUP BY m.pl_category, m.pl_order
ORDER BY m.pl_order;
```

### 패턴 5. ROLLUP으로 소계/합계 자동 생성

```sql
-- 부문별 P&L with 소계
SELECT
    COALESCE(d.division_name, '합계')  AS division,
    COALESCE(m.pl_category, '소계')    AS category,
    SUM(
        CASE
            WHEN m.account_type = 'revenue' THEN e.credit - e.debit
            ELSE e.debit - e.credit
        END
    ) AS amount
FROM gl_entries e
JOIN account_master m ON e.account_code = m.account_code
JOIN dept_master d    ON e.dept_code    = d.dept_code
WHERE e.entry_date >= '2026-04-01'
  AND e.entry_date  < '2026-07-01'
GROUP BY ROLLUP(d.division_name, m.pl_category)
ORDER BY d.division_name NULLS LAST, m.pl_category NULLS LAST;
```

**Copilot 프롬프트**:
```
PostgreSQL 쿼리 작성.

테이블:
- gl_entries(entry_date, account_code, dept_code, debit NUMERIC, credit NUMERIC)
- account_master(account_code, account_name, account_type, pl_category, pl_order)
  account_type: 'revenue' | 'cogs' | 'sg_and_a' | 'other'
- dept_master(dept_code, dept_name, division_name)

목표: 2026년 상반기 손익계산서 (부문별 + 전체 합계)

구조:
1. 매출 (account_type = 'revenue')
2. 매출원가 (account_type = 'cogs')
3. 매출총이익 = 1 - 2
4. 판관비 (account_type = 'sg_and_a')
5. 영업이익 = 3 - 4

결과: division_name, pl_category, 금액
ROLLUP으로 부문별 소계 + 전체 합계 포함.
금액은 원 단위 정수 (ROUND(..., 0)).
```

---

## 5.4 부문별 손익 집계

### 패턴 6. 부문별 P&L 피벗

```sql
-- 부문별 손익 (행: P&L 항목, 열: 부문)
SELECT
    m.pl_category,
    SUM(CASE WHEN d.division_name = '영업본부'  THEN
        CASE WHEN m.account_type = 'revenue' THEN e.credit - e.debit
             ELSE e.debit - e.credit END ELSE 0 END) AS "영업본부",
    SUM(CASE WHEN d.division_name = '제조본부'  THEN
        CASE WHEN m.account_type = 'revenue' THEN e.credit - e.debit
             ELSE e.debit - e.credit END ELSE 0 END) AS "제조본부",
    SUM(CASE WHEN d.division_name = '관리본부'  THEN
        CASE WHEN m.account_type = 'revenue' THEN e.credit - e.debit
             ELSE e.debit - e.credit END ELSE 0 END) AS "관리본부",
    SUM(
        CASE WHEN m.account_type = 'revenue' THEN e.credit - e.debit
             ELSE e.debit - e.credit END
    ) AS "합계"
FROM gl_entries e
JOIN account_master m ON e.account_code = m.account_code
JOIN dept_master d    ON e.dept_code    = d.dept_code
WHERE e.entry_date >= '2026-01-01'
  AND e.entry_date  < '2026-07-01'
GROUP BY m.pl_category, m.pl_order
ORDER BY m.pl_order;
```

### 패턴 7. 부문별 비용 구조 분석

```sql
-- 각 부문의 비용 항목별 비중
WITH dept_totals AS (
    SELECT
        d.division_name,
        SUM(e.debit - e.credit) AS total_cost
    FROM gl_entries e
    JOIN account_master m ON e.account_code = m.account_code
    JOIN dept_master d    ON e.dept_code    = d.dept_code
    WHERE m.account_type != 'revenue'
      AND e.entry_date >= '2026-01-01'
      AND e.entry_date  < '2026-07-01'
    GROUP BY d.division_name
)
SELECT
    d.division_name,
    m.pl_category,
    SUM(e.debit - e.credit)                                 AS amount,
    dt.total_cost,
    ROUND(SUM(e.debit - e.credit) / NULLIF(dt.total_cost, 0) * 100, 1) AS pct
FROM gl_entries e
JOIN account_master m ON e.account_code = m.account_code
JOIN dept_master d    ON e.dept_code    = d.dept_code
JOIN dept_totals dt   ON d.division_name = dt.division_name
WHERE m.account_type != 'revenue'
  AND e.entry_date >= '2026-01-01'
  AND e.entry_date  < '2026-07-01'
GROUP BY d.division_name, m.pl_category, dt.total_cost
ORDER BY d.division_name, amount DESC;
```

---

## 5.5 기간 비교 (YoY / QoQ)

### 패턴 8. 전년 동기 비교 (YoY)

```sql
-- 월별 매출 YoY 비교
SELECT
    TO_CHAR(curr.month, 'YYYY-MM')                             AS month,
    curr.revenue                                               AS curr_revenue,
    prev.revenue                                               AS prev_revenue,
    curr.revenue - prev.revenue                                AS diff,
    ROUND(
        (curr.revenue - prev.revenue)
        / NULLIF(prev.revenue, 0) * 100,
        1
    )                                                          AS growth_pct
FROM (
    SELECT DATE_TRUNC('month', entry_date) AS month,
           SUM(credit - debit)             AS revenue
    FROM gl_entries
    WHERE account_code LIKE '4%'
      AND entry_date >= '2026-01-01'
      AND entry_date  < '2027-01-01'
    GROUP BY DATE_TRUNC('month', entry_date)
) curr
LEFT JOIN (
    SELECT DATE_TRUNC('month', entry_date)             AS month,
           SUM(credit - debit)                         AS revenue
    FROM gl_entries
    WHERE account_code LIKE '4%'
      AND entry_date >= '2025-01-01'
      AND entry_date  < '2026-01-01'
    GROUP BY DATE_TRUNC('month', entry_date)
) prev
  ON curr.month = prev.month + INTERVAL '1 year'
ORDER BY curr.month;
```

### 패턴 9. 분기 비교 (QoQ)

```sql
-- 분기별 영업이익 QoQ
WITH quarterly AS (
    SELECT
        DATE_PART('year', entry_date)                         AS yr,
        DATE_PART('quarter', entry_date)                      AS qtr,
        SUM(
            CASE WHEN account_code LIKE '4%' THEN credit - debit
                 WHEN account_code LIKE '5%' THEN -(debit - credit)
                 ELSE 0 END
        ) AS op_income
    FROM gl_entries
    GROUP BY DATE_PART('year', entry_date),
             DATE_PART('quarter', entry_date)
)
SELECT
    yr,
    qtr,
    op_income,
    LAG(op_income) OVER (ORDER BY yr, qtr)  AS prev_qtr_income,
    op_income - LAG(op_income) OVER (ORDER BY yr, qtr) AS qoq_diff,
    ROUND(
        (op_income - LAG(op_income) OVER (ORDER BY yr, qtr))
        / NULLIF(ABS(LAG(op_income) OVER (ORDER BY yr, qtr)), 0) * 100,
        1
    ) AS qoq_pct
FROM quarterly
ORDER BY yr, qtr;
```

**Copilot 프롬프트**:
```
PostgreSQL 쿼리 작성.

테이블: gl_entries(entry_date DATE, account_code VARCHAR, debit NUMERIC, credit NUMERIC)
수익 계정: account_code LIKE '4%'
비용 계정: account_code LIKE '5%'

목표: 2025년~2026년 월별 매출, 영업이익 YoY 비교

결과 컬럼:
- 월 (2025-01 ~ 2026-12)
- 당기매출, 전기매출, 매출증감액, 매출증감률(%)
- 당기영업이익, 전기영업이익, 영업이익증감액, 증감률(%)

LAG 윈도우 함수 또는 셀프 JOIN 방식.
증감률 분모 0 처리 (NULLIF).
소수점 1자리.
```

---

## 5.6 환율 조인

### 패턴 10. 거래일 기준 환율 적용

```sql
-- 외화 거래를 거래일 환율로 원화 환산
SELECT
    t.tx_date,
    t.vendor_id,
    t.currency_code,
    t.amount_foreign,
    r.krw_rate,
    ROUND(t.amount_foreign * r.krw_rate) AS amount_krw
FROM transactions t
JOIN exchange_rates r
  ON r.currency_code = t.currency_code
 AND r.rate_date     = t.tx_date
ORDER BY t.tx_date;
```

### 패턴 11. 환율 없는 날은 가장 최근 환율 사용 (윈도우 함수)

```sql
-- 거래일 환율이 없으면 직전 영업일 환율 사용
WITH daily_rates AS (
    SELECT
        rate_date,
        currency_code,
        krw_rate,
        LEAD(rate_date) OVER (
            PARTITION BY currency_code
            ORDER BY rate_date
        ) AS next_rate_date
    FROM exchange_rates
)
SELECT
    t.tx_date,
    t.currency_code,
    t.amount_foreign,
    dr.krw_rate,
    ROUND(t.amount_foreign * dr.krw_rate) AS amount_krw
FROM transactions t
JOIN daily_rates dr
  ON dr.currency_code = t.currency_code
 AND dr.rate_date    <= t.tx_date
 AND (dr.next_rate_date > t.tx_date OR dr.next_rate_date IS NULL)
ORDER BY t.tx_date;
```

**Copilot 프롬프트**:
```
PostgreSQL 쿼리 작성.

테이블:
- fx_transactions(id, tx_date DATE, amount_usd NUMERIC, amount_eur NUMERIC, vendor_id)
- exchange_rates(rate_date DATE, currency_code VARCHAR, krw_rate NUMERIC)

목표: 2026년 1분기 외화 매입(USD, EUR)을 원화로 환산
- USD: tx_date 기준 환율, 없으면 직전 환율 (LATERAL 또는 서브쿼리)
- EUR: 동일
- 원화 환산금액 = ROUND(외화금액 × 환율, 0)

결과: tx_date, vendor_id, USD금액, USD환율, USD원화환산, EUR금액, EUR환율, EUR원화환산, 합계원화
거래처별 월별 집계도 추가 (CTE 방식).
```

---

## 5.7 재무제표 SQL 패턴

### 패턴 12. 손익계산서 (P&L)

```sql
-- 손익계산서 (2026년 상반기)
WITH pl_data AS (
    SELECT
        m.pl_order,
        m.pl_category,
        SUM(
            CASE
                WHEN m.account_type = 'revenue' THEN e.credit - e.debit
                ELSE e.debit - e.credit
            END
        ) AS amount
    FROM gl_entries e
    JOIN account_master m ON e.account_code = m.account_code
    WHERE e.entry_date >= '2026-01-01'
      AND e.entry_date  < '2026-07-01'
      AND m.pl_category IS NOT NULL
    GROUP BY m.pl_order, m.pl_category
),
subtotals AS (
    SELECT pl_order, pl_category, amount FROM pl_data
    UNION ALL
    -- 매출총이익 소계
    SELECT 20, '매출총이익',
        SUM(CASE WHEN pl_order < 20 THEN amount ELSE 0 END)
    FROM pl_data WHERE pl_order < 20
    UNION ALL
    -- 영업이익 소계
    SELECT 40, '영업이익',
        SUM(CASE WHEN pl_order < 20 THEN amount
                 WHEN pl_order BETWEEN 20 AND 39 THEN -amount
                 ELSE 0 END)
    FROM pl_data WHERE pl_order < 40
)
SELECT pl_order, pl_category, amount
FROM subtotals
ORDER BY pl_order;
```

### 패턴 13. 재무상태표 (B/S) 잔액 추출

```sql
-- 재무상태표 계정 잔액 (기초잔액 + 당기 증감)
WITH opening AS (
    SELECT account_code,
           SUM(debit) - SUM(credit) AS opening_balance
    FROM gl_entries
    WHERE entry_date < '2026-01-01'
    GROUP BY account_code
),
current_period AS (
    SELECT account_code,
           SUM(debit)  AS period_debit,
           SUM(credit) AS period_credit
    FROM gl_entries
    WHERE entry_date >= '2026-01-01'
      AND entry_date  < '2026-07-01'
    GROUP BY account_code
)
SELECT
    m.account_code,
    m.account_name,
    m.bs_category,
    COALESCE(o.opening_balance, 0)               AS opening_balance,
    COALESCE(cp.period_debit, 0)                 AS period_debit,
    COALESCE(cp.period_credit, 0)                AS period_credit,
    COALESCE(o.opening_balance, 0)
        + COALESCE(cp.period_debit, 0)
        - COALESCE(cp.period_credit, 0)          AS closing_balance
FROM account_master m
LEFT JOIN opening        o ON m.account_code = o.account_code
LEFT JOIN current_period cp ON m.account_code = cp.account_code
WHERE m.bs_category IS NOT NULL
ORDER BY m.account_code;
```

### 패턴 14. 현금흐름표 (간접법 기초)

```sql
-- 현금 계정 증감 (영업/투자/재무 활동 분류)
SELECT
    m.cf_category,
    m.cf_subcategory,
    SUM(e.debit - e.credit) AS cash_flow
FROM gl_entries e
JOIN account_master m ON e.account_code = m.account_code
WHERE e.entry_date >= '2026-01-01'
  AND e.entry_date  < '2026-07-01'
  AND m.cf_category IS NOT NULL
GROUP BY m.cf_category, m.cf_subcategory, m.cf_order
ORDER BY m.cf_order;
```

---

## 5.8 미수금 / 미지급금 분석

### 패턴 15. 미수금 Aging

```sql
-- 미수금 Aging (기준일: 2026-07-20)
SELECT
    customer_id,
    COUNT(*)                                                  AS invoice_cnt,
    SUM(amount)                                               AS total_amount,
    SUM(CASE WHEN CURRENT_DATE - due_date <= 30  THEN amount ELSE 0 END) AS bucket_0_30,
    SUM(CASE WHEN CURRENT_DATE - due_date BETWEEN 31 AND 60 THEN amount ELSE 0 END) AS bucket_31_60,
    SUM(CASE WHEN CURRENT_DATE - due_date BETWEEN 61 AND 90 THEN amount ELSE 0 END) AS bucket_61_90,
    SUM(CASE WHEN CURRENT_DATE - due_date > 90 THEN amount ELSE 0 END)  AS bucket_over_90,
    MAX(CURRENT_DATE - due_date)                              AS max_overdue_days
FROM receivables
WHERE paid_date IS NULL
GROUP BY customer_id
ORDER BY total_amount DESC;
```

### 패턴 16. 예산 vs 실적 편차

```sql
-- 예산 대비 실적 편차 분석
SELECT
    b.dept_code,
    b.account_code,
    m.account_name,
    b.budget_amount,
    COALESCE(a.actual_amount, 0)                              AS actual_amount,
    COALESCE(a.actual_amount, 0) - b.budget_amount            AS variance,
    ROUND(
        COALESCE(a.actual_amount, 0)
        / NULLIF(b.budget_amount, 0) * 100,
        1
    )                                                         AS achievement_pct
FROM budget b
LEFT JOIN (
    SELECT
        dept_code,
        account_code,
        SUM(debit - credit) AS actual_amount
    FROM gl_entries
    WHERE entry_date >= '2026-01-01'
      AND entry_date  < '2026-07-01'
    GROUP BY dept_code, account_code
) a ON b.dept_code = a.dept_code AND b.account_code = a.account_code
JOIN account_master m ON b.account_code = m.account_code
WHERE b.year = 2026
ORDER BY ABS(COALESCE(a.actual_amount, 0) - b.budget_amount) DESC;
```

---

## 5.9 Copilot SQL 검증 방법

Copilot이 생성한 SQL을 재무 데이터에 실행하기 전에 반드시 검증합니다.

### 검증 단계

**1단계. 구조 검토 (실행 전)**
```
- WHERE 날짜 조건: >= 시작일 AND < 다음날  (시간 포함 처리)
- ROUND 함수: 금액 컬럼에 적용됐는지
- NULLIF / CASE WHEN: 0 나눔 방지 코드 있는지
- LEFT JOIN vs INNER JOIN: 누락 없이 포함해야 할 데이터가 있으면 LEFT JOIN
- GROUP BY 컬럼: SELECT에 있는 비집계 컬럼이 모두 GROUP BY에 포함됐는지
```

**2단계. 소규모 테스트 실행**
```sql
-- 전체 실행 전 건수 확인
SELECT COUNT(*) FROM gl_entries
WHERE entry_date >= '2026-01-01'
AND entry_date < '2026-07-01';

-- 집계 전 샘플 5행 확인
SELECT * FROM gl_entries
WHERE entry_date >= '2026-01-01'
LIMIT 5;
```

**3단계. 결과 교차 검증**
```sql
-- 쿼리 결과 합계와 단순 집계 비교
-- 쿼리 결과:
SELECT SUM(revenue) FROM 쿼리결과;

-- 단순 확인:
SELECT SUM(credit - debit)
FROM gl_entries
WHERE account_code LIKE '4%'
AND entry_date >= '2026-01-01'
AND entry_date < '2026-07-01';
-- 두 값이 같아야 함
```

### Copilot SQL의 자주 나오는 실수

| 실수 | 예시 | 수정 방법 |
|------|------|---------|
| 날짜 경계 오류 | `<= '2026-06-30'` | `< '2026-07-01'` 로 변경 |
| 집계 함수 누락 | GROUP BY 없이 SUM 사용 | GROUP BY 확인 |
| NULL 처리 누락 | LEFT JOIN 후 NULL 합산 오류 | COALESCE(컬럼, 0) 추가 |
| 금액 부호 오류 | 비용을 credit - debit으로 | account_type별 부호 정의 |
| 전체 기간 누락 | 빈 월이 결과에 없음 | generate_series로 날짜 채우기 |

---

## 5.10 실습: P&L SQL 5개 완성

### 실습 환경 설정

DB가 없는 경우, DBeaver의 SQLite 메모리 DB나 VS Code SQLite 확장을 사용합니다.

**Copilot 프롬프트 - DDL 생성**:
```
SQLite 호환 DDL 및 샘플 데이터 생성.

테이블:
1. account_master (account_code TEXT, account_name TEXT, account_type TEXT, pl_category TEXT, pl_order INTEGER)
   데이터: 매출(4000/revenue/매출/10), 매출원가(5200/expense/매출원가/20), 급여(5110/expense/판관비/30), 임차료(5120/expense/판관비/31), 광고선전비(5150/expense/판관비/32)

2. dept_master (dept_code TEXT, dept_name TEXT, division_name TEXT)
   데이터: 4개 부서 (SALES/영업팀/영업본부, MFG/제조팀/제조본부, HR/인사팀/관리본부, ADM/총무팀/관리본부)

3. gl_entries (id INTEGER, entry_date TEXT, account_code TEXT, dept_code TEXT, debit NUMERIC, credit NUMERIC)
   데이터: 2025년~2026년 6월, 200행

CREATE TABLE + INSERT 문 완성. SQLite 문법.
```

### P&L SQL 실습 목록

아래 5개 쿼리를 Copilot으로 생성하고 실행해서 결과를 확인합니다.

**SQL 1. 2026년 상반기 월별 매출 + 영업이익**
```
월별 매출, 매출원가, 매출총이익, 판관비 합계, 영업이익, 영업이익률(%) 조회.
```

**SQL 2. 부문별 매출 구성 (당기 vs 전기)**
```
2026년 상반기 vs 2025년 상반기 부문별 매출 비교.
증감액, 증감률 포함.
```

**SQL 3. 계정과목별 판관비 상세**
```
2026년 상반기 판관비 계정별 금액, 전체 판관비 대비 비중(%).
금액 내림차순 정렬.
```

**SQL 4. 월별 영업이익 YoY (2025 vs 2026)**
```
월별 영업이익 전년 동기 비교. LAG 윈도우 함수 또는 셀프 JOIN.
```

**SQL 5. 손익계산서 완성 (소계 포함)**
```
수익 - 원가 = 매출총이익, 매출총이익 - 판관비 = 영업이익 구조.
UNION ALL로 소계 행 포함.
```

각 SQL 실행 후:
- [ ] 행 수가 예상 범위인가
- [ ] 합계 금액이 단순 SUM 결과와 일치하는가
- [ ] 영업이익 = 매출 - 원가 - 판관비 검증

---

## 핵심 포인트

1. **날짜 조건**: `< 다음날` 패턴이 `<= 마지막날` 보다 안전 (시간 포함 날짜 처리)
2. **부호 처리**: account_type으로 차변/대변 방향을 CASE WHEN으로 명시
3. **NULLIF 필수**: 비율 계산에서 0 나눔 방지
4. **CTE 활용**: 복잡한 P&L은 CTE로 단계를 쌓아 가독성 확보
5. **교차 검증**: 생성된 SQL은 단순 SUM과 항상 비교 검증

---

**다음**: [06-python-accounting.md](./06-python-accounting.md) — Python 회계 자동화
