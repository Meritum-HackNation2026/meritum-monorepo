# meritum-monorepo

Repozytorium zbiorcze projektu Meritum, obywatelskiego radaru dezinformacji (HackNation 2026, konkurs MSZ „Prawdowid”). Samo nie zawiera kodu produktu. Łączy pozostałe repozytoria organizacji jako submoduły git, przypięte do konkretnych commitów.

## Działające środowiska

| Nazwa | Wersja | Przeznaczenie | Link |
|---|---|---|---|
| Aplikacja webowa | prd | aplikacja dla obywateli (bootstrap: stan API; docelowo formularz sprawdzania twierdzeń) | [meritum.gburek.app](https://meritum.gburek.app) |
| Aplikacja webowa | dev | aplikacja dla obywateli (bootstrap: stan API; docelowo formularz sprawdzania twierdzeń) | [meritum-dev.gburek.app](https://meritum-dev.gburek.app) |
| API | prd | dokumentacja OpenAPI (Swagger UI) | [meritum.gburek.app/api/docs](https://meritum.gburek.app/api/docs) |
| API | dev | dokumentacja OpenAPI (Swagger UI) | [meritum-dev.gburek.app/api/docs](https://meritum-dev.gburek.app/api/docs) |
| API: stan | prd | health: API, baza danych i środowisko | [meritum.gburek.app/api/v1/health](https://meritum.gburek.app/api/v1/health) |
| API: stan | dev | health: API, baza danych i środowisko | [meritum-dev.gburek.app/api/v1/health](https://meritum-dev.gburek.app/api/v1/health) |
| Makieta X | prd | makieta platformy do demo wtyczki | [meritum-x.gburek.app](https://meritum-x.gburek.app) |
| Makieta X | dev | makieta platformy do demo wtyczki | [meritum-x-dev.gburek.app](https://meritum-x-dev.gburek.app) |
| Makieta Facebook | prd | makieta platformy do demo wtyczki | [meritum-facebook.gburek.app](https://meritum-facebook.gburek.app) |
| Makieta Facebook | dev | makieta platformy do demo wtyczki | [meritum-facebook-dev.gburek.app](https://meritum-facebook-dev.gburek.app) |
| Makieta Instagram | prd | makieta platformy do demo wtyczki | [meritum-instagram.gburek.app](https://meritum-instagram.gburek.app) |
| Makieta Instagram | dev | makieta platformy do demo wtyczki | [meritum-instagram-dev.gburek.app](https://meritum-instagram-dev.gburek.app) |
| Makieta Reddit | prd | makieta platformy do demo wtyczki | [meritum-reddit.gburek.app](https://meritum-reddit.gburek.app) |
| Makieta Reddit | dev | makieta platformy do demo wtyczki | [meritum-reddit-dev.gburek.app](https://meritum-reddit-dev.gburek.app) |
| Makieta TikTok | prd | makieta platformy do demo wtyczki | [meritum-tiktok.gburek.app](https://meritum-tiktok.gburek.app) |
| Makieta TikTok | dev | makieta platformy do demo wtyczki | [meritum-tiktok-dev.gburek.app](https://meritum-tiktok-dev.gburek.app) |
| Wtyczka Chrome | prd | zip do załadowania w chrome://extensions (artefakt `meritum-extension-prd` w przebiegu CI) | [przebiegi CI na `main`](https://github.com/Meritum-HackNation2026/meritum-extension/actions/workflows/ci.yml?query=branch%3Amain+is%3Asuccess) |
| Wtyczka Chrome | dev | zip do załadowania w chrome://extensions (artefakt `meritum-extension-dev` w przebiegu CI) | [przebiegi CI na `develop`](https://github.com/Meritum-HackNation2026/meritum-extension/actions/workflows/ci.yml?query=branch%3Adevelop+is%3Asuccess) |

`prd` wdraża się z gałęzi `main`, `dev` z gałęzi `develop`. Worker DBOS nie ma publicznego adresu; to, że działa, widać po zadaniu `ping` w deployu API.

## Nawigacja

| Katalog | Repozytorium | Zawartość |
|---|---|---|
| `backend/` | [meritum-backend](https://github.com/Meritum-HackNation2026/meritum-backend) | API w FastAPI; zleca długie operacje workerom przez DBOS |
| `worker/` | [meritum-worker](https://github.com/Meritum-HackNation2026/meritum-worker) | workery DBOS do długich operacji w tle, na PostgreSQL |
| `core/` | [meritum-core](https://github.com/Meritum-HackNation2026/meritum-core) | kod wspólny backendu i workerów: kontrakty zadań, porty, adaptery |
| `frontend/` | [meritum-frontend](https://github.com/Meritum-HackNation2026/meritum-frontend) | aplikacja webowa (React, pnpm), serwowana przez nginx, który przekazuje `/api` do backendu |
| `extension/` | [meritum-extension](https://github.com/Meritum-HackNation2026/meritum-extension) | wtyczka Chrome MV3 (WXT, React): przycisk „Sprawdź” pod postami |
| `mocks/` | [meritum-mocks](https://github.com/Meritum-HackNation2026/meritum-mocks) | makiety X, Facebooka, Instagrama, Reddita i TikToka z małym backendem w Hono |
| `marketing/` | [meritum-marketing](https://github.com/Meritum-HackNation2026/meritum-marketing) | deck, film i grafiki na konkurs MSZ |
| `design-system/` | [meritum-design-system](https://github.com/Meritum-HackNation2026/meritum-design-system) | dokument produktowy, kontrakty domenowe, system projektowy, teksty, źródłowe makiety platform |
| `infra/` | [meritum-infra](https://github.com/Meritum-HackNation2026/meritum-infra) | runnery GitHub Actions (GCP i dellpromaxgb10) oraz wspólna platforma na dellpromaxgb10: PostgreSQL, gateway, trasy Cloudflare |
| `org-profile/` | [.github](https://github.com/Meritum-HackNation2026/.github) | publiczny profil organizacji na GitHubie (`profile/README.md`) |
| `scripts/` | (to repozytorium) | skrypty pomocnicze |

## Infrastruktura środowisk

| Środowisko | Gałąź | Kontenery na dellpromaxgb10 | Schematy w bazie `meritum` |
|---|---|---|---|
| dev | `develop` | `meritum-web-dev`, `meritum-api-dev`, `meritum-worker-dev`, `meritum-mocks-dev` | `api_dev`, `worker_dev`, `mocks_dev` |
| prd | `main` | `meritum-web-prd`, `meritum-api-prd`, `meritum-worker-prd`, `meritum-mocks-prd` | `api_prd`, `worker_prd`, `mocks_prd` |

Wszystkie środowiska dzielą jeden kontener PostgreSQL (`meritum-postgres`, pgvector i pg_trgm). Każda aplikacja w każdym środowisku ma własną rolę, która widzi tylko swój schemat. Schemat workera trzyma też tabele systemowe DBOS, a rola API ma do nich dostęp, żeby zlecać zadania. Szczegóły w README meritum-infra.

## CI/CD

Każde repo aplikacji ma `.github/workflows/ci.yml` z jednym uruchomieniem na commit:

- CI (lint, typy, testy, build) działa na runnerach GCP z etykietą `meritum`, na każdej gałęzi.
- CD działa na runnerze `dellpromaxgb10`, tylko dla `develop` (dev) i `main` (prd), po zielonym CI. Deploy buduje obraz na hoście (ARM64), podmienia kontener i sprawdza go: API odpowiada na `/api/v1/health` i przepuszcza zadanie `ping` przez workera, frontend i makiety odpowiadają przez gateway pod swoimi adresami.
- Wtyczka nie ma serwera: na `develop` i `main` CI buduje zip z adresem API danego środowiska i zostawia go jako artefakt przebiegu. Marketing nie ma CI.

Zmiany idą przez PR do `develop`, wydanie przez PR `develop` → `main`. Nie pushuj bezpośrednio do `develop` ani `main`. Organizacja jest na planie Free, który nie chroni gałęzi w repozytoriach prywatnych, więc pilnujemy tego sami. Gałąź funkcji usuwaj po merge'u (`gh pr merge --delete-branch`). Automatyczne usuwanie gałęzi jest wyłączone, bo skasowałoby też `develop` po PR `develop` → `main`.

## Klonowanie

Submoduły używają adresów SSH (`git@github.com:Meritum-HackNation2026/<repo>.git`), więc potrzebujesz klucza SSH dodanego do konta GitHub z dostępem do organizacji.

```bash
git clone --recurse-submodules git@github.com:Meritum-HackNation2026/meritum-monorepo.git
```

Jeśli sklonowałeś repozytorium bez submodułów:

```bash
git submodule update --init
```

## Aktualizacja submodułów

Submoduł wskazuje konkretny commit, a nie gałąź. Żeby przesunąć wszystkie submoduły na najnowszy `main` z GitHuba:

```bash
git submodule update --remote --merge
git add design-system infra org-profile core backend worker frontend mocks extension marketing
git commit -m "Zaktualizuj submoduły"
```

To samo robi skrypt, który od razu tworzy commit (albo nic nie robi, gdy wszystko jest aktualne):

```bash
./scripts/update-submodules.sh
git push
```

Zmiany w kodzie commituj i wypychaj w repozytorium danego submodułu. W tym repozytorium commitujesz tylko przesunięcie wskaźnika.
