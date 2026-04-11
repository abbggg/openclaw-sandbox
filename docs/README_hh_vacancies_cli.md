# HH Vacancy Helper For OpenClaw

Этот документ описывает текущую интеграцию поиска вакансий HH для `openclaw-sandbox`.

## Что теперь является основным runtime path

- runtime helper внутри sandbox: `.openshell/bin/openclaw-hh-vacancies`
- host-side wrapper в репозитории: `scripts/hh_vacancies_cli.py`
- OpenClaw skill внутри sandbox: `.openshell/skills/hh-vacancies/SKILL.md`

Важно: в OpenShell materialization участвует только `.openshell/`, поэтому реальный helper и skill лежат именно там.

## Что умеет helper

- искать вакансии публично без OAuth
- автоматически использовать токен, если он уже есть
- выполнять ручной OAuth login-user
- получать app token через `login-app`
- проверять токен через `/me`
- сохранять токен в `~/.config/hh_api/token.json`

## Базовый сценарий

Внутри sandbox:

```bash
openclaw-hh-vacancies search --text 'python developer' --per-page 5
openclaw-hh-vacancies search --text 'data engineer' --param schedule=remote --format json
```

Через OpenClaw:

```text
Найди вакансии python developer на hh.ru
Найди remote вакансии data engineer на hh.ru
```

Skill `hh-vacancies` должен сам вызвать helper и вернуть краткий shortlist.

В sandbox helper заранее добавляется в local OpenClaw allowlist, поэтому типовой поиск вакансий через skill не должен требовать `/approve` на каждую команду helper-а.

## OAuth path

Если public search перестанет быть достаточным или HH начнёт требовать дополнительную проверку:

```bash
openclaw-hh-vacancies login-user
openclaw-hh-vacancies me
openclaw-hh-vacancies search --auth-mode require --text 'python developer' --format json
```

`login-user` работает в ручном режиме:

1. helper печатает URL авторизации;
2. вы открываете его в локальном браузере;
3. после redirect копируете полный URL или только `code` обратно в консоль sandbox.

## Переменные окружения

Если нужен OAuth, в sandbox должны попасть:

```bash
HH_CLIENT_ID
HH_CLIENT_SECRET
HH_REDIRECT_URI
HH_USER_AGENT
```

`HH_USER_AGENT` не секрет. Это строка идентификации клиента для HH API, например:

```bash
HH_USER_AGENT='openclaw-sandbox-hh/1.0 (your-email@example.com)'
```

## Как секреты попадают в sandbox

Рекомендуемый путь:

1. положить `HH_*` значения в текущий shell или в `~/.config/robolaba/secrets.env`;
2. создать sandbox через `scripts/openclaw_create_env.sh`;
3. launcher сам попробует прикрепить optional HH provider, если все четыре переменные доступны.

Если какой-то `HH_*` отсутствует, sandbox всё равно создастся, но только с public-search path.

Практический нюанс: generic OpenShell provider инжектит ссылки вида `openshell:resolve:env:...`, а не plain-text значения. Для OpenClaw это нормально, но Python helper их сам не резолвит. Поэтому ручной OAuth для helper-а сейчас надёжнее проходить на хосте через `scripts/hh_vacancies_cli.py login-user`, а затем загружать полученный `token.json` в sandbox.

## Полезные команды

Хост:

```bash
python scripts/hh_vacancies_cli.py search --text 'golang' --format json
```

Sandbox:

```bash
openclaw skills info hh-vacancies
openclaw-hh-vacancies search --text 'golang' --only-with-salary
```

## Сетевой доступ

Для этого сценария в policy открыты:

- `api.hh.ru`
- `gist.github.com`
- `gist.githubusercontent.com`

`gist` открыт только в read-only смысле использования сети из sandbox; отдельного write-flow для gist здесь нет.

Во время финальной smoke-проверки:

- `gist.github.com` и `gist.githubusercontent.com` доступны;
- public search по `https://api.hh.ru/vacancies` из sandbox работает;
- `openclaw-hh-vacancies me` с applicant OAuth token работает;
- `openclaw-hh-vacancies search --auth-mode require ...` с таким applicant token получает `403 forbidden`.

Поэтому текущий helper в режиме `auto` делает fallback на public search, если authenticated vacancy search запрещён со стороны HH.

Практический вывод по OpenClaw:

- Telegram approvals теперь могут приходить в DM бота;
- но для самого helper-а это не требуется в нормальном path, потому что `openclaw-start` заранее держит `tools.exec.host=auto` и добавляет `openclaw-hh-vacancies` в local allowlist.
