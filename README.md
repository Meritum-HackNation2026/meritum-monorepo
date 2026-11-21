# meritum-monorepo

Repozytorium zbiorcze projektu Meritum (obywatelski radar dezinformacji oraz scamu). Samo nie zawiera kodu produktu. Łączy pozostałe repozytoria organizacji jako submoduły git, przypięte do konkretnych commitów.

## Układ

| Katalog | Repozytorium | Zawartość |
|---|---|---|
| `design-system/` | `meritum-design-system` | system projektowy, znak, tokeny, komponenty, teksty, makiety platform do demo |
| `infra/` | `meritum-infra` | infrastruktura i wdrożenie |
| `org-profile/` | `.github` | publiczny profil organizacji na GitHubie (`profile/README.md`) |
| `scripts/` | (to repozytorium) | skrypty pomocnicze |

Submoduły używają adresów SSH (`git@github.com:Meritum-HackNation2026/<repo>.git`), więc potrzebujesz klucza SSH dodanego do konta GitHub z dostępem do organizacji.

## Klonowanie

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
git add design-system infra org-profile
git commit -m "Zaktualizuj submoduły"
```

To samo robi skrypt, który od razu tworzy commit (albo nic nie robi, gdy wszystko jest aktualne):

```bash
./scripts/update-submodules.sh
git push
```

Zmiany w kodzie commituj i wypychaj w repozytorium danego submodułu. W tym repozytorium commitujesz tylko przesunięcie wskaźnika.
