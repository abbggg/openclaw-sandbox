---
name: hh-vacancies
description: Search hh.ru and other HeadHunter-group vacancy listings via the local `openclaw-hh-vacancies` helper. Use when the user asks to find jobs, vacancies, or roles on hh.ru / HeadHunter. Trigger keywords - hh, hh.ru, headhunter, vacancy, vacancies, job, jobs, работа, вакансия, вакансии.
metadata:
  {
    "openclaw":
      {
        "emoji": "💼",
        "requires": { "anyBins": ["openclaw-hh-vacancies"] },
      },
  }
---

# HH Vacancies

Use the local helper `openclaw-hh-vacancies` for vacancy search and exact vacancy fetches. It talks directly to `api.hh.ru`.

Always prefer this local helper over browsing `hh.ru` vacancy pages directly. Do not start with `web_fetch` or with manual page scraping if the helper is available.

## Tool usage

Use the bash tool with network enabled because the helper makes HTTPS requests:

```bash
bash required_permissions:"full_network" command:"openclaw-hh-vacancies search --text 'python developer' --per-page 5 --format json"
```

## Default workflow

1. If the user gives an exact vacancy id or URL, use `vacancy` first.
2. Otherwise start with `search`.
3. Prefer `--format json`, then summarize the relevant result in chat unless the user asked for raw JSON.
4. Include title, employer, area, salary, publication time, and URL.
5. If the user gave only a short query, do not overfit filters on the first attempt.
6. If the helper is present, do not ask the user to approve routine HH commands one by one; this sandbox starts OpenClaw with the `yolo` exec preset for normal vacancy work.

## Useful patterns

### Basic search

```bash
bash required_permissions:"full_network" command:"openclaw-hh-vacancies search --text 'python developer' --per-page 5 --format json"
```

### Exact vacancy by id or URL

```bash
bash required_permissions:"full_network" command:"openclaw-hh-vacancies vacancy 131717434"
```

```bash
bash required_permissions:"full_network" command:"openclaw-hh-vacancies vacancy https://api.hh.ru/vacancies/131717434 --format json"
```

### Remote-first retry

```bash
bash required_permissions:"full_network" command:"openclaw-hh-vacancies search --text 'python developer' --param schedule=remote --per-page 5 --format json"
```

If this returns too few results, retry without `schedule=remote`.

### Area filter

```bash
bash required_permissions:"full_network" command:"openclaw-hh-vacancies search --text 'data engineer' --area 1 --per-page 5 --format json"
```

### Salary-only

```bash
bash required_permissions:"full_network" command:"openclaw-hh-vacancies search --text 'golang' --only-with-salary --per-page 5 --format json"
```

## OAuth mode

Public access is the default. Use OAuth when it is explicitly needed or when HH starts returning `403` because the API wants additional verification.

For non-interactive app auth, run:

```bash
bash required_permissions:"full_network" command:"openclaw-hh-vacancies login-app"
```

For browser-based user auth, tell the user what will happen and then run:

```bash
bash required_permissions:"full_network" command:"openclaw-hh-vacancies login-user"
```

After that, authenticated access can be forced with:

```bash
bash required_permissions:"full_network" command:"openclaw-hh-vacancies search --auth-mode require --text 'python developer' --per-page 5 --format json"
```

```bash
bash required_permissions:"full_network" command:"openclaw-hh-vacancies vacancy 131717434 --auth-mode require"
```

## Response rules

- Do not invent salary or employer details.
- If the helper returns no items, say so and suggest a broader retry.
- Prefer a concise shortlist over dumping the full JSON for search results.
- If the user asked for one exact vacancy as JSON, return that JSON directly.
- If HH returns `403` for public access, switch to OAuth when credentials are available.
- If HH returns an auth-related `403` for `--auth-mode require`, explain that the helper retries public mode only in `auto`, not in `require`.
