# meritum-monorepo

Repozytorium zbiorcze projektu Meritum, obywatelskiego radaru dezinformacji (HackNation 2026, konkurs MSZ „Prawdowid”). Samo nie zawiera kodu produktu. Łączy pozostałe repozytoria organizacji jako submoduły git, przypięte do konkretnych commitów.

## Nawigacja

| Katalog | Repozytorium | Zawartość |
|---|---|---|
| `backend/` | [meritum-backend](https://github.com/Meritum-HackNation2026/meritum-backend) | API w FastAPI; zleca długie operacje workerom przez DBOS |
| `worker/` | [meritum-worker](https://github.com/Meritum-HackNation2026/meritum-worker) | workery DBOS do długich operacji w tle, na PostgreSQL |
| `core/` | [meritum-core](https://github.com/Meritum-HackNation2026/meritum-core) | kod wspólny backendu i workerów: kontrakty zadań, porty, adaptery |
| `frontend/` | [meritum-frontend](https://github.com/Meritum-HackNation2026/meritum-frontend) | aplikacja webowa (React, pnpm), serwowana przez nginx, który przekazuje `/api` do backendu |
| `design-system/` | [meritum-design-system](https://github.com/Meritum-HackNation2026/meritum-design-system) | dokument produktowy, kontrakty domenowe, system projektowy, teksty, makiety platform do demo |
| `infra/` | [meritum-infra](https://github.com/Meritum-HackNation2026/meritum-infra) | runnery GitHub Actions (GCP i dellpromaxgb10) oraz wspólna platforma na dellpromaxgb10: PostgreSQL, gateway, trasy Cloudflare |
| `org-profile/` | [.github](https://github.com/Meritum-HackNation2026/.github) | publiczny profil organizacji na GitHubie (`profile/README.md`) |
| `scripts/` | (to repozytorium) | skrypty pomocnicze |

Repozytoria założone, jeszcze puste (dostaną submoduł po pierwszym commicie): [meritum-extension](https://github.com/Meritum-HackNation2026/meritum-extension) (wtyczka Chrome), [meritum-mocks](https://github.com/Meritum-HackNation2026/meritum-mocks) (makiety platform do demo wtyczki), [meritum-marketing](https://github.com/Meritum-HackNation2026/meritum-marketing) (pitch deck, film, materiały konkursowe).

## Środowiska

| Środowisko | Gałąź | Adres | Kontenery na dellpromaxgb10 | Schematy w bazie `meritum` |
|---|---|---|---|---|
| dev | `develop` | https://meritum-dev.gburek.app | `meritum-web-dev`, `meritum-api-dev`, `meritum-worker-dev` | `api_dev`, `worker_dev` |
| prd | `main` | https://meritum.gburek.app | `meritum-web-prd`, `meritum-api-prd`, `meritum-worker-prd` | `api_prd`, `worker_prd` |

Wszystkie środowiska dzielą jeden kontener PostgreSQL (`meritum-postgres`, pgvector i pg_trgm). Każda aplikacja w każdym środowisku ma własną rolę, która widzi tylko swój schemat. Schemat workera trzyma też tabele systemowe DBOS, a rola API ma do nich dostęp, żeby zlecać zadania. Szczegóły w README meritum-infra.

## CI/CD

Każde repo aplikacji ma `.github/workflows/ci.yml` z jednym uruchomieniem na commit:

- CI (lint, typy, testy, build) działa na runnerach GCP z etykietą `meritum`, na każdej gałęzi.
- CD działa na runnerze `dellpromaxgb10`, tylko dla `develop` (dev) i `main` (prd), po zielonym CI. Deploy buduje obraz na hoście (ARM64), podmienia kontener i sprawdza go: API odpowiada na `/api/v1/health` i przepuszcza zadanie `ping` przez workera, frontend odpowiada przez gateway pod swoim adresem.

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
git add design-system infra org-profile core backend worker frontend
git commit -m "Zaktualizuj submoduły"
```

To samo robi skrypt, który od razu tworzy commit (albo nic nie robi, gdy wszystko jest aktualne):

```bash
./scripts/update-submodules.sh
git push
```

Zmiany w kodzie commituj i wypychaj w repozytorium danego submodułu. W tym repozytorium commitujesz tylko przesunięcie wskaźnika.
