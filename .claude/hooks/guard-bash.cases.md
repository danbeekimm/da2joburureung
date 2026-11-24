# guard-bash.sh 시험표

`guard-bash.sh` 는 AI가 셸 명령을 실행하기 **전에** 불려서, 위험한 명령이면 종료 코드 2 로 막는다.
아래는 가짜 입력을 넣어 직접 돌린 결과다. 훅을 고치면 이 표를 다시 돌린다.

## 손으로 돌리는 방법

```bash
printf '{"tool_input":{"command":"terraform apply"}}' | bash .claude/hooks/guard-bash.sh
echo $?        # 2 = 차단, 0 = 통과
```

## 결과 (2026-11-24, Windows 11 · Git Bash · jq 로 입력 읽기)

| # | 명령 | 기대 | 결과 |
|---|---|---|---|
| 1 | `./gradlew build -x test` | 통과 | 통과 |
| 2 | `cat .env` | 차단 | 차단 |
| 3 | `grep KEY ./.env` | 차단 | 차단 |
| 4 | `source .env && docker compose up` | 차단 | 차단 |
| 5 | `cat .env.example` | 통과 | 통과 |
| 6 | `terraform apply -auto-approve` | 차단 | 차단 |
| 7 | `terraform -chdir=terraform destroy` | 차단 | 차단 |
| 8 | `terraform validate` | 통과 | 통과 |
| 9 | `terraform fmt -check` | 통과 | 통과 |
| 10 | `terraform plan` | 통과 | 통과 |
| 11 | `cat terraform/terraform.tfvars` | 차단 | 차단 |
| 12 | `cat terraform/terraform.tfvars.example` | 통과 | 통과 |
| 13 | `cat terraform/terraform.tfstate` | 차단 | 차단 |
| 14 | `type terraform\terraform.tfstate.backup` | 차단 | 차단 |
| 15 | `git push origin main` | 차단 | 차단 |
| 16 | `git push origin develop` | 차단 | 차단 |
| 17 | `git push origin HEAD:develop` | 차단 | 차단 |
| 18 | `git push -f origin feature/x` | 차단 | 차단 |
| 19 | `git push origin feature/x` | 통과 | 통과 |
| 20 | `git push origin develop-fix` | 통과 | 통과 |
| 21 | `git log origin/develop --oneline` | 통과 | 통과 |
| 22 | `docker compose down -v` | 차단 | 차단 |
| 23 | `docker compose down` | 통과 | 통과 |
| 24 | `docker compose up -d` | 통과 | 통과 |
| 25 | `Get-Content .env` (PowerShell) | 차단 | 차단 |
| 26 | `cat "$CLAUDE_PROJECT_DIR/.env"` | 차단 | 차단 |
| 27 | `ls -la` | 통과 | 통과 |

`terraform plan` 은 훅에서는 통과하지만 `.claude/settings.json` 의 `ask` 에 있어 실행 전에 사람에게 묻는다.

## 한계 — 알고 있는 우회 경로

이 훅은 명령 **문자열**을 보는 방식이다. 문자열에 `.env` 가 그대로 나타나지 않으면 지나간다.

| 명령 | 결과 | 왜 지나가는가 |
|---|---|---|
| `F=.en; cat ${F}v` | 통과 | 파일 이름을 변수로 조합했다 |
| `cat .e*v` | 통과 | 셸이 실행 시점에 이름을 펼친다 |

그래서 이 훅은 **실수를 막는 장치**이지 완전한 차단이 아니다.

- 파일 읽기 도구로 `.env` · `terraform.tfvars` · `tfstate` 를 여는 것은 `.claude/settings.json` 의 `deny` 규칙이 따로 막는다.
- 의도적인 우회까지 막으려면 격리된 실행 환경이 필요하다.
- 차단 메시지 끝에 "우회하지 말고 사용자에게 알린다" 를 붙여, 막힌 뒤의 행동도 함께 지시한다.

## 알아 둘 동작

- `cp .env.example .env` 도 차단된다. `.env` 를 만드는 일은 사람이 직접 한다.
- `develop` 푸시를 막는 이유: `develop` 에 푸시되면 `build-push-ecr.yml` 이 9개 서비스 이미지를 빌드해 ECR 로 올린다.
- `Bash` 와 `PowerShell` 도구 양쪽에 연결되어 있다 (`settings.json` 의 `matcher`).
