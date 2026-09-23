import 'dart:convert';

import 'package:colette/features/diversification/data/dtos/food_catalog_dto.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';

/// Petit catalogue représentatif : une règle avoid, des sources divergentes,
/// une précaution de préparation, des allergènes.
const catalogFixtureJson = '''
{
  "version": 1,
  "reviewedAt": "2026-09-23",
  "sources": {
    "oms": { "label": "OMS 2023", "url": "https://www.who.int/publications/i/item/9789240081864" },
    "anses": { "label": "Anses 2019", "url": "https://www.anses.fr/fr/system/files/NUT2017SA0145.pdf" },
    "spf": { "label": "SPF 2021", "url": "https://www.mangerbouger.fr" }
  },
  "guide": {
    "phases": {
      "preparation": { "mealsSummary": "Lait uniquement", "items": [ { "text": "Lait maternel ou infantile.", "sources": ["oms"] } ] },
      "months6To8": { "mealsSummary": "2 à 3 repas", "items": [ { "text": "Purées lisses puis écrasées.", "sources": ["oms", "spf"] } ] },
      "months9To11": { "mealsSummary": "3 à 4 repas", "items": [ { "text": "Haché fin, morceaux fondants.", "sources": ["oms"] } ] },
      "months12To23": { "mealsSummary": "3 à 4 repas", "items": [ { "text": "Plats familiaux.", "sources": ["oms"] } ] }
    },
    "readinessSigns": [ { "text": "Tient sa tête et son dos droits.", "sources": ["spf"] } ],
    "hungerSigns": [ { "text": "Ouvre la bouche.", "sources": ["spf"] } ],
    "satietySigns": [ { "text": "Tourne la tête.", "sources": ["spf"] } ],
    "safety": [ { "text": "Toujours assis et surveillé.", "sources": ["spf"] } ]
  },
  "foods": [
    { "id": "carotte", "name": "Carotte", "group": "vitaminAFruitsVeg" },
    { "id": "brocoli", "name": "Brocoli", "group": "otherFruitsVeg" },
    { "id": "pates", "name": "Pâtes", "group": "grainsRootsTubers", "allergens": ["gluten"] },
    { "id": "oeuf-cuit", "name": "Œuf bien cuit", "group": "eggs", "allergens": ["eggs"] },
    { "id": "miel", "name": "Miel", "group": "outsideGroups", "rules": [
      { "kind": "avoid", "untilMonths": 12, "sources": ["oms", "anses"], "text": "Risque de botulisme infantile." }
    ] },
    { "id": "lait-de-vache", "name": "Lait de vache (boisson)", "group": "dairy", "allergens": ["milk"], "rules": [
      { "kind": "info", "sources": ["oms"], "text": "L'OMS l'accepte dès 6 mois." },
      { "kind": "avoid", "untilMonths": 12, "sources": ["anses", "spf"], "text": "Pas comme boisson principale avant 1 an." }
    ] },
    { "id": "raisin", "name": "Raisin", "group": "otherFruitsVeg", "rules": [
      { "kind": "prepare", "untilMonths": 60, "sources": ["spf"], "text": "Couper en quatre, retirer les pépins." }
    ] },
    { "id": "arachide", "name": "Arachide (poudre, pâte)", "group": "legumesNutsSeeds", "allergens": ["peanut"], "rules": [
      { "kind": "prepare", "untilMonths": 60, "sources": ["spf"], "text": "Jamais entière : en pâte ou en poudre." }
    ] }
  ]
}
''';

/// [catalogFixtureJson] décodé.
FoodCatalog catalogFixture() => FoodCatalogDto.fromJson(
  jsonDecode(catalogFixtureJson) as Map<String, dynamic>,
);
