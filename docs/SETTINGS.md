# Claude Code 환경 설정 지시서

이 문서는 Claude Code가 새 환경에서 읽고 직접 실행하기 위한 지시서입니다.
아래 작업을 순서대로 수행하세요.

---

## Step 1. Status Line 스크립트 배포

`scripts/statusline.sh`를 `~/.claude/statusline.sh`로 복사하고 실행 권한을 부여하세요.

```bash
cp scripts/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

## Step 2. Slack 알림 스크립트 배포

`scripts/notify-slack.sh`를 `~/.claude/notify-slack.sh`로 복사하고 실행 권한을 부여하세요.

```bash
cp scripts/notify-slack.sh ~/.claude/notify-slack.sh
chmod +x ~/.claude/notify-slack.sh
```

스크립트는 환경변수 `SLACK_WEBHOOK_URL`을 사용합니다.
셸 프로필(`~/.bashrc` 등)에 Webhook URL을 등록하세요.

```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

> Webhook URL은 [Slack App 설정](https://api.slack.com/apps) → Incoming Webhooks에서 생성할 수 있습니다.

## Step 3. settings.json 설정

`~/.claude/settings.json`을 읽고, 기존 설정을 유지하면서 아래 키들을 merge하세요.
파일이 없으면 새로 생성하세요.

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  },
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/notify-slack.sh \"🔔 Claude Code: 작업이 완료되었습니다. 확인해주세요.\""
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/notify-slack.sh \"🔔 Claude Code: 알림이 있습니다. 확인해주세요.\""
          }
        ]
      }
    ]
  }
}
```

### hooks 설명

| 이벤트 | 트리거 시점 |
|---|---|
| `Stop` | Claude가 작업을 마치고 사용자 입력을 기다릴 때 |
| `Notification` | Claude Code가 알림을 보낼 때 |

`matcher`가 빈 문자열이면 해당 이벤트의 모든 경우에 매칭됩니다.

## Step 4. 글로벌 규칙 적용

`docs/RULES.md`를 `~/.claude/CLAUDE.md`로 복사하세요.

```bash
cp docs/RULES.md ~/.claude/CLAUDE.md
```

## Step 5. 세션 컬러 설정

Claude Code 세션 내에서 `/color pink`를 실행하세요.

---

## 참고: statusline.sh 스펙

- 라벨 색상: cyan (`\033[36m`)
- 표시 항목: 모델명, 컨텍스트 사용량 바, in/out 토큰, cwd, 프로젝트, diff(+green/-red), rate limit(5h/7d), worktree
- 순수 bash로 작성 (python 불필요)

## 참고: notify-slack.sh 스펙

- 환경변수 `SLACK_WEBHOOK_URL`이 설정되어 있지 않으면 아무 동작 없이 종료
- 첫 번째 인자를 메시지로 Slack Incoming Webhook에 POST
- Claude Code의 `Notification` hook과 연동하여 승인 대기/작업 완료 시 알림
