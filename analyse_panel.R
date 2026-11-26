# ============================================================
# ANALYSE DE DONNÉES DE PANEL
# Projet : Impact de la transformation numérique sur la performance financière des entreprises
# Variable dépendante : ROA (Return on Assets)
# Variables explicatives : Productivité, Innovation, Investissements tech, Cybermenaces, Dépendance tech
# Panel : 100 entreprises x 6 années (2017-2022) = 600 observations
# ============================================================

# ---- 0. Installation et chargement des packages ----
# install.packages(c("plm", "lmtest", "car", "tseries", "ggplot2", "dplyr", "readxl", "sandwich"))

library(plm)
library(lmtest)
library(car)
library(tseries)
library(ggplot2)
library(dplyr)
library(readxl)
library(sandwich)

# ---- 1. Importation et préparation des données ----
data <- read_excel("data/Base 3_oui.xlsx", sheet = "Feuil2")  # chemin relatif au dépôt

if(nrow(data) == 0 || is.null(data)) {
  stop("❌ Erreur : Le fichier est vide ou la feuille 'Feuil2' est introuvable.")
}

# Renommer les colonnes pour simplifier
colnames(data) <- c("company", "periode", "ROA", "PROD", "INNOV", "INVEST", "CYBER", "DEPTEC")

# S'assurer que 'periode' est numérique
data$periode <- as.numeric(data$periode)

# Trier les données par entreprise et période (évite les warnings panel)
data <- data[order(data$company, data$periode), ]

# Définir le panel
pdata <- pdata.frame(data, index = c("company", "periode"))

cat("=== STRUCTURE DES DONNÉES ===\n")
cat("Nombre d'observations :", nrow(pdata), "\n")
cat("Nombre d'entreprises  :", length(unique(pdata$company)), "\n")
cat("Nombre de périodes    :", length(unique(pdata$periode)), "\n")
cat("Années couvertes      :", paste(sort(unique(pdata$periode)), collapse = ", "), "\n\n")

# ---- 2. Statistiques descriptives ----
cat("=== STATISTIQUES DESCRIPTIVES ===\n")
summary(data[, c("ROA", "PROD", "INNOV", "INVEST", "CYBER", "DEPTEC")])

# ---- 3. Visualisation des données ----
roa_moy <- data %>% group_by(periode) %>% summarise(ROA_moy = mean(ROA, na.rm=TRUE))
print(roa_moy)

# ---- 4. Tests de stationnarité (IPS) ----
# NOTE : avec T = 6 périodes par entreprise, le test IPS avec lags = "AIC"
# échoue ("lag value larger than length of series to lag").
# Cette limite est documentée dans le README et dans le rapport :
# la stationnarité n'a pas pu être testée de façon fiable sur un panel aussi court.
cat("\n=== TESTS DE STATIONNARITÉ (IPS - Im-Pesaran-Shin) ===\n")
vars_test <- c("ROA", "PROD", "INNOV", "INVEST", "CYBER", "DEPTEC")
for(v in vars_test) {
  cat("\nVariable :", v, "\n")
  tryCatch({
    test <- purtest(pdata[[v]], test = "ips", exo = "intercept", lags = "AIC")
    print(summary(test))
  }, error = function(e) cat("Erreur :", e$message, "\n"))
}

# ---- 5. Estimation des modèles de base ----
cat("\n=== ESTIMATION DES MODÈLES ===\n")

model_fe <- plm(ROA ~ PROD + INNOV + INVEST + CYBER + DEPTEC,
                data = pdata, model = "within")
cat("\n--- Modèle à Effets Fixes ---\n")
summary(model_fe)

model_re <- plm(ROA ~ PROD + INNOV + INVEST + CYBER + DEPTEC,
                data = pdata, model = "random")
cat("\n--- Modèle à Effets Aléatoires ---\n")
summary(model_re)

model_pool <- plm(ROA ~ PROD + INNOV + INVEST + CYBER + DEPTEC,
                  data = pdata, model = "pooling")
cat("\n--- Modèle Pooled OLS ---\n")
summary(model_pool)

# ---- 6. Test de Hausman ----
cat("\n=== TEST DE HAUSMAN ===\n")
hausman_test <- phtest(model_fe, model_re)
print(hausman_test)
cat("\nInterprétation : Si p-value < 0.05 → Effets fixes préférés ; sinon → Effets aléatoires\n")

# ---- 7. Tests des effets individuels ----
cat("\n=== TEST DE SIGNIFICATIVITÉ DES EFFETS INDIVIDUELS (F-test) ===\n")
print(pFtest(model_fe, model_pool))

cat("\n=== TEST DE BREUSCH-PAGAN (effets aléatoires vs Pooled) ===\n")
print(plmtest(model_pool, type = "bp"))

# ---- 8. Tests sur les résidus ----
cat("\n=== TESTS SUR LES RÉSIDUS DU MODÈLE RETENU ===\n")
if(hausman_test$p.value < 0.05) {
  modele_final <- model_fe
  cat("✅ Modèle retenu : EFFETS FIXES\n\n")
} else {
  modele_final <- model_re
  cat("✅ Modèle retenu : EFFETS ALÉATOIRES\n\n")
}

cat("--- Test d'hétéroscédasticité (Breusch-Pagan) ---\n")
print(bptest(modele_final))

cat("\n--- Test d'autocorrélation de Wooldridge ---\n")
print(pbgtest(modele_final))

# ---- 9. Estimation robuste ----
cat("\n=== ESTIMATION ROBUSTE (écarts-types HC3) ===\n")
print(coeftest(modele_final, vcov = vcovHC(modele_final, type = "HC3")))

# ---- 10. Test de multicolinéarité (VIF) ----
cat("\n=== TEST DE MULTICOLINÉARITÉ (VIF) ===\n")
ols_simple <- lm(ROA ~ PROD + INNOV + INVEST + CYBER + DEPTEC, data = data)
vif_vals <- vif(ols_simple)
print(vif_vals)
cat("\nRègle : VIF > 10 = problème de multicolinéarité\n")

# ---- 11. Résumé comparatif (VERSION CORRIGÉE) ----
cat("\n=== TABLEAU COMPARATIF DES MODÈLES ===\n")

# Liste des variables explicatives (sans l'intercepte)
vars <- c("PROD", "INNOV", "INVEST", "CYBER", "DEPTEC")

# Créer le tableau en extrayant seulement ces variables
comp_table <- data.frame(
  Variable = vars,
  Pooled_OLS = round(coef(model_pool)[vars], 4),
  Effets_Fixes = round(coef(model_fe)[vars], 4),
  Effets_Aleatoires = round(coef(model_re)[vars], 4)
)
print(comp_table, row.names = FALSE)


# ---- 12. Modèle LSDV (Dummies individuelles) ----
cat("\n=== MODÈLE LSDV ===\n")
model_lsdv_lm <- lm(ROA ~ PROD + INNOV + INVEST + CYBER + DEPTEC + factor(company), data = data)
summary(model_lsdv_lm)

cat("\n--- Effets fixes estimés (10 premières entreprises) ---\n")
effets_fixes <- fixef(model_fe)
print(head(effets_fixes, 10))
print(summary(effets_fixes))


# ---- 13. Modèle Between ----
cat("\n=== MODÈLE BETWEEN ===\n")
model_between <- plm(ROA ~ PROD + INNOV + INVEST + CYBER + DEPTEC,
                     data = pdata, model = "between")
summary(model_between)
cat("Observations (moyennes par entreprise) :", nobs(model_between), "\n")


# ---- 14. Comparaison complète (VERSION CORRIGÉE) ----
cat("\n=== TABLEAU COMPARATIF COMPLET (AVEC BETWEEN) ===\n")
comp_full <- data.frame(
  Variable = vars,
  Pooled_OLS = round(coef(model_pool)[vars], 4),
  Within_FE = round(coef(model_fe)[vars], 4),
  Random_Effects = round(coef(model_re)[vars], 4),
  Between = round(coef(model_between)[vars], 4)
)
print(comp_full, row.names = FALSE)

cat("\n=== FIN DE L'ANALYSE ===\n")
