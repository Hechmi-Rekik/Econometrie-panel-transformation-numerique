# Transformation numérique et rentabilité des entreprises : économétrie des données de panel (R)

Projet individuel de méthodes quantitatives, Master Data Science for Business & Economics, IHEC Sfax (avril 2025).

## Question de recherche

> Dans quelle mesure la transformation numérique influence-t-elle la performance financière des entreprises, mesurée par le ROA ?

## Données

Panel équilibré de **100 entreprises observées sur 6 ans (2017–2022)**, soit **600 observations**.

| Variable | Rôle | Description |
|---|---|---|
| ROA | Dépendante | Rentabilité des actifs (%) |
| PROD | Explicative | Productivité des employés (output par employé) |
| INNOV | Explicative | Part du chiffre d'affaires issue de nouveaux produits |
| INVEST | Explicative | Part des investissements en technologies émergentes |
| CYBER | Explicative | Indice d'exposition aux cybermenaces |
| DEPTEC | Explicative | Dépendance vis-à-vis des fournisseurs technologiques |

Modèle estimé :

```
ROA_it = α + β1·PROD_it + β2·INNOV_it + β3·INVEST_it + β4·CYBER_it + β5·DEPTEC_it + μ_i + ε_it
```

Les données, fournies dans le cadre du cours, ne sont pas publiées dans ce dépôt.

## Démarche

1. **Estimation de 5 modèles** : MCO poolés, LSDV, Within (effets fixes), effets aléatoires, Between.
2. **Choix du modèle** :
   - test F des effets individuels (effets fixes vs MCO poolés) : F = 23,25, p < 0,001 ;
   - test de Breusch-Pagan (effets aléatoires vs MCO poolés) : χ² = 704,75, p < 0,001 ;
   - test de Hausman (effets fixes vs effets aléatoires) : χ² = 123,44, p < 0,001.
   
   → **Modèle à effets fixes retenu.**
3. **Validation des résidus** : hétéroscédasticité (Breusch-Pagan), autocorrélation (Wooldridge : χ² = 106,95, p < 0,001), multicolinéarité (VIF tous < 10).
4. **Estimation robuste** avec écarts-types **HC3**.

## Résultat principal

| Variable | t classique | t robuste (HC3) | Significatif après correction |
|---|---|---|---|
| PROD | 32,48 | 15,66 | ✅ oui (p < 0,001) |
| INNOV | 2,08 | 0,94 | non |
| INVEST | 2,71 | 1,43 | non |
| CYBER | -1,92 | -1,18 | non |
| DEPTEC | -0,87 | -0,51 | non |

Après correction de l'hétéroscédasticité et de l'autocorrélation, **seule la productivité des employés reste un déterminant significatif du ROA**. Les effets de l'innovation et des investissements technologiques, significatifs avec les écarts-types classiques, ne résistent pas à l'estimation robuste.

## Limites

- **Stationnarité non testée de façon fiable** : avec seulement T = 6 périodes par entreprise, le test IPS (Im-Pesaran-Shin) ne peut pas être conduit (`lag value larger than length of series to lag`). Cette limite est signalée plutôt que contournée.
- Un panel de 6 ans ne permet pas de capter un éventuel délai entre l'innovation et sa rentabilisation.

## Contenu du dépôt

| Fichier | Description |
|---|---|
| `analyse_panel.R` | Script R complet : préparation, estimations, tests, estimation robuste |
| `rapport_panel.pdf` | Rapport détaillé avec les sorties R et leur interprétation |

## Reproduire l'analyse

```r
install.packages(c("plm", "lmtest", "car", "tseries", "ggplot2", "dplyr", "readxl", "sandwich"))
# Placer le fichier de données dans data/ puis :
source("analyse_panel.R")
```

**Outils :** R, plm, lmtest, sandwich, car.

---
Hechmi Rekik · [LinkedIn](https://www.linkedin.com/in/hechmi-rekik-75931642b/)
