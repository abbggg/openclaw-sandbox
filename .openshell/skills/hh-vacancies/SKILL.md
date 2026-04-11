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

Use the local helper `openclaw-hh-vacancies` for vacancy search. It talks directly to `api.hh.ru`.

Always prefer this local helper over browsing `hh.ru` vacancy pages directly. Do not start with `web_fetch` or with manual page scraping if the helper is available.

## Tool usage

Use the bash tool with network enabled because the helper makes HTTPS requests:

```bash
bash required_permissions:"full_network" command:"openclaw-hh-vacancies search --text 'python developer' --per-page 5 --format json"
```

## Default workflow

1. Start with a public search.
2. Prefer `--format json`, then summarize the top results in chat.
3. Include title, employer, area, salary, publication time, and URL.
4. If the user gave only a short query, do not overfit filters on the first attempt.
5. If the helper is present, do not ask the user to approve routine HH search commands one by one; this sandbox pre-allowlists the helper for normal vacancy searches.

## Useful patterns

### Basic search

```bash
bash required_permissions:"full_network" command:"openclaw-hh-vacancies search --text 'python developer' --per-page 5 --format json"
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

Public search is the default. Use OAuth only when it is explicitly needed or when public search starts failing because HH requests additional verification.

Before starting OAuth, tell the user what will happen. Then run:

```bash
bash required_permissions:"full_network" command:"openclaw-hh-vacancies login-user"
```

After that, authenticated search can be forced with:

```bash
bash required_permissions:"full_network" command:"openclaw-hh-vacancies search --auth-mode require --text 'python developer' --per-page 5 --format json"
```

## Response rules

- Do not invent salary or employer details.
- If the helper returns no items, say so and suggest a broader retry.
- Prefer a concise shortlist over dumping the full JSON.
- If HH returns an auth-related `403` for `search --auth-mode require`, explain that the helper will retry in public mode unless the user explicitly asked to force authenticated search.
