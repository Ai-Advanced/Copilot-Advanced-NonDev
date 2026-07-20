# 07. 캠페인 리포트 자동화

## 학습 목표

- CSV 광고 데이터를 pandas 스크립트로 자동 집계하는 워크플로우 구축
- Copilot으로 pandas 스크립트를 생성하고 수정하는 방법 익히기
- 주요 마케팅 KPI(ROAS, CPA, CTR 등)를 자동 계산하는 스크립트 완성
- 매주 반복되는 리포트 작업을 스크립트 한 번 실행으로 대체

**예상 소요**: 75~90분

---

## 7.1 왜 pandas인가

마케터에게 pandas를 배우라고 하면 "그건 데이터 사이언티스트 일 아닌가요?"라고 생각할 수 있습니다.

여기서는 pandas를 **"엑셀보다 빠른 CSV 처리 도구"**로 씁니다. 복잡한 통계나 머신러닝은 전혀 없습니다. Copilot이 코드를 다 써주고, 여러분은 실행만 합니다.

**엑셀로 할 때 vs pandas 스크립트로 할 때**

| 작업 | 엑셀 | pandas 스크립트 |
|------|------|----------------|
| 5개 CSV 합치기 | 수동 복붙, 15분 | 스크립트 1줄, 5초 |
| 채널별 집계 | 피벗테이블 수동, 5분 | 스크립트 실행, 1초 |
| KPI 계산 | 수식 입력, 오류 가능 | 한 번 정의, 매번 정확 |
| 다음 주에 동일 작업 | 처음부터 다시 | 스크립트 재실행 |

---

## 7.2 환경 준비

### Python + pandas 설치 확인

```bash
# 터미널에서 확인 (VS Code 터미널: Ctrl+`)
python --version          # 3.10 이상이면 OK
pip install pandas openpyxl
```

### 실습 CSV 파일 준비

README.md에서 만든 `ad_report.csv`를 준비하거나, 아래 내용으로 직접 만드세요.

```csv
campaign_id,campaign_name,channel,date,impressions,clicks,ctr,cost,conversions,revenue
C001,여름세일_FB,facebook,2026-07-14,45000,1350,3.0,450000,27,1080000
C001,여름세일_FB,facebook,2026-07-15,52000,1456,2.8,520000,31,1240000
C001,여름세일_FB,facebook,2026-07-16,48000,1392,2.9,480000,29,1160000
C001,여름세일_FB,facebook,2026-07-17,55000,1650,3.0,550000,33,1320000
C001,여름세일_FB,facebook,2026-07-18,61000,1830,3.0,610000,37,1480000
C001,여름세일_FB,facebook,2026-07-19,58000,1740,3.0,580000,35,1400000
C001,여름세일_FB,facebook,2026-07-20,63000,1890,3.0,630000,38,1520000
C002,여름세일_GG,google,2026-07-14,38000,1140,3.0,380000,23,920000
C002,여름세일_GG,google,2026-07-15,41000,1230,3.0,410000,25,1000000
C002,여름세일_GG,google,2026-07-16,39000,1170,3.0,390000,24,960000
C002,여름세일_GG,google,2026-07-17,44000,1320,3.0,440000,27,1080000
C002,여름세일_GG,google,2026-07-18,47000,1410,3.0,470000,29,1160000
C002,여름세일_GG,google,2026-07-19,45000,1350,3.0,450000,27,1080000
C002,여름세일_GG,google,2026-07-20,50000,1500,3.0,500000,31,1240000
C003,브랜드인지_YT,youtube,2026-07-14,120000,2400,2.0,600000,12,480000
C003,브랜드인지_YT,youtube,2026-07-15,135000,2700,2.0,675000,14,560000
C003,브랜드인지_YT,youtube,2026-07-16,128000,2560,2.0,640000,13,520000
C003,브랜드인지_YT,youtube,2026-07-17,142000,2840,2.0,710000,15,600000
C003,브랜드인지_YT,youtube,2026-07-18,150000,3000,2.0,750000,16,640000
C003,브랜드인지_YT,youtube,2026-07-19,145000,2900,2.0,725000,15,600000
C003,브랜드인지_YT,youtube,2026-07-20,155000,3100,2.0,775000,17,680000
C004,여름세일_NV,naver,2026-07-14,28000,1120,4.0,280000,18,720000
C004,여름세일_NV,naver,2026-07-15,31000,1240,4.0,310000,20,800000
C004,여름세일_NV,naver,2026-07-16,29000,1160,4.0,290000,19,760000
C004,여름세일_NV,naver,2026-07-17,33000,1320,4.0,330000,21,840000
C004,여름세일_NV,naver,2026-07-18,35000,1400,4.0,350000,23,920000
C004,여름세일_NV,naver,2026-07-19,34000,1360,4.0,340000,22,880000
C004,여름세일_NV,naver,2026-07-20,37000,1480,4.0,370000,24,960000
```

---

## 7.3 기본 pandas 패턴 (Copilot이 쓰는 코드 이해하기)

Copilot이 생성하는 pandas 코드를 읽을 수 있어야 수정도 할 수 있습니다. 핵심 5개 패턴만 이해하면 됩니다.

```python
import pandas as pd

# 1. CSV 불러오기
df = pd.read_csv('ad_report.csv')

# 2. 날짜 필터링
df['date'] = pd.to_datetime(df['date'])
last_7 = df[df['date'] >= pd.Timestamp.now() - pd.Timedelta(days=7)]

# 3. 집계 (groupby)
channel_summary = df.groupby('channel').agg(
    total_cost=('cost', 'sum'),
    total_revenue=('revenue', 'sum'),
    total_clicks=('clicks', 'sum'),
    total_impressions=('impressions', 'sum')
).reset_index()

# 4. 새 컬럼 계산 (KPI)
channel_summary['roas'] = (
    channel_summary['total_revenue'] / channel_summary['total_cost'] * 100
).round(1)
channel_summary['ctr'] = (
    channel_summary['total_clicks'] / channel_summary['total_impressions'] * 100
).round(2)

# 5. 저장
channel_summary.to_csv('weekly_summary.csv', index=False, encoding='utf-8-sig')
print(channel_summary)
```

---

## 7.4 주간 리포트 자동화 스크립트 생성

### Step 1. 스크립트 파일 만들기

VS Code에서 `weekly_report.py` 파일 생성.

### Step 2. Copilot으로 스크립트 생성

Inline Chat(`Ctrl+I`)으로 빈 파일에:

```
광고 성과 CSV를 읽어서 주간 리포트를 자동 생성하는 Python 스크립트 작성.

입력 파일: ad_report.csv
컬럼: campaign_id, campaign_name, channel, date, impressions, clicks, ctr, cost, conversions, revenue

스크립트 동작:
1. CSV 불러오기 (pandas)
2. date 컬럼을 datetime 타입으로 변환
3. 최근 7일 데이터 필터링
4. 채널별 집계:
   - total_impressions, total_clicks, total_cost, total_conversions, total_revenue
5. KPI 계산 (새 컬럼 추가):
   - ctr = total_clicks / total_impressions * 100 (소수점 2자리)
   - roas = total_revenue / total_cost * 100 (소수점 1자리)
   - cpa = total_cost / total_conversions (conversions > 0일 때만, 아니면 None)
6. 결과를 weekly_report_YYYYMMDD.csv로 저장 (오늘 날짜)
7. 터미널에 요약 출력 (채널별 ROAS 표)

에러 처리:
- 파일이 없을 때 → 안내 메시지 출력 후 종료
- 최근 7일 데이터가 없을 때 → 경고 메시지

주석: 각 단계마다 한국어 주석
변수명: 영어 snake_case
```

### Step 3. 생성된 스크립트 검증

스크립트를 생성했으면 Copilot Chat에:

```
위 weekly_report.py 스크립트를 검토해줘.

체크 항목:
1. ZeroDivisionError 가능성 (cost=0, conversions=0인 경우)
2. 파일 인코딩 문제 (한글 CSV, BOM 처리)
3. 날짜 필터 로직이 "최근 7일"을 올바르게 처리하는지
4. 저장 파일명에 오늘 날짜가 올바르게 들어가는지
5. 누락된 에러 처리

각 문제에 수정 코드 제시.
```

---

## 7.5 완성 스크립트 예시

아래는 Copilot이 생성하고 검증을 마친 수준의 완성 스크립트입니다.

```python
"""
주간 광고 성과 리포트 자동화 스크립트
사용법: python weekly_report.py [csv_파일경로]
기본값: ad_report.csv (같은 폴더에 있어야 함)
"""
import sys
import pandas as pd
from datetime import datetime, timedelta
from pathlib import Path


def load_data(filepath: str) -> pd.DataFrame:
    """CSV 파일을 불러오고 기본 검증을 수행합니다."""
    path = Path(filepath)
    if not path.exists():
        print(f"[오류] 파일을 찾을 수 없습니다: {filepath}")
        sys.exit(1)

    df = pd.read_csv(filepath, encoding='utf-8-sig')

    # date 컬럼을 datetime으로 변환
    df['date'] = pd.to_datetime(df['date'], errors='coerce')
    invalid_dates = df['date'].isna().sum()
    if invalid_dates > 0:
        print(f"[경고] 날짜 파싱 실패: {invalid_dates}행 제외됨")
        df = df.dropna(subset=['date'])

    return df


def filter_recent(df: pd.DataFrame, days: int = 7) -> pd.DataFrame:
    """최근 N일 데이터만 필터링합니다."""
    cutoff = pd.Timestamp.now().normalize() - timedelta(days=days)
    recent = df[df['date'] >= cutoff]

    if recent.empty:
        print(f"[경고] 최근 {days}일 데이터가 없습니다. 전체 데이터로 집계합니다.")
        return df

    return recent


def aggregate_by_channel(df: pd.DataFrame) -> pd.DataFrame:
    """채널별 KPI를 집계하고 계산합니다."""
    summary = df.groupby('channel').agg(
        total_impressions=('impressions', 'sum'),
        total_clicks=('clicks', 'sum'),
        total_cost=('cost', 'sum'),
        total_conversions=('conversions', 'sum'),
        total_revenue=('revenue', 'sum')
    ).reset_index()

    # CTR 계산 (0 나누기 방지)
    summary['ctr'] = (
        summary['total_clicks'] / summary['total_impressions'].replace(0, float('nan')) * 100
    ).round(2)

    # ROAS 계산
    summary['roas'] = (
        summary['total_revenue'] / summary['total_cost'].replace(0, float('nan')) * 100
    ).round(1)

    # CPA 계산 (전환 없으면 None)
    summary['cpa'] = (
        summary['total_cost'] / summary['total_conversions'].replace(0, float('nan'))
    ).round(0)

    # ROAS 내림차순 정렬
    return summary.sort_values('roas', ascending=False)


def save_report(summary: pd.DataFrame) -> str:
    """결과를 날짜 포함 CSV 파일명으로 저장합니다."""
    today = datetime.now().strftime('%Y%m%d')
    filename = f'weekly_report_{today}.csv'
    summary.to_csv(filename, index=False, encoding='utf-8-sig')
    return filename


def print_summary(summary: pd.DataFrame) -> None:
    """터미널에 요약 표를 출력합니다."""
    print("\n" + "=" * 60)
    print("  주간 채널별 성과 요약")
    print("=" * 60)

    # 숫자 포맷팅
    display = summary.copy()
    display['total_cost'] = display['total_cost'].apply(lambda x: f"{x:,.0f}원")
    display['total_revenue'] = display['total_revenue'].apply(lambda x: f"{x:,.0f}원")
    display['roas'] = display['roas'].apply(lambda x: f"{x:.1f}%" if pd.notna(x) else "N/A")
    display['cpa'] = display['cpa'].apply(lambda x: f"{x:,.0f}원" if pd.notna(x) else "N/A")

    print(display[['channel', 'total_cost', 'total_revenue', 'roas',
                   'total_conversions', 'cpa']].to_string(index=False))
    print("=" * 60 + "\n")


def main():
    filepath = sys.argv[1] if len(sys.argv) > 1 else 'ad_report.csv'

    print(f"파일 로딩 중: {filepath}")
    df = load_data(filepath)

    print("최근 7일 데이터 필터링 중...")
    recent_df = filter_recent(df, days=7)

    print("채널별 집계 중...")
    summary = aggregate_by_channel(recent_df)

    filename = save_report(summary)
    print(f"리포트 저장 완료: {filename}")

    print_summary(summary)


if __name__ == '__main__':
    main()
```

### 실행 방법

```bash
# VS Code 터미널 (Ctrl+`)
python weekly_report.py ad_report.csv
```

---

## 7.6 인사이트 요약 프롬프트

스크립트로 숫자를 뽑았으면, Copilot Chat으로 의미 있는 인사이트를 생성합니다.

```
아래 주간 광고 성과 데이터를 분석하고 실행 가능한 인사이트 5개를 생성해줘.

채널별 성과 요약:
[스크립트 출력 결과 붙여넣기]

분석 관점:
1. ROAS 기준 채널 효율성 비교
2. CPA가 가장 낮은/높은 채널과 그 이유 가설
3. 전주 대비 주목할 변화 (전주 데이터 있으면)
4. 예산 재배분 기회 (높은 ROAS 채널로)
5. 다음 주 테스트해볼 가설

각 인사이트:
- 발견: [데이터가 말하는 것]
- 가설: [왜 이런 결과인지 추정]
- 액션: [다음 주에 할 수 있는 구체적 행동]

주의: 데이터에 없는 수치는 절대 만들어내지 말 것. 불확실한 것은 "가설"로 표시.
```

---

## 7.7 Google Sheets 연동 개념

스크립트를 더 고도화하면 Google Sheets에 자동으로 데이터를 업로드할 수 있습니다. 여기서는 개념만 이해하고, 실제 구현은 필요할 때 Copilot에게 요청합니다.

```python
# gspread 라이브러리를 사용한 Google Sheets 연동 개념 코드
# pip install gspread google-auth

import gspread
from google.oauth2.service_account import Credentials

# 서비스 계정 인증 (Google Cloud Console에서 발급)
creds = Credentials.from_service_account_file(
    'service_account.json',
    scopes=['https://spreadsheets.google.com/feeds']
)
client = gspread.authorize(creds)

# 시트 열기
sheet = client.open('마케팅 대시보드').worksheet('주간 리포트')

# 데이터 업로드
sheet.update('A1', [summary.columns.tolist()] + summary.values.tolist())
```

실제 사용 시 Copilot에게:
```
위 weekly_report.py 스크립트에 Google Sheets 자동 업로드 기능 추가.
gspread 라이브러리 사용.
서비스 계정 키 파일: service_account.json
업로드 대상: 스프레드시트 "마케팅 대시보드"의 "주간 리포트" 시트.
기존 데이터는 덮어쓰기.
업로드 실패 시 에러 메시지만 출력하고 스크립트는 계속 실행.
```

---

## 실습: 광고 CSV → 주간 리포트 자동 생성 스크립트

### 과제

`weekly_report.py` 스크립트를 완성하고 실제로 실행해서 리포트를 생성하세요.

**Step 1. 스크립트 생성** (15분)

7.4절의 프롬프트로 스크립트 생성

**Step 2. 실행 테스트** (5분)

```bash
python weekly_report.py ad_report.csv
```

오류가 나면 오류 메시지를 Copilot Chat에 붙여넣고:
```
위 스크립트를 실행했더니 아래 에러가 발생했어. 수정해줘.
[에러 메시지 붙여넣기]
```

**Step 3. 기능 추가** (15분)

기본 스크립트가 동작하면, 아래 중 하나를 추가하세요.

```
옵션 A: 캠페인별 집계 추가
weekly_report.py에 채널별 집계 외에 캠페인별 집계도 추가.
두 번째 시트(또는 두 번째 CSV)로 저장.

옵션 B: 전주 대비 증감률 계산
weekly_report.py에 전주(8~14일 전) 데이터와 이번 주 데이터를 비교.
각 채널별 cost, revenue, roas 증감률(%) 계산.

옵션 C: 임계값 알림 추가
ROAS가 200% 미만인 채널 → 터미널에 [경고] 표시
CPA가 50,000원 초과인 채널 → [경고] 표시
임계값은 스크립트 상단 상수로 정의.
```

**Step 4. 인사이트 생성** (10분)

스크립트 출력 결과를 Copilot Chat에 붙여넣고 7.6절의 인사이트 요약 프롬프트 실행

---

## 핵심 포인트

1. **pandas는 "엑셀 대체제"가 아닌 "반복 작업 자동화 도구"** — 코드를 쓰는 게 아니라 Copilot이 쓴 코드를 실행하는 것
2. **0 나누기 방지 필수** — `replace(0, float('nan'))` 패턴 기억
3. **한글 CSV는 `utf-8-sig` 인코딩** — 일반 `utf-8`로 저장하면 엑셀에서 깨짐
4. **에러 메시지를 Copilot에게** — 오류가 나면 메시지 그대로 붙여넣기, Copilot이 수정해줌
5. **인사이트는 Copilot이 초안, 판단은 마케터** — 숫자 해석과 액션 결정은 경험이 필요

---

**다음**: [08-capstone.md](./08-capstone.md) — 캡스톤 프로젝트
