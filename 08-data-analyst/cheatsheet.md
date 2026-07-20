# 데이터 분析가 Copilot 치트시트 — 1페이지 요약

---

## 핵심 원칙 3가지

1. **스키마 먼저** — 테이블명 + 컬럼명 + 타입을 프롬프트 첫 줄에
2. **방언 명시** — `PostgreSQL` / `BigQuery` / `Snowflake` 항상 지정
3. **검증 필수** — JOIN 전후 행 수, GROUP BY 컬럼 누락, NULL 처리 확인

---

## SQL 프롬프트 공식

```
[방언] SQL 작성.
테이블: [테이블명(컬럼1, 컬럼2, ...)]
목적: [무엇을 구하는가]
결과 컬럼: [컬럼명 목록]
조건: [필터/기간/기준]
정렬: [컬럼 ASC/DESC]
```

## pandas 프롬프트 공식

```python
# [df] DataFrame, 컬럼: [컬럼 목록]
# 작업: [필터/groupby/pivot/merge/apply]
# 결과: [원하는 형태]
# 주의: SettingWithCopyWarning 없이, .copy() 사용
```

---

## SQL 핵심 패턴 빠른 참조

| 패턴 | 핵심 키워드 |
|------|-----------|
| 코호트 리텐션 | `MIN(event_date)` + `DATE_TRUNC` + `DATEDIFF` |
| Window Function | `ROW_NUMBER / LAG / LEAD / RANK OVER(PARTITION BY ... ORDER BY ...)` |
| 세션 분리 | `LAG(event_date) + 30분 간격 기준 + SUM(flag) OVER(...)` |
| 퍼널 전환 | `COUNT(DISTINCT CASE WHEN event='X' THEN user_id END)` |
| RFM | `MAX(paid_at)` + `COUNT(*)` + `SUM(amount)` + `NTILE(5)` |
| MRR 분해 | `SUM(CASE WHEN event_type='subscribe' THEN mrr END)` |
| 중복 제거 | `ROW_NUMBER() OVER(PARTITION BY key ORDER BY id DESC) = 1` |

---

## pandas 핵심 패턴

```python
# 읽기
df = pd.read_csv('file.csv', parse_dates=['date_col'])

# 필터
df_filtered = df[df['col'] > value].copy()

# groupby 집계
result = df.groupby(['col1', 'col2'])['amount'].agg(['sum','mean','count']).reset_index()

# 피벗
pivot = df.pivot_table(index='month', columns='plan', values='user_id', aggfunc='nunique', fill_value=0)

# merge (LEFT JOIN)
merged = pd.merge(left_df, right_df, on='user_id', how='left')

# apply
df['price'] = df['plan'].map({'basic': 9.99, 'pro': 19.99, 'enterprise': 49.99})

# 결측치
df['col'].fillna(0, inplace=False)   # inplace=True 대신 재대입 권장
df = df.dropna(subset=['필수컬럼'])
```

---

## Copilot이 자주 틀리는 TOP 5

| # | 실수 유형 | 검증 방법 |
|---|---------|---------|
| 1 | LEFT JOIN → INNER JOIN (행 누락) | 조인 전후 `SELECT COUNT(*)` 비교 |
| 2 | GROUP BY 컬럼 누락 | 실행 오류 확인 + 쿼리 재검토 |
| 3 | SettingWithCopyWarning | `.copy()` 추가 여부 확인 |
| 4 | 코호트 기준일 오류 | `MIN(event_date)` 기준인지 확인 |
| 5 | 날짜 VARCHAR 비교 | `CAST(col AS DATE)` 추가 여부 |

---

## 분析 단계별 go-to 프롬프트

| 단계 | 프롬프트 파일 위치 |
|------|----------------|
| 탐색 | prompts.md P01~P08 |
| 정제 | prompts.md P09~P15 |
| 집계 | prompts.md P16~P26 |
| 시각화 | prompts.md P27~P34 |
| 스토리텔링 | prompts.md P35~P40 |
| SQL 최적화 | prompts.md P41~P45 |
| 통계 | prompts.md P57~P60 |

---

## 데이터 프라이버시 체크리스트

- [ ] PII(이름·이메일·전화번호) 컬럼을 프롬프트에 직접 붙이지 않았는가
- [ ] 실제 데이터 대신 컬럼명·스키마만 공유했는가
- [ ] 샘플 데이터는 익명화 또는 합성 데이터인가
- [ ] read-only DB 계정을 사용 중인가

---

## 사전 준비 체크

- [ ] GitHub Copilot + Copilot Chat 확장 설치
- [ ] SQLTools 확장 설치
- [ ] Rainbow CSV 확장 설치
- [ ] Jupyter 확장 설치
- [ ] Python 3.10+ + pandas/numpy/matplotlib/seaborn/plotly 설치
