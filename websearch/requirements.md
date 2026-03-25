# 삼성 반도체 관련 웹 크롤링 Daily Reporting 시스템

## 1. 프로젝트 개요

삼성 반도체와 관련된 정보를 다수의 웹사이트에서 자동 크롤링하고, LLM을 활용하여 유의미한 정보를 판별한 뒤, 일일 리포트를 이메일로 발송하는 자동화 시스템.

### 1.1 핵심 수집 카테고리

| 카테고리 | 설명 | 예시 키워드 |
|---------|------|------------|
| 삼성 반도체 기술 이슈 | 삼성 반도체 관련 기술 동향, 신제품, 공정 이슈, 수율 문제 등 | Samsung semiconductor, 삼성 파운드리, GAA, HBM, NAND, DRAM |
| 경쟁사 채용 동향 | TSMC, Intel, SK하이닉스, Micron 등 경쟁사의 채용 공고 및 인력 이동 | hiring, recruit, 채용, talent acquisition |
| 경쟁사/업계 트렌드 | 반도체 산업 전반의 트렌드, 경쟁사 전략, 시장 변화 | AI chip, advanced packaging, chiplet, 반도체 보조금 |

### 1.2 경쟁사 목록

- TSMC
- Intel (Intel Foundry Services)
- SK하이닉스
- Micron Technology
- GlobalFoundries
- NVIDIA (팹리스 / AI 반도체)
- AMD
- Qualcomm
- Broadcom

---

## 2. 크롤링 대상 사이트 목록

### 2.1 글로벌 뉴스/기술 미디어

| 사이트 | URL | 수집 방식 | 비고 |
|--------|-----|----------|------|
| Reuters (Tech) | https://www.reuters.com/technology/ | RSS / HTML 파싱 | 반도체 관련 기사 필터링 |
| Bloomberg (Tech) | https://www.bloomberg.com/technology | HTML 파싱 | 유료 구독 필요 여부 확인 |
| TechCrunch | https://techcrunch.com/ | RSS | 반도체/AI 칩 관련 |
| The Verge | https://www.theverge.com/ | RSS | 주요 기술 뉴스 |
| Ars Technica | https://arstechnica.com/ | RSS | 기술 심층 분석 |
| Tom's Hardware | https://www.tomshardware.com/ | RSS / HTML 파싱 | 반도체 하드웨어 전문 |
| AnandTech / TechInsights | https://www.techinsights.com/ | HTML 파싱 | 반도체 분석 전문 |

### 2.2 반도체 전문 미디어

| 사이트 | URL | 수집 방식 | 비고 |
|--------|-----|----------|------|
| SemiAnalysis | https://www.semianalysis.com/ | RSS / HTML 파싱 | 반도체 산업 심층 분석 |
| Semiconductor Engineering | https://semiengineering.com/ | RSS | 공정/기술 전문 |
| EE Times | https://www.eetimes.com/ | RSS | 전자/반도체 뉴스 |
| DigiTimes | https://www.digitimes.com/ | HTML 파싱 | 아시아 반도체 공급망 |
| SEMI.org | https://www.semi.org/ | HTML 파싱 | 반도체 장비/소재 업계 |
| IC Insights | - | HTML 파싱 | 시장 분석 데이터 |

### 2.3 한국 미디어

| 사이트 | URL | 수집 방식 | 비고 |
|--------|-----|----------|------|
| 전자신문 (ET News) | https://www.etnews.com/ | HTML 파싱 | 국내 IT/반도체 전문 |
| 더일렉 (TheElec) | https://www.thelec.kr/ | HTML 파싱 | 반도체/디스플레이 전문 |
| ZDNet Korea | https://zdnet.co.kr/ | RSS / HTML 파싱 | IT 전문 |
| 한경 산업 | https://www.hankyung.com/ | HTML 파싱 | 산업/경제 뉴스 |
| IT조선 | https://it.chosun.com/ | HTML 파싱 | IT 뉴스 |

### 2.4 채용 플랫폼

| 사이트 | URL | 수집 방식 | 비고 |
|--------|-----|----------|------|
| LinkedIn Jobs | https://www.linkedin.com/jobs/ | API / 스크래핑 | 경쟁사 반도체 관련 채용 |
| Indeed | https://www.indeed.com/ | HTML 파싱 | 경쟁사 채용 공고 |
| Glassdoor | https://www.glassdoor.com/ | HTML 파싱 | 채용 + 기업 리뷰 |
| 경쟁사 공식 채용 페이지 | 각사 careers 페이지 | HTML 파싱 | TSMC, Intel 등 |

### 2.5 커뮤니티 / 포럼

| 사이트 | URL | 수집 방식 | 비고 |
|--------|-----|----------|------|
| Reddit (r/semiconductors 등) | https://www.reddit.com/ | Reddit API | 업계 여론/트렌드 |
| Hacker News | https://news.ycombinator.com/ | API | 기술 커뮤니티 반응 |
| X (Twitter) | https://x.com/ | API | 업계 인사 및 전문가 트윗 |

---

## 3. 시스템 아키텍처

```
[Scheduler (Cron/APScheduler)]
        |
        v
[Crawler Manager] ──> [Site Crawler 1] ──> HTML/RSS 파싱
        |              [Site Crawler 2] ──> API 호출
        |              [Site Crawler N] ──> ...
        v
[Raw Data Storage] (DB / File)
        |
        v
[Preprocessor] ──> 중복 제거, 본문 추출, 언어 감지
        |
        v
[LLM Analyzer] ──> 관련성 판단 + 카테고리 분류 + 요약 + 중요도 평가
        |
        v
[Report Generator] ──> 일일 리포트 생성 (HTML 형식)
        |
        v
[Email Sender] ──> SMTP를 통한 메일 발송
```

---

## 4. 상세 모듈 설계

### 4.1 Crawler Manager (크롤러 관리 모듈)

**역할:** 크롤링 대상 사이트 관리, 크롤링 스케줄 조율, 크롤러 실행 관리

**요구사항:**
- 사이트별 크롤링 주기 설정 (기본: 1일 1회, 속보성 사이트는 수시간 간격)
- 사이트별 크롤러 타입 매핑 (RSS, HTML 파싱, API)
- 크롤링 실패 시 재시도 로직 (최대 3회, 지수 백오프)
- 크롤링 상태 로깅 (성공/실패/부분 성공)
- Rate limiting 준수 (사이트별 요청 간격 설정)
- robots.txt 준수 여부 확인

**설정 파일 구조 (YAML):**
```yaml
sites:
  - name: "Reuters Tech"
    url: "https://www.reuters.com/technology/"
    crawler_type: "rss"
    rss_url: "https://www.reuters.com/technology/rss"
    schedule: "0 6 * * *"  # 매일 오전 6시
    rate_limit: 2  # 초당 최대 요청 수
    retry_count: 3
    enabled: true
    keywords:
      - "Samsung"
      - "semiconductor"
      - "TSMC"
      - "HBM"
```

### 4.2 Site Crawlers (사이트별 크롤러)

**공통 인터페이스:**
```python
class BaseCrawler:
    def crawl(self, config: SiteConfig) -> List[RawArticle]
    def parse(self, response) -> List[RawArticle]
    def validate(self, article: RawArticle) -> bool
```

**크롤러 타입:**

| 타입 | 라이브러리 | 용도 |
|------|-----------|------|
| RSS Crawler | `feedparser` | RSS/Atom 피드 지원 사이트 |
| HTML Crawler | `requests` + `BeautifulSoup` / `Playwright` | 일반 웹페이지 파싱 |
| API Crawler | `requests` / 전용 SDK | Reddit API, Twitter API 등 |
| Dynamic Crawler | `Playwright` / `Selenium` | JavaScript 렌더링 필요 사이트 |

**수집 데이터 구조:**
```python
@dataclass
class RawArticle:
    source: str           # 출처 사이트명
    url: str              # 원문 URL
    title: str            # 제목
    content: str          # 본문 (전체 또는 요약)
    published_at: datetime # 게시 일시
    author: str           # 작성자
    language: str         # 언어 (ko/en)
    crawled_at: datetime  # 크롤링 시각
    raw_html: str         # 원본 HTML (디버깅용, 선택)
```

### 4.3 Preprocessor (전처리 모듈)

**역할:** 크롤링된 원시 데이터를 LLM 분석 전에 정제

**처리 단계:**
1. **중복 제거** - URL 기반 + 제목 유사도(코사인 유사도 > 0.9) 기반 중복 탐지
2. **본문 추출** - HTML 태그 제거, 광고/네비게이션 영역 제거 (`trafilatura` 또는 `newspaper3k` 활용)
3. **언어 감지** - `langdetect` 활용, 한국어/영어 분류
4. **키워드 1차 필터링** - 사전 정의 키워드 매칭으로 명백히 무관한 기사 제거 (LLM 비용 절감)
5. **텍스트 정규화** - 특수문자 정리, 인코딩 통일 (UTF-8)

### 4.4 LLM Analyzer (LLM 분석 모듈)

**역할:** 전처리된 기사를 LLM으로 분석하여 관련성, 카테고리, 중요도 판단

**사용 모델:** Claude API (Anthropic) 또는 OpenAI GPT-4o

**분석 프로세스:**

#### Step 1: 관련성 판단
```
프롬프트 예시:
"다음 기사가 삼성 반도체, 반도체 경쟁사(TSMC, Intel, SK하이닉스 등),
 또는 반도체 산업 트렌드와 관련이 있는지 판단하세요.
 관련성: HIGH / MEDIUM / LOW / NONE
 판단 근거: (1-2문장)"
```

#### Step 2: 카테고리 분류
```
카테고리:
- SAMSUNG_TECH: 삼성 반도체 기술 이슈
- COMPETITOR_HIRING: 경쟁사 채용 동향
- INDUSTRY_TREND: 반도체 업계 트렌드
- COMPETITOR_STRATEGY: 경쟁사 전략/사업
- SUPPLY_CHAIN: 공급망 이슈
- REGULATION: 규제/정책 변화
- MARKET: 시장/재무 동향
```

#### Step 3: 중요도 평가
```
중요도 기준:
- CRITICAL: 삼성에 즉각적 영향, 경영진 보고 필요
- HIGH: 주요 전략적 시사점, 팀 리더 보고 필요
- MEDIUM: 참고할 만한 정보
- LOW: 일반적인 업계 소식
```

#### Step 4: 한국어 요약 생성
```
- 기사 핵심 내용 3줄 요약
- 삼성 관점에서의 시사점 1-2줄
- 관련 키워드 태깅
```

**LLM 호출 최적화:**
- 배치 처리: 관련 기사를 묶어서 한 번에 분석 (토큰 효율화)
- 캐싱: 동일 기사 재분석 방지
- 비용 관리: 일일 토큰 사용량 모니터링 및 상한 설정
- 1차 필터(키워드 매칭)로 명백히 무관한 기사는 LLM 호출 없이 제외

### 4.5 Report Generator (리포트 생성 모듈)

**역할:** LLM 분석 결과를 일일 리포트 형태로 가공

**리포트 구조:**

```
===================================
삼성 반도체 Daily Intelligence Report
날짜: 2026-03-25
===================================

[Executive Summary]
- 금일 총 수집 기사: 150건
- 유의미 기사: 23건 (CRITICAL: 2, HIGH: 5, MEDIUM: 16)
- 주요 이슈 한줄 요약 3개

---

[1. CRITICAL 이슈]
  1-1. [기사 제목]
       출처: Reuters | 게시일: 2026-03-25
       요약: ...
       시사점: ...
       원문 링크: ...

---

[2. 삼성 반도체 기술 이슈] (HIGH 이상)
  2-1. ...
  2-2. ...

[3. 경쟁사 채용 동향]
  3-1. TSMC - 미국 애리조나 공장 엔지니어 200명 추가 채용
  3-2. Intel - ...

[4. 반도체 업계 트렌드]
  4-1. ...

[5. 기타 참고 사항] (MEDIUM)
  5-1. ...

---
[통계]
- 사이트별 수집 현황
- 카테고리별 분포
- 크롤링 오류 사이트 목록
```

**출력 형식:** HTML 이메일 템플릿 (Jinja2 활용)

### 4.6 Email Sender (메일 발송 모듈)

**역할:** 생성된 리포트를 이메일로 발송

**요구사항:**
- SMTP 기반 메일 발송 (`smtplib` + `email.mime`)
- 수신자 목록 관리 (설정 파일에서 관리)
- HTML 형식 메일 본문
- 발송 실패 시 재시도 (최대 3회)
- 발송 이력 로깅

**설정:**
```yaml
email:
  smtp_host: "smtp.company.com"
  smtp_port: 587
  use_tls: true
  sender: "semiconductor-report@company.com"
  sender_name: "반도체 Daily Report"
  recipients:
    - "team-lead@company.com"
    - "analyst@company.com"
  cc:
    - "manager@company.com"
  send_time: "08:00"  # 매일 오전 8시 발송
  subject_template: "[반도체 Daily] {date} - {critical_count}건 긴급, {high_count}건 주요"
```

---

## 5. 데이터 저장소

### 5.1 Database 스키마 (SQLite / PostgreSQL)

```sql
-- 크롤링된 기사 원본
CREATE TABLE articles (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    source          VARCHAR(100) NOT NULL,
    url             VARCHAR(500) UNIQUE NOT NULL,
    title           VARCHAR(500) NOT NULL,
    content         TEXT,
    author          VARCHAR(200),
    language        VARCHAR(10),
    published_at    TIMESTAMP,
    crawled_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- LLM 분석 결과
CREATE TABLE analysis_results (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    article_id      INTEGER REFERENCES articles(id),
    relevance       VARCHAR(10),     -- HIGH/MEDIUM/LOW/NONE
    category        VARCHAR(50),     -- 카테고리
    importance      VARCHAR(10),     -- CRITICAL/HIGH/MEDIUM/LOW
    summary_ko      TEXT,            -- 한국어 요약
    implication     TEXT,            -- 삼성 관점 시사점
    keywords        TEXT,            -- JSON array
    analyzed_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    model_used      VARCHAR(50),     -- 사용된 LLM 모델명
    token_used      INTEGER          -- 사용 토큰 수
);

-- 리포트 발송 이력
CREATE TABLE report_logs (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    report_date     DATE NOT NULL,
    total_articles  INTEGER,
    relevant_articles INTEGER,
    report_html     TEXT,
    sent_at         TIMESTAMP,
    send_status     VARCHAR(20),     -- SUCCESS/FAILED
    error_message   TEXT
);

-- 크롤링 실행 로그
CREATE TABLE crawl_logs (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    site_name       VARCHAR(100),
    started_at      TIMESTAMP,
    finished_at     TIMESTAMP,
    status          VARCHAR(20),     -- SUCCESS/FAILED/PARTIAL
    articles_found  INTEGER,
    error_message   TEXT
);
```

---

## 6. 기술 스택

| 구분 | 기술 | 비고 |
|------|------|------|
| 언어 | Python 3.11+ | |
| 웹 크롤링 | `requests`, `BeautifulSoup4`, `Playwright` | 정적/동적 페이지 대응 |
| RSS 파싱 | `feedparser` | RSS/Atom 피드 |
| 본문 추출 | `trafilatura`, `newspaper3k` | HTML → 순수 텍스트 |
| LLM | Anthropic Claude API / OpenAI API | 분석 및 요약 |
| DB | SQLite (초기) → PostgreSQL (확장 시) | |
| ORM | SQLAlchemy | DB 추상화 |
| 스케줄러 | APScheduler / Linux Cron | 크롤링 및 리포트 스케줄 |
| 메일 발송 | `smtplib` + Jinja2 | HTML 템플릿 메일 |
| 설정 관리 | PyYAML | YAML 기반 설정 |
| 로깅 | Python `logging` + `loguru` | 구조화 로깅 |
| 테스트 | `pytest` | 단위/통합 테스트 |

---

## 7. 프로젝트 디렉토리 구조

```
project/
├── config/
│   ├── sites.yaml              # 크롤링 대상 사이트 설정
│   ├── keywords.yaml           # 검색 키워드 설정
│   ├── email.yaml              # 메일 발송 설정
│   └── llm.yaml                # LLM API 설정
├── src/
│   ├── __init__.py
│   ├── main.py                 # 엔트리포인트
│   ├── crawler/
│   │   ├── __init__.py
│   │   ├── manager.py          # CrawlerManager
│   │   ├── base.py             # BaseCrawler
│   │   ├── rss_crawler.py      # RSS 크롤러
│   │   ├── html_crawler.py     # HTML 파싱 크롤러
│   │   ├── api_crawler.py      # API 기반 크롤러
│   │   └── dynamic_crawler.py  # JS 렌더링 크롤러
│   ├── preprocessor/
│   │   ├── __init__.py
│   │   ├── dedup.py            # 중복 제거
│   │   ├── extractor.py        # 본문 추출
│   │   └── filter.py           # 키워드 필터링
│   ├── analyzer/
│   │   ├── __init__.py
│   │   ├── llm_client.py       # LLM API 클라이언트
│   │   ├── prompts.py          # 프롬프트 템플릿
│   │   └── analyzer.py         # 분석 로직
│   ├── reporter/
│   │   ├── __init__.py
│   │   ├── generator.py        # 리포트 생성
│   │   └── templates/
│   │       └── daily_report.html  # 메일 HTML 템플릿
│   ├── notifier/
│   │   ├── __init__.py
│   │   └── email_sender.py     # 메일 발송
│   ├── storage/
│   │   ├── __init__.py
│   │   ├── models.py           # SQLAlchemy 모델
│   │   └── database.py         # DB 연결/세션 관리
│   └── utils/
│       ├── __init__.py
│       └── logger.py           # 로깅 설정
├── tests/
│   ├── test_crawler/
│   ├── test_preprocessor/
│   ├── test_analyzer/
│   └── test_reporter/
├── requirements.txt
├── .env                        # API 키 등 시크릿 (git 미포함)
├── .gitignore
└── README.md
```

---

## 8. 실행 흐름 (Daily Pipeline)

```
06:00  [1단계] 크롤링 시작
         ├── 각 사이트별 크롤러 병렬 실행 (asyncio / ThreadPool)
         ├── 수집된 기사 DB 저장
         └── 크롤링 로그 기록

06:30  [2단계] 전처리
         ├── 중복 제거
         ├── 본문 추출 및 정제
         └── 키워드 1차 필터링

07:00  [3단계] LLM 분석
         ├── 필터링 통과 기사 배치 분석
         ├── 관련성/카테고리/중요도 판단
         ├── 한국어 요약 생성
         └── 분석 결과 DB 저장

07:30  [4단계] 리포트 생성
         ├── 분석 결과 집계
         ├── HTML 리포트 렌더링
         └── 리포트 DB 저장

08:00  [5단계] 메일 발송
         ├── 수신자 목록 조회
         ├── 이메일 발송
         └── 발송 결과 로깅
```

---

## 9. 예외 처리 및 안정성

| 상황 | 처리 방안 |
|------|----------|
| 크롤링 대상 사이트 접속 불가 | 재시도 3회 → 실패 로그 기록, 해당 사이트 건너뛰고 나머지 진행 |
| 크롤링 차단 (403/429) | User-Agent 로테이션, 요청 간격 증가, 프록시 사용 고려 |
| LLM API 장애 | 재시도 3회 → 실패 시 미분석 기사로 표시, 다음 실행 시 재분석 |
| LLM 비용 초과 | 일일 토큰 상한 도달 시 분석 중단, 미분석 기사 목록만 리포트에 포함 |
| 메일 발송 실패 | 재시도 3회 → 실패 시 리포트를 로컬 파일로 저장, 관리자에게 알림 |
| DB 장애 | 크롤링 결과를 임시 JSON 파일로 저장, DB 복구 후 적재 |

---

## 10. 모니터링 및 운영

- **일일 크롤링 성공률** 모니터링 (사이트별)
- **LLM 토큰 사용량** 일별 추적
- **메일 발송 성공 여부** 확인
- **크롤링 품질 검증**: 주 1회 수동으로 누락/오분류 기사 샘플링 검토
- **로그 보관**: 최근 30일 상세 로그, 이후 요약 로그만 보관

---

## 11. 구현 단계 (Phase)

### Phase 1: MVP (1-2주)
- [ ] 프로젝트 구조 셋업 및 설정 파일 구성
- [ ] RSS 크롤러 구현 (3-5개 주요 사이트)
- [ ] 기본 전처리 (중복 제거, 본문 추출)
- [ ] LLM 분석 모듈 (관련성 판단 + 요약)
- [ ] 텍스트 기반 리포트 생성
- [ ] 이메일 발송 기본 기능
- [ ] SQLite DB 연동

### Phase 2: 확장 (2-3주)
- [ ] HTML 파싱 크롤러 추가 (한국 미디어 등)
- [ ] 채용 플랫폼 크롤러 추가
- [ ] HTML 이메일 템플릿 적용
- [ ] LLM 분석 고도화 (카테고리 세분화, 중요도 평가)
- [ ] 크롤링 병렬 처리 (asyncio)
- [ ] 크롤링/분석 로그 대시보드

### Phase 3: 고도화 (3-4주)
- [ ] Dynamic Crawler 추가 (Playwright)
- [ ] Reddit/Twitter API 연동
- [ ] 주간/월간 트렌드 분석 리포트
- [ ] 키워드 알림 (CRITICAL 이슈 즉시 알림)
- [ ] PostgreSQL 마이그레이션
- [ ] 웹 대시보드 (Flask/FastAPI + 간단한 UI)

---

## 12. 보안 및 법적 고려사항

- **API 키 관리**: `.env` 파일에 저장, 절대 코드에 하드코딩 금지
- **크롤링 윤리**: `robots.txt` 준수, 과도한 요청 지양
- **저작권**: 크롤링된 원문 전체 저장 시 저작권 이슈 → 요약본만 리포트에 포함, 원문은 링크 제공
- **개인정보**: 채용 공고 크롤링 시 개인정보 수집 최소화
- **사내 보안**: 사내 메일 시스템 연동 시 보안 정책 확인 필요
