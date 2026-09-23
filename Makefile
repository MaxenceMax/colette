# =============================================================================
#  Colette — Makefile
#  App iOS Flutter (suivi des soins du nouveau-né)
#  Usage : make <target>
# =============================================================================

SHELL := /bin/bash
ROOT  := $(shell pwd)

# Dossier des Cloud Functions (optionnel tant qu'il n'existe pas)
FUNCTIONS_DIR := $(ROOT)/functions

# Simulateur iOS par défaut (make run DEVICE="iPhone 17 Pro")
DEVICE ?=
DEVICE_FLAG = $(if $(DEVICE),-d "$(DEVICE)",)

# Fichiers générés (build_runner) et localisations (gen-l10n)
GEN_PATTERNS := \( -name "*.g.dart" -o -name "*.freezed.dart" \)
L10N_DIR     := $(ROOT)/lib/l10n/generated

# Colors
RESET  := \033[0m
BOLD   := \033[1m
CYAN   := \033[36m
GREEN  := \033[32m
YELLOW := \033[33m
RED    := \033[31m
DIM    := \033[2m

define section
	@printf "\n"
	@printf "$(CYAN)$(BOLD)━━━  $(1)  ━━━$(RESET)\n"
endef

define ok
	@printf "$(GREEN)✓$(RESET) $(1)\n"
endef

define info
	@printf "$(YELLOW)→$(RESET) $(1)\n"
endef


# =============================================================================
#  HELP
# =============================================================================

.DEFAULT_GOAL := help

.PHONY: help
help:
	@printf "\n"
	@printf "$(BOLD)$(CYAN)Colette — app iOS Flutter$(RESET)\n"
	@printf "$(DIM)make <target>$(RESET)\n"
	@printf "\n"
	@printf "$(BOLD)── Setup ────────────────────────────────────────────$(RESET)\n"
	@printf "  $(CYAN)get$(RESET)              flutter pub get\n"
	@printf "  $(CYAN)upgrade$(RESET)          flutter pub upgrade\n"
	@printf "  $(CYAN)outdated$(RESET)         flutter pub outdated\n"
	@printf "  $(CYAN)doctor$(RESET)           flutter doctor -v\n"
	@printf "\n"
	@printf "$(BOLD)── Clean ────────────────────────────────────────────$(RESET)\n"
	@printf "  $(CYAN)clean$(RESET)            flutter clean\n"
	@printf "  $(CYAN)nuke$(RESET)             clean + gen-clean + get + gen\n"
	@printf "  $(CYAN)reset-ios$(RESET)        clean + pod-reset\n"
	@printf "\n"
	@printf "$(BOLD)── Code generation ──────────────────────────────────$(RESET)\n"
	@printf "  $(CYAN)gen$(RESET)              build_runner build (riverpod, freezed)\n"
	@printf "  $(CYAN)gen-watch$(RESET)        build_runner watch\n"
	@printf "  $(CYAN)gen-clean$(RESET)        supprime les *.g.dart / *.freezed.dart\n"
	@printf "  $(CYAN)l10n$(RESET)             flutter gen-l10n (app_fr.arb → S)\n"
	@printf "  $(CYAN)l10n-check$(RESET)       clés ARB inutilisées dans lib/\n"
	@printf "\n"
	@printf "$(BOLD)── Qualité ──────────────────────────────────────────$(RESET)\n"
	@printf "  $(CYAN)format$(RESET)           dart format lib test\n"
	@printf "  $(CYAN)format-check$(RESET)     dart format --set-exit-if-changed\n"
	@printf "  $(CYAN)analyze$(RESET)          dart analyze (avec riverpod_lint)\n"
	@printf "  $(CYAN)fix$(RESET)              dart fix --apply\n"
	@printf "  $(CYAN)check$(RESET)            format-check + analyze + test\n"
	@printf "  $(CYAN)pre-commit$(RESET)       format + gen + analyze + test\n"
	@printf "\n"
	@printf "$(BOLD)── Tests ────────────────────────────────────────────$(RESET)\n"
	@printf "  $(CYAN)test$(RESET)             flutter test [T=<chemin ou motif>]\n"
	@printf "  $(CYAN)test-domain$(RESET)      tests des couches domain uniquement\n"
	@printf "  $(CYAN)test-coverage$(RESET)    flutter test --coverage + rapport HTML\n"
	@printf "\n"
	@printf "$(BOLD)── Run / Build iOS ──────────────────────────────────$(RESET)\n"
	@printf "  $(CYAN)devices$(RESET)          liste les simulateurs / appareils\n"
	@printf "  $(CYAN)simulator$(RESET)        ouvre le Simulateur iOS\n"
	@printf "  $(CYAN)run$(RESET)              flutter run debug [DEVICE=\"iPhone 17 Pro\"]\n"
	@printf "  $(CYAN)run-release$(RESET)      flutter run --release\n"
	@printf "  $(CYAN)build-ios$(RESET)        flutter build ipa (App Store / TestFlight)\n"
	@printf "  $(CYAN)build-ios-sim$(RESET)    flutter build ios --simulator (sans signature)\n"
	@printf "  $(CYAN)xcode$(RESET)            ouvre Runner.xcworkspace dans Xcode\n"
	@printf "  $(CYAN)pod-install$(RESET)      pod install\n"
	@printf "  $(CYAN)pod-reset$(RESET)        supprime Pods + Podfile.lock puis pod install\n"
	@printf "\n"
	@printf "$(BOLD)── Firebase ─────────────────────────────────────────$(RESET)\n"
	@printf "  $(CYAN)functions-install$(RESET) npm install dans functions/\n"
	@printf "  $(CYAN)functions-build$(RESET)  compile les Cloud Functions (TypeScript)\n"
	@printf "  $(CYAN)functions-test$(RESET)   tests des Cloud Functions\n"
	@printf "  $(CYAN)functions-deploy$(RESET) firebase deploy --only functions\n"
	@printf "  $(CYAN)firestore-deploy$(RESET) firebase deploy --only firestore (rules + indexes)\n"
	@printf "  $(CYAN)emulators$(RESET)        firebase emulators:start\n"
	@printf "\n"
	@printf "$(BOLD)── Git ──────────────────────────────────────────────$(RESET)\n"
	@printf "  $(CYAN)new-branch$(RESET)       BRANCH=<nom>  crée + push upstream\n"
	@printf "  $(CYAN)push$(RESET)             M=\"message\"  add + commit + push\n"
	@printf "\n"


# =============================================================================
#  SETUP
# =============================================================================

.PHONY: get
get:
	$(call section,flutter pub get)
	@flutter pub get
	$(call ok,Dépendances installées)

.PHONY: upgrade
upgrade:
	$(call section,flutter pub upgrade)
	@flutter pub upgrade
	$(call ok,Dépendances mises à jour)

.PHONY: outdated
outdated:
	$(call section,flutter pub outdated)
	@flutter pub outdated

.PHONY: doctor
doctor:
	$(call section,flutter doctor)
	@flutter doctor -v


# =============================================================================
#  CLEAN
# =============================================================================

.PHONY: clean
clean:
	$(call section,flutter clean)
	@flutter clean
	@rm -rf coverage
	$(call ok,Projet nettoyé)

.PHONY: nuke
nuke: clean gen-clean get gen
	$(call ok,Reset complet terminé)

.PHONY: reset-ios
reset-ios: clean pod-reset
	$(call ok,Reset iOS terminé)


# =============================================================================
#  CODE GENERATION — build_runner / gen-l10n
# =============================================================================

.PHONY: gen
gen:
	$(call section,build_runner build)
	@dart run build_runner build -d
	$(call ok,Génération terminée)

.PHONY: gen-watch
gen-watch:
	$(call section,build_runner watch)
	$(call info,Ctrl+C pour arrêter)
	@dart run build_runner watch -d

.PHONY: gen-clean
gen-clean:
	$(call section,Suppression des fichiers générés)
	@COUNT=$$(find $(ROOT)/lib $(ROOT)/test -type f $(GEN_PATTERNS) | wc -l | tr -d ' '); \
	find $(ROOT)/lib $(ROOT)/test -type f $(GEN_PATTERNS) -delete; \
	printf "  $$COUNT fichier(s) supprimé(s)\n"
	$(call ok,Fichiers générés nettoyés — relance 'make gen')

.PHONY: l10n
l10n:
	$(call section,flutter gen-l10n)
	@flutter gen-l10n
	$(call ok,Localisations générées dans $(L10N_DIR))

# Liste les clés de app_fr.arb qui ne sont référencées nulle part dans lib/
# (S.of(context).cle, s.cle, S.current.cle, .cle( pour les placeholders).
.PHONY: l10n-check
l10n-check:
	$(call section,Clés ARB inutilisées)
	@if ! command -v jq >/dev/null 2>&1; then \
		printf "$(RED)✗ jq requis (brew install jq)$(RESET)\n"; exit 1; \
	fi; \
	UNUSED=0; \
	for KEY in $$(jq -r 'keys[] | select(startswith("@") | not)' lib/l10n/app_fr.arb); do \
		if ! grep -rqE "\.$$KEY\b" --include="*.dart" --exclude-dir=generated lib; then \
			printf "  $(YELLOW)-$(RESET) $$KEY\n"; UNUSED=$$((UNUSED+1)); \
		fi; \
	done; \
	if [ $$UNUSED -eq 0 ]; then \
		printf "$(GREEN)✓$(RESET) Toutes les clés sont utilisées\n"; \
	else \
		printf "$(YELLOW)→$(RESET) $$UNUSED clé(s) non référencée(s)\n"; \
	fi


# =============================================================================
#  QUALITÉ — format / analyze
# =============================================================================

.PHONY: format
format:
	$(call section,dart format lib test)
	@dart format lib test
	$(call ok,Code formaté)

.PHONY: format-check
format-check:
	$(call section,dart format --set-exit-if-changed)
	@dart format --output=none --set-exit-if-changed lib test
	$(call ok,Formatage conforme)

# dart analyze (et non flutter analyze) : seul dart analyze exécute riverpod_lint.
.PHONY: analyze
analyze:
	$(call section,dart analyze)
	@dart analyze
	$(call ok,Analyse sans erreur)

.PHONY: fix
fix:
	$(call section,dart fix --apply)
	@dart fix --apply
	$(call ok,Corrections appliquées)

.PHONY: check
check: format-check analyze test
	$(call section,Tous les checks OK)
	$(call ok,format-check + analyze + test passés)

.PHONY: pre-commit
pre-commit: format gen analyze test
	$(call section,Prêt à commiter)
	$(call ok,format + gen + analyze + test passés)


# =============================================================================
#  TESTS
# =============================================================================

# make test                              → toute la suite
# make test T=test/features/events       → un dossier
# make test T="plan biberons"            → filtre --name (si T n'est pas un chemin)
.PHONY: test
test:
	$(call section,flutter test $(T))
	@if [ -z "$(T)" ]; then \
		flutter test; \
	elif [ -e "$(T)" ]; then \
		flutter test "$(T)"; \
	else \
		flutter test --name "$(T)"; \
	fi
	$(call ok,Tests passés)

.PHONY: test-domain
test-domain:
	$(call section,Tests domain)
	@DIRS=$$(find test/features -type d -name domain); \
	if [ -z "$$DIRS" ]; then \
		printf "$(YELLOW)→$(RESET) Aucun dossier test/features/*/domain\n"; \
	else \
		flutter test $$DIRS; \
	fi
	$(call ok,Tests domain passés)

.PHONY: test-coverage
test-coverage:
	$(call section,flutter test --coverage)
	@flutter test --coverage
	@if command -v lcov >/dev/null 2>&1; then \
		lcov --quiet --remove coverage/lcov.info \
			'**/*.g.dart' '**/*.freezed.dart' '**/l10n/generated/**' \
			-o coverage/lcov.filtered.info 2>/dev/null || cp coverage/lcov.info coverage/lcov.filtered.info; \
		genhtml coverage/lcov.filtered.info -o coverage/html --quiet; \
		printf "$(GREEN)✓$(RESET) Rapport HTML : coverage/html/index.html\n"; \
	else \
		printf "$(YELLOW)→$(RESET) lcov non installé — brew install lcov pour le rapport HTML\n"; \
	fi


# =============================================================================
#  RUN / BUILD — iOS uniquement
# =============================================================================

.PHONY: devices
devices:
	$(call section,Appareils disponibles)
	@flutter devices

.PHONY: simulator
simulator:
	$(call section,Simulateur iOS)
	@open -a Simulator
	$(call ok,Simulateur ouvert)

.PHONY: run
run:
	$(call section,flutter run debug)
	@flutter run $(DEVICE_FLAG)

.PHONY: run-release
run-release:
	$(call section,flutter run release)
	@flutter run --release $(DEVICE_FLAG)

.PHONY: build-ios
build-ios:
	$(call section,flutter build ipa)
	@flutter build ipa
	$(call ok,IPA : build/ios/ipa/)

.PHONY: build-ios-sim
build-ios-sim:
	$(call section,flutter build ios --simulator)
	@flutter build ios --simulator --debug
	$(call ok,App simulateur : build/ios/iphonesimulator/Runner.app)

.PHONY: xcode
xcode:
	$(call section,Ouverture Xcode)
	@open ios/Runner.xcworkspace

.PHONY: pod-install
pod-install:
	$(call section,pod install)
	@cd ios && pod install
	$(call ok,Pods installés)

.PHONY: pod-reset
pod-reset:
	$(call section,Reset CocoaPods)
	@cd ios && rm -rf Pods Podfile.lock && pod install --repo-update
	$(call ok,Pods réinstallés)


# =============================================================================
#  FIREBASE — Cloud Functions / Firestore
# =============================================================================
#
# Prérequis : firebase-tools (npm i -g firebase-tools), firebase login,
# plan Blaze pour les Functions. Le dossier functions/ est créé à la tâche
# Cloud Functions du plan v1 ; les cibles ci-dessous échouent proprement
# tant qu'il n'existe pas.

.PHONY: _check-functions
_check-functions:
	@if [ ! -d "$(FUNCTIONS_DIR)" ]; then \
		printf "$(RED)✗ Dossier functions/ introuvable$(RESET)\n"; \
		printf "$(DIM)  Voir docs/superpowers/specs/2026-09-21-colette-v1-design.md §7$(RESET)\n"; \
		exit 1; \
	fi

.PHONY: functions-install
functions-install: _check-functions
	$(call section,npm install — functions)
	@cd $(FUNCTIONS_DIR) && npm install
	$(call ok,Dépendances functions installées)

.PHONY: functions-build
functions-build: _check-functions
	$(call section,Build Cloud Functions)
	@cd $(FUNCTIONS_DIR) && npm run build
	$(call ok,Functions compilées)

.PHONY: functions-test
functions-test: _check-functions
	$(call section,Tests Cloud Functions)
	@cd $(FUNCTIONS_DIR) && npm test
	$(call ok,Tests functions passés)

.PHONY: functions-deploy
functions-deploy: _check-functions functions-build
	$(call section,firebase deploy --only functions)
	@firebase deploy --only functions
	$(call ok,Functions déployées)

.PHONY: firestore-deploy
firestore-deploy:
	$(call section,firebase deploy --only firestore)
	@firebase deploy --only firestore
	$(call ok,Règles et index Firestore déployés)

.PHONY: emulators
emulators:
	$(call section,firebase emulators:start)
	$(call info,Ctrl+C pour arrêter)
	@firebase emulators:start


# =============================================================================
#  GIT
# =============================================================================

.PHONY: new-branch
new-branch:
	@if [ -z "$(BRANCH)" ]; then \
		printf "$(RED)✗ Spécifie le nom de la branche$(RESET)\n"; \
		printf "$(DIM)  Usage : make new-branch BRANCH=<nom>$(RESET)\n"; \
		exit 1; \
	fi
	$(call section,Nouvelle branche $(BRANCH))
	@git checkout -b $(BRANCH)
	@git push -u origin $(BRANCH)
	$(call ok,Branche $(BRANCH) créée et upstream configuré)

.PHONY: push
push:
	@if [ -z "$(M)" ]; then \
		printf "$(RED)✗ Spécifie le message de commit$(RESET)\n"; \
		printf "$(DIM)  Usage : make push M=\"feat: votre message\"$(RESET)\n"; \
		exit 1; \
	fi
	$(call section,git add + commit + push)
	@git add .
	@git commit -m "$(M)"
	@git push
	$(call ok,Push terminé)
