import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';

/// Conversion `Tasting` ↔ document `tastings/{id}`.
abstract final class TastingDto {
  static Map<String, dynamic> toMap(Tasting tasting) => {
    'foodId': tasting.foodId,
    'at': Timestamp.fromDate(tasting.at),
    if (tasting.liking case final liking?) 'liking': liking.name,
    'hadReaction': tasting.hadReaction,
    if (tasting.note?.trim() case final note? when note.isNotEmpty)
      'note': note,
  };

  /// `null` (journalisé) si `foodId` ou `at` sont invalides ; `liking` inconnu lu `null`.
  static Tasting? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final foodId = data?['foodId'];
    final at = data?['at'];
    if (data == null ||
        foodId is! String ||
        foodId.isEmpty ||
        at is! Timestamp) {
      developer.log('Dégustation ${doc.id} ignorée', name: 'colette');
      return null;
    }
    final note = data['note'];
    return Tasting(
      id: doc.id,
      foodId: foodId,
      at: at.toDate(),
      liking: Liking.values.asNameMap()[data['liking']],
      hadReaction: data['hadReaction'] == true,
      note: note is String && note.isNotEmpty ? note : null,
    );
  }
}
