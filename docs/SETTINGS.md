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

## Step 2. settings.json에 statusLine 등록

`~/.claude/settings.json`을 읽고, 기존 설정을 유지하면서 아래 `statusLine` 키를 merge하세요.
파일이 없으면 새로 생성하세요.

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

## Step 3. 글로벌 규칙 적용

`docs/RULES.md`를 `~/.claude/CLAUDE.md`로 복사하세요.

```bash
cp docs/RULES.md ~/.claude/CLAUDE.md
```

## Step 4. 세션 컬러 설정

Claude Code 세션 내에서 `/color pink`를 실행하세요.

---

## 참고: statusline.sh 스펙

- 라벨 색상: cyan (`\033[36m`)
- 표시 항목: 모델명, 컨텍스트 사용량 바, in/out 토큰, cwd, 프로젝트, diff(+green/-red), rate limit(5h/7d), worktree
- 순수 bash로 작성 (python 불필요)
