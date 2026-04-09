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

`scripts/notify-slack.sh`와 `scripts/pretool-cache.sh`를 `~/.claude/`로 복사하고 실행 권한을 부여하세요.

```bash
cp scripts/notify-slack.sh ~/.claude/notify-slack.sh
cp scripts/pretool-cache.sh ~/.claude/pretool-cache.sh
chmod +x ~/.claude/notify-slack.sh ~/.claude/pretool-cache.sh
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
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "WebFetch",
      "WebSearch",
      "Bash(git status*)",
      "Bash(git log*)",
      "Bash(git diff*)",
      "Bash(git branch*)",
      "Bash(git remote*)",
      "Bash(git show*)",
      "Bash(ls *)",
      "Bash(ls)",
      "Bash(cat *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(wc *)",
      "Bash(which *)",
      "Bash(echo *)",
      "Bash(pwd)",
      "Bash(env)",
      "Bash(nvidia-smi*)",
      "Bash(gpustat*)",
      "Bash(ps *)",
      "Bash(top *)",
      "Bash(htop*)",
      "Bash(df *)",
      "Bash(du *)",
      "Bash(free *)",
      "Bash(uname *)",
      "Bash(docker ps*)",
      "Bash(docker images*)",
      "Bash(docker logs*)",
      "Bash(python --version*)",
      "Bash(pip list*)",
      "Bash(pip show*)",
      "Bash(uv run python --version*)",
      "Agent",
      "Bash(git add *)",
      "Bash(git add .)",
      "Bash(git stash*)",
      "Bash(uv pip list*)",
      "Bash(uv pip show*)",
      "Bash(uv pip install*)",
      "Bash(uv venv*)",
      "Bash(ruff check*)",
      "Bash(ruff format --check*)",
      "Bash(python -c *)",
      "Bash(python3 -c *)",
      "Bash(mkdir *)",
      "Bash(file *)",
      "Bash(find *)",
      "Bash(tree *)",
      "Bash(tree)",
      "Bash(grep *)",
      "Bash(wc)",
      "Bash(realpath *)",
      "Bash(date*)",
      "Bash(sort *)",
      "Bash(uniq *)",
      "Bash(diff *)",
      "Bash(md5sum *)",
      "Bash(sha256sum *)",
      "Bash(stat *)",
      "Bash(id)",
      "Bash(whoami)",
      "Bash(hostname)",
      "Bash(printenv*)",
      "Bash(lsof *)",
      "Bash(netstat *)",
      "Bash(ss *)",
      "Bash(nproc)",
      "Bash(lscpu)",
      "Bash(lsblk*)",
      "Bash(ip addr*)",
      "Bash(conda list*)",
      "Bash(conda info*)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/pretool-cache.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/notify-slack.sh"
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
            "command": "bash ~/.claude/notify-slack.sh"
          }
        ]
      }
    ]
  }
}
```

### permissions 설명

읽기 전용 도구와 상태 확인 명령어를 승인 없이 자동 실행합니다.

| 카테고리 | 자동 허용 항목 |
|---|---|
| Read-only 도구 | `Read`, `Glob`, `Grep` |
| 웹 조회 | `WebFetch`, `WebSearch` |
| Subagent | `Agent` |
| Git 조회 | `git status`, `git log`, `git diff`, `git branch`, `git remote`, `git show` |
| Git 안전 작업 | `git add`, `git stash` |
| 파일 조회 | `ls`, `cat`, `head`, `tail`, `wc`, `pwd`, `file`, `find`, `tree`, `grep`, `stat`, `realpath` |
| 텍스트 처리 (read-only) | `sort`, `uniq`, `diff` |
| 체크섬 | `md5sum`, `sha256sum` |
| 시스템 상태 | `nvidia-smi`, `gpustat`, `ps`, `top`, `htop`, `df`, `du`, `free`, `uname`, `env`, `nproc`, `lscpu`, `lsblk` |
| 시스템 정보 | `id`, `whoami`, `hostname`, `date`, `printenv` |
| 네트워크 조회 | `lsof`, `netstat`, `ss`, `ip addr` |
| Docker 조회 | `docker ps`, `docker images`, `docker logs` |
| Python 조회/실행 | `python --version`, `python -c`, `python3 -c`, `pip list`, `pip show`, `uv pip list`, `uv pip show`, `uv pip install`, `uv venv` |
| Conda 조회 | `conda list`, `conda info` |
| 린터 (검사만) | `ruff check`, `ruff format --check` |
| 디렉토리 생성 | `mkdir` |

파일 수정(`Edit`, `Write`), `git commit`, `git push`, `rm`, `mv` 등 쓰기/삭제 작업은 승인이 필요합니다.

### hooks 설명

| 이벤트 | 트리거 시점 | 동작 |
|---|---|---|
| `PreToolUse` | 도구 호출 직전 | `pretool-cache.sh`가 도구 정보를 `/tmp`에 캐싱 (Slack 호출 없음) |
| `Notification` | Claude Code가 알림을 보낼 때 (승인 요청 등) | `notify-slack.sh`가 캐시된 도구 정보와 함께 Slack 전송 |
| `Stop` | Claude가 작업을 마치고 사용자 입력을 기다릴 때 | `notify-slack.sh`가 마지막 응답 200자와 함께 Slack 전송 |

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
- stdin으로 hook event JSON을 받아 파싱 (`jq` 사용)
- 메시지 형식:
  ```
  [SERVER:$USER DIR:$PWD SESSION:<custom-title>] <승인 요청|작업 완료>
  <본문>
  ```
- `SESSION`: transcript JSONL의 `customTitle` (`/rename`으로 설정한 이름). 없으면 `session_id` 앞 8자.
- 본문:
  - `Notification` → `pretool-cache.sh`가 저장한 `/tmp/claude-last-tool-${session_id}.json`을 읽어 도구명과 입력값(command/file_path/pattern/url) 표시
  - `Stop` → transcript에서 마지막 assistant 메시지 텍스트의 앞 200자

## 참고: pretool-cache.sh 스펙

- `PreToolUse` hook에서 호출되어 stdin JSON을 받음
- `tool_name`과 `tool_input`만 추출해 `/tmp/claude-last-tool-${session_id}.json`에 저장
- Slack 호출 없음 (도구 호출마다 발동되므로 스팸 방지)
- `notify-slack.sh`가 `Notification` 이벤트에서 이 캐시를 읽어 "어떤 도구를 승인하려는지" 본문을 구성
