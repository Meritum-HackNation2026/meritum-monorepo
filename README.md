# meritum-monorepo

Repozytorium zbiorcze projektu Meritum, obywatelskiego radaru dezinformacji (HackNation 2026, konkurs MSZ „Prawdowid”). Samo nie zawiera kodu produktu. Łączy pozostałe repozytoria organizacji jako submoduły git, przypięte do konkretnych commitów.

## Działające środowiska

### Aplikacja webowa i API

| Nazwa | Wersja | Przeznaczenie | Link |
|---|---|---|---|
| Aplikacja webowa | prd | aplikacja dla obywateli (bootstrap: stan API; docelowo formularz sprawdzania twierdzeń) | [meritum.gburek.app](https://meritum.gburek.app) |
| Aplikacja webowa | dev | aplikacja dla obywateli (bootstrap: stan API; docelowo formularz sprawdzania twierdzeń) | [meritum-dev.gburek.app](https://meritum-dev.gburek.app) |
| API | prd | dokumentacja OpenAPI (Swagger UI) | [meritum.gburek.app/api/docs](https://meritum.gburek.app/api/docs) |
| API | dev | dokumentacja OpenAPI (Swagger UI) | [meritum-dev.gburek.app/api/docs](https://meritum-dev.gburek.app/api/docs) |
| API: stan | prd | health: API, baza danych i środowisko | [meritum.gburek.app/api/v1/health](https://meritum.gburek.app/api/v1/health) |
| API: stan | dev | health: API, baza danych i środowisko | [meritum-dev.gburek.app/api/v1/health](https://meritum-dev.gburek.app/api/v1/health) |

### Makiety platform

| Nazwa | Wersja | Przeznaczenie | Link |
|---|---|---|---|
| Makieta X | prd | makieta platformy do demo wtyczki | [meritum-x.gburek.app](https://meritum-x.gburek.app) |
| Makieta Facebook | prd | makieta platformy do demo wtyczki | [meritum-facebook.gburek.app](https://meritum-facebook.gburek.app) |
| Makieta Instagram | prd | makieta platformy do demo wtyczki | [meritum-instagram.gburek.app](https://meritum-instagram.gburek.app) |
| Makieta Reddit | prd | makieta platformy do demo wtyczki | [meritum-reddit.gburek.app](https://meritum-reddit.gburek.app) |
| Makieta TikTok | prd | makieta platformy do demo wtyczki | [meritum-tiktok.gburek.app](https://meritum-tiktok.gburek.app) |

### Wtyczka Chrome

| Nazwa | Wersja | Przeznaczenie | Link |
|---|---|---|---|
| Wtyczka Chrome | prd | zip do załadowania w chrome://extensions (artefakt `meritum-extension-prd` w przebiegu CI) | [przebiegi CI na `main`](https://github.com/Meritum-HackNation2026/meritum-extension/actions/workflows/ci.yml?query=branch%3Amain+is%3Asuccess) |

### Discord

| Nazwa | Wersja | Przeznaczenie | Link |
|---|---|---|---|
| Discord: Meritum | prd | dodanie aplikacji do konta albo serwera; komendy /sprawdz i „Sprawdź w Meritum” przy wiadomości | [zainstaluj „Meritum”](https://discord.com/oauth2/authorize?client_id=1573692006398693396) |
| Discord: Meritum dev | dev | dodanie aplikacji do konta albo serwera; komendy /sprawdz i „Sprawdź w Meritum” przy wiadomości | [zainstaluj „Meritum dev”](https://discord.com/oauth2/authorize?client_id=1573690220782559332) |

`prd` wdraża się z gałęzi `main`, `dev` z gałęzi `develop` (tylko frontend, backend i worker). Makiety i wtyczka mają tylko `main`, więc nie mają już wersji dev. Worker DBOS nie ma publicznego adresu; to, że działa, widać po zadaniu `ping` w deployu API.

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
| `docs/` | [meritum-docs](https://github.com/Meritum-HackNation2026/meritum-docs) | dokumentacja aplikacji (Zensical, Cloudflare Pages) |
| `infra/` | [meritum-infra](https://github.com/Meritum-HackNation2026/meritum-infra) | runnery GitHub Actions (GCP i dellpromaxgb10) oraz wspólna platforma na dellpromaxgb10: PostgreSQL, gateway, trasy Cloudflare |
| `org-profile/` | [.github](https://github.com/Meritum-HackNation2026/.github) | publiczny profil organizacji na GitHubie (`profile/README.md`) |
| `scripts/` | (to repozytorium) | skrypty pomocnicze |

## Infrastruktura środowisk

| Środowisko | Gałąź | Kontenery na dellpromaxgb10 | Schematy w bazie `meritum` |
|---|---|---|---|
| dev | `develop` (frontend, backend, worker) | `meritum-web-dev`, `meritum-api-dev`, `meritum-worker-dev` | `api_dev`, `worker_dev` |
| prd | `main` | `meritum-web-prd`, `meritum-api-prd`, `meritum-worker-prd`, `meritum-mocks-prd` | `api_prd`, `worker_prd`, `mocks_prd` |

Kontener `meritum-mocks-dev` i schemat `mocks_dev` zostały po dawnym przepływie makiet i nie dostają nowych wersji.

Wszystkie środowiska dzielą jeden kontener PostgreSQL (`meritum-postgres`, pgvector i pg_trgm). Każda aplikacja w każdym środowisku ma własną rolę, która widzi tylko swój schemat. Schemat workera trzyma też tabele systemowe DBOS, a rola API ma do nich dostęp, żeby zlecać zadania. Szczegóły w README meritum-infra.

## CI/CD

Każde repo aplikacji ma `.github/workflows/ci.yml` z jednym uruchomieniem na commit:

- CI (lint, typy, testy, build) działa na runnerach GCP z etykietą `meritum`, na każdej gałęzi.
- CD działa na runnerze `dellpromaxgb10` po zielonym CI: `develop` na dev (frontend, backend, worker) i `main` na prd (te trzy oraz makiety). Deploy buduje obraz na hoście (ARM64), podmienia kontener i sprawdza go: API odpowiada na `/api/v1/health` i przepuszcza zadanie `ping` przez workera, frontend i makiety odpowiadają przez gateway pod swoimi adresami.
- Wtyczka nie ma serwera: na `main` CI buduje zip z adresem API prd i zostawia go jako artefakt przebiegu. Marketing nie ma CI poza skanem sekretów.

W meritum-frontend, meritum-backend i meritum-worker zmiany idą przez PR do `develop`, a wydanie przez PR `develop` → `main`. Pozostałe repozytoria mają tylko `main` i zmiany idą przez PR do `main`. Nie pushuj bezpośrednio do `develop` ani `main`. Organizacja jest na planie Free, który nie chroni gałęzi w repozytoriach prywatnych, więc pilnujemy tego sami. Gałąź funkcji usuwaj po merge'u (`gh pr merge --delete-branch`). Automatyczne usuwanie gałęzi jest wyłączone, bo w trzech repozytoriach z `develop` skasowałoby go po PR `develop` → `main`.

## Sekrety i zależności

W każdym repo działa `.github/workflows/secrets.yml`: gitleaks przegląda całą historię gita przy każdym pushu i PR, a każde znalezisko oblewa przebieg. Lokalnie ten sam gitleaks blokuje push z sekretem, zanim commit opuści komputer (hook `.githooks/pre-push`). Włącz go raz po sklonowaniu:

```bash
brew install gitleaks && scripts/setup-git-hooks.sh
```

Skrypt ustawia `core.hooksPath` w monorepo i we wszystkich submodułach. W pojedynczym repo wystarczy `git config core.hooksPath .githooks`. Fałszywy alarm dopisz z uzasadnieniem do `.gitleaks.toml` w tym repo, zamiast pushować z `--no-verify`.

Dependabot otwiera w poniedziałki PR-y z aktualizacjami według `.github/dependabot.yml`. Wersje drobne i poprawkowe trafiają do jednego PR na ekosystem. Wersji głównych ani nowego Pythona w obrazach Dependabot nie proponuje. PR idzie do domyślnej gałęzi repozytorium (`develop` we frontendzie, backendzie i workerze, `main` w pozostałych). Wersję meritum-core w backendzie i workerze podbija workflow w core, Dependabot jej nie rusza.

## Jak przetestować Meritum (jury)

Są dwie ścieżki. Żadna nie wymaga pomocy zespołu.

| Ścieżka | Co trzeba mieć | Klucze |
|---|---|---|
| Publiczne demo | przeglądarkę | żadnych |
| Lokalnie | Docker z Compose 2.24+, git, klucz SSH z dostępem do organizacji (do czasu upublicznienia meritum-core) | żadnych na stubach; własne klucze Google Cloud dla prawdziwego modelu |

### Publiczne demo

- Formularz WWW: [meritum.gburek.app](https://meritum.gburek.app). Wklej tekst albo link i kliknij „Sprawdź”.
- Discord: [zainstaluj „Meritum”](https://discord.com/oauth2/authorize?client_id=1573692006398693396), potem `/sprawdz` albo „Sprawdź w Meritum” w menu wiadomości.
- Makieta Discorda (mocks/001, główna ścieżka obok formularza): adres pojawi się w tabeli makiet wyżej, gdy makieta będzie wdrożona.
- Wtyczka Chrome (opcjonalnie, poniżej 2 minut): pobierz artefakt `meritum-extension-prd` z [ostatniego przebiegu CI na `main`](https://github.com/Meritum-HackNation2026/meritum-extension/actions/workflows/ci.yml?query=branch%3Amain+is%3Asuccess), rozpakuj, otwórz `chrome://extensions`, włącz „Tryb dewelopera”, kliknij „Załaduj rozpakowane” i wskaż katalog. Przycisk „Sprawdź” pojawi się pod postami na makietach platform.

### Lokalnie jednym poleceniem

```bash
git clone --recurse-submodules git@github.com:Meritum-HackNation2026/meritum-monorepo.git
cd meritum-monorepo
ssh-add ~/.ssh/id_ed25519    # klucz z dostępem do organizacji (meritum-core jest na razie prywatne)
cp .env.example .env         # wpisz co najmniej MERITUM_CHANNEL_HASH_SALT
docker compose up --build
```

| Adres | Co |
|---|---|
| http://localhost:8080 | aplikacja webowa z formularzem (nginx przekazuje `/api` do API) |
| http://localhost:8080/api/docs | dokumentacja API |
| http://localhost:8080/api/v1/health | test gotowości: baza, worker, brakujące zmienne |
| http://localhost:3000 | makiety platform (`/x/`, `/facebook/`, `/instagram/`, `/reddit/`, `/tiktok/`) |

`docker-compose.yml` buduje te same obrazy co dev i prd: PostgreSQL z obrazu meritum-infra (pgvector i polski słownik), worker DBOS, API, frontend i makiety. API i worker dzielą wolumen `files` na nagrania i obrazy (adapter systemu plików `BlobStore`, ADR-31). Lokalnie jedna rola bazy robi wszystko; na serwerze każda aplikacja i środowisko ma własną rolę i schemat.

Każda zmienna w `.env.example` ma opis. Bez pliku `.env` system startuje na stubach: model językowy odpowiada z `config/llm-stub.json`, a embeddingi i transkrypcja też są stubami. Prawdziwy model to `MERITUM_LLM_PROVIDER=vertex` z modelem, regionem UE i projektem Google Cloud oraz Application Default Credentials w kontenerze workera.

Gdy brakuje klucza, test gotowości wypisuje jego nazwę (nigdy wartości) w logu startu i w `/api/v1/health`, a API odpowiada na pytania stanem „Problem techniczny” zamiast werdyktu (US-BEZ-03, US-WDR-08).

Proces Gateway Discorda (backend/028) dojdzie do compose jako usługa uruchamiana tylko z tokenem bota, gdy powstanie w meritum-backend. Do tego czasu Discord działa przez endpoint interakcji API (`MERITUM_DISCORD_PUBLIC_KEY`).

### Test dymny

```bash
scripts/smoke.sh                 # zostawia system uruchomiony
SMOKE_DOWN=1 scripts/smoke.sh    # na końcu zatrzymuje compose
```

Skrypt uruchamia `docker compose up --build`, czeka na `/api/v1/health` i wysyła jedno sprawdzenie tekstu na stubie modelu, a potem czeka na wynik. Działa tylko lokalnie i ręcznie; nie należy do żadnego CI, bo wymaga kontaktu między usługami. Potrzebuje backendu i workera z endpointem `/api/v1/checks`, czyli submodułów po promocji `develop` → `main` (`scripts/update-submodules.sh`).

### Miejsce przetwarzania (rejestr podmiotów przetwarzających, ADR-14)

| Podmiot | Co przetwarza | Region | Kiedy |
|---|---|---|---|
| Google Cloud Vertex AI | tekst pytania (po maskowaniu), fragmenty źródeł; model językowy i embeddingi | UE (`europe-central2` / `europe-west4`; Londyn i Zurych odrzucane) | `MERITUM_LLM_PROVIDER=vertex`, `MERITUM_EMBEDDINGS_PROVIDER=vertex` |
| Google Cloud Sensitive Data Protection (DLP) | tekst pytania przed modelem, maskowanie danych osobowych | UE (`MERITUM_PII_LOCATION`, domyślnie Warszawa) | `MERITUM_PII_GATE=sdp` |
| Google Cloud Model Armor albo Cloudflare Workers AI | tekst pytania i źródeł, klasyfikacja wstrzyknięć poleceń | Model Armor: region UE projektu; Cloudflare: sieć globalna, poza UE | `MERITUM_INJECTION_GATE_PROVIDER` |
| Google Cloud Speech-to-Text v2 | nagrania głosowe (transkrypcja) | UE | `MERITUM_TRANSCRIPTION_PROVIDER=speech_v2` |
| Discord | wiadomości i identyfikator użytkownika kanału (u nas tylko solony skrót) | USA | kanał Discord |
| Cloudflare | ruch HTTP publicznego demo (tunel, ochrona przed DDoS) | sieć globalna | publiczne demo |

Lokalnie, na stubach, nic nie opuszcza komputera.

### Bramki przed modelem

| Bramka | Dostawca | Region | Gdy wyłączona |
|---|---|---|---|
| Maskowanie danych osobowych (DLP) | Google Sensitive Data Protection | UE | działają tylko wzorce telefonu, e-maila i PESEL-u; log zapisuje pominięcie bramki |
| Klasyfikator wstrzyknięć | Google Model Armor albo Cloudflare Workers AI | UE albo globalnie | działają wzorce PL/EN z meritum-core, treść użytkownika i źródeł trafia do modelu wyłącznie jako dane, a log zapisuje pominięcie bramki |
| Reranker | jeszcze brak (ADR-14 przewiduje dostawcę w UE) | brak | wyniki wyszukiwania zostają w kolejności z wyszukiwarki |

### Koszty, limity i zachowanie pod obciążeniem (ADR-18)

Koszt każdego sprawdzenia liczymy z tokenów i wywołań wyszukiwarki zapisanych w `CheckRecord` (US-OBS-02). Koszt 1 000 zapytań, koszt utrzymania kanałów, koszt i limity transkrypcji oraz odsetek trafień w pamięci wyników podajemy tylko zmierzone naszym skryptem ewaluacji (meritum-worker, `evals/`); do czasu pomiaru te wiersze są puste:

| Pozycja | Wartość |
|---|---|
| Koszt 1 000 zapytań (model, embeddingi, bramki, wyszukiwarka) | do pomiaru |
| Utrzymanie kanałów: WWW, wtyczka, Discord | do pomiaru |
| Transkrypcja: koszt, limit długości, retencja nagrań | do pomiaru |
| Odsetek trafień w pamięci wyników | do pomiaru |

Przy dużym ruchu: sprawdzenia idą przez kolejkę DBOS z limitem współbieżności, API liczy limity na IP, kanał i region (`MERITUM_CHECKS_PER_*_PER_MINUTE`) i próg oczekujących sprawdzeń (`MERITUM_MAX_PENDING_CHECKS`), a ponad limitem odpowiada HTTP 429 z `Retry-After` i komunikatem, nigdy werdyktem. Awaria albo brak klucza dostawcy kończy się stanem „Problem techniczny”, a nie pozornym wynikiem.

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
git add design-system infra org-profile core backend worker frontend mocks extension marketing docs
git commit -m "Zaktualizuj submoduły"
```

To samo robi skrypt, który od razu tworzy commit (albo nic nie robi, gdy wszystko jest aktualne):

```bash
./scripts/update-submodules.sh
git push
```

Zmiany w kodzie commituj i wypychaj w repozytorium danego submodułu. W tym repozytorium commitujesz tylko przesunięcie wskaźnika.
