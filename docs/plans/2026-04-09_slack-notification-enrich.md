# Slack 알림 정보 강화 계획

## 목표

현재 Slack 알림은 고정 문구("작업 완료" / "알림 있음")만 보내고 있어 컨텍스트가 부족하다. 다음 정보를 함께 전달해 한눈에 어떤 세션에서 무슨 일이 일어났는지 파악 가능하게 한다.

## 메시지 형식

### 제목 (모든 알림 공통)
```
[SERVER:$USER DIR:$PWD SESSION:<custom-title>] <notification type>
```

- `SERVER`: `$USER` 환경변수
- `DIR`: `$PWD` (hook 실행 시 작업 디렉토리)
- `SESSION`: transcript JSONL 첫 줄에서 `customTitle` 추출 (`/rename`으로 설정한 이름). 없으면 `session_id` 앞 8자.
- `notification type`:
  - `Notification` 이벤트 → `승인 요청`
  - `Stop` 이벤트 → `작업 완료`

### 본문
- **승인 요청 (`Notification`)**: 직전에 호출된 도구 정보 (도구명 + 핵심 입력)
  - 예: `Bash 실행: git push origin overflow`
  - 예: `Edit 실행: /workspace/agent-workflow/scripts/notify-slack.sh`
- **작업 완료 (`Stop`)**: 마지막 assistant 메시지 텍스트의 앞 200자
  - 예: `확인 완료. 모두 가능합니다. ## 검증 결과 1. 세션 이름 ✅ - transcript JSONL 첫 줄에...`

## 구현 방식

### A. `PreToolUse` hook으로 도구 컨텍스트 캐싱

매 `PreToolUse` 발동 시 **Slack에 보내지 않고** 다음 정보를 임시 파일에 기록한다:

- 경로: `/tmp/claude-last-tool-${session_id}.json`
- 내용: `{"tool_name": "...", "tool_input": {...}}`

이후 `Notification` 발동 시 이 파일을 읽어 본문에 포함한다. 이렇게 하면 Slack 스팸 없이도 "어떤 명령을 승인하려는지" 정확한 정보를 얻을 수 있다.

### B. `notify-slack.sh` 재작성

기존 스크립트는 인자 1개를 메시지로 받아 그대로 POST하는 9줄짜리 단순 구조. 이를 다음과 같이 확장한다:

1. stdin에서 hook JSON 읽기 (`jq`로 파싱)
2. `hook_event_name`으로 분기 (`Notification` / `Stop`)
3. `transcript_path`에서 `customTitle` 추출 (`grep` + `jq`)
4. 본문 생성:
   - `Notification` → `/tmp/claude-last-tool-${session_id}.json` 읽기
   - `Stop` → transcript JSONL을 거꾸로 읽어 마지막 `type:"assistant"` 항목의 텍스트 내용 추출 후 200자 truncate
5. 제목 + 본문 조합해 Slack Incoming Webhook으로 POST

`SLACK_WEBHOOK_URL` 미설정 시 즉시 종료는 그대로 유지.

### C. `pretool-cache.sh` 신규 스크립트

`PreToolUse` hook에서 호출되어 도구 정보를 임시 파일에 캐싱만 수행. Slack 호출 없음. 매우 짧은 bash 스크립트.

- 경로: `scripts/pretool-cache.sh`
- 동작: stdin JSON에서 `session_id`, `tool_name`, `tool_input` 추출 → `/tmp/claude-last-tool-${session_id}.json`에 기록

### D. `settings.json` hooks 업데이트

`docs/SETTINGS.md`의 settings.json 예시 블록을 다음과 같이 변경:

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "",
      "hooks": [
        { "type": "command", "command": "bash ~/.claude/pretool-cache.sh" }
      ]
    }
  ],
  "Stop": [
    {
      "matcher": "",
      "hooks": [
        { "type": "command", "command": "bash ~/.claude/notify-slack.sh" }
      ]
    }
  ],
  "Notification": [
    {
      "matcher": "",
      "hooks": [
        { "type": "command", "command": "bash ~/.claude/notify-slack.sh" }
      ]
    }
  ]
}
```

핵심 변경: `notify-slack.sh`에 인자를 넘기지 않음 (stdin JSON에서 모든 정보 획득).

### E. `docs/SETTINGS.md` 문서 업데이트

- Step 2에 `pretool-cache.sh` 배포 명령 추가
- Step 3 hooks 블록을 위 새 구조로 교체
- 하단 "참고: notify-slack.sh 스펙" 섹션을 새 동작에 맞게 업데이트
- 새 섹션 "참고: pretool-cache.sh 스펙" 추가

## 변경 파일 목록

| 파일 | 변경 내용 |
|---|---|
| `scripts/notify-slack.sh` | 재작성 (stdin JSON 파싱, 컨텍스트 추출, 본문 생성) |
| `scripts/pretool-cache.sh` | 신규 (도구 정보 캐싱) |
| `docs/SETTINGS.md` | Step 2/3 및 참고 섹션 업데이트 |

`docker/Dockerfile`은 이미 `jq`가 포함되어 있어 변경 불필요.

## 엣지 케이스 처리

- **`SLACK_WEBHOOK_URL` 미설정** → 즉시 exit 0 (기존 동작 유지)
- **`customTitle` 없음** → `session_id` 앞 8자로 fallback
- **`/tmp/claude-last-tool-*.json` 없음** (`Notification` 시) → 본문에 `(도구 정보 없음)` 표시
- **마지막 assistant 메시지가 비어있음** (`Stop` 시) → 본문 생략, 제목만 전송
- **메시지에 큰따옴표/개행 포함** → `jq -Rs` 또는 `jq -n --arg`로 안전하게 JSON escape
- **transcript_path가 존재하지 않음** → SESSION을 `session_id` 앞 8자로 표시, 본문 생략

## 테스트 방법

배포 후 실제 동작 확인 (수동):

1. `cp scripts/notify-slack.sh ~/.claude/ && cp scripts/pretool-cache.sh ~/.claude/ && chmod +x ~/.claude/*.sh`
2. settings.json hooks 업데이트
3. 새 Claude Code 세션 시작 → `/rename test-session`
4. Bash 명령 (승인 필요한 것) 요청 → Slack에 `[... SESSION:test-session] 승인 요청` + 도구 정보 도착 확인
5. 작업 완료 후 → `[... SESSION:test-session] 작업 완료` + 마지막 응답 200자 도착 확인

## 미결정 사항

없음. 모두 사용자 확인 완료:
- `jq` 사용 OK (이미 Docker에 설치됨)
- 승인 요청 디테일은 (B) PreToolUse 조합 방식
- 마지막 응답 미리보기 200자
