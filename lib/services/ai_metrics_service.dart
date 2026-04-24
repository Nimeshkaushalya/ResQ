import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ai_evaluation_record.dart';

class AIMetricsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'ai_evaluations';

  // Save the evaluation to Firebase
  Future<void> saveEvaluation({
    required bool isActualEmergency,
    required bool isGeminiPredicted,
    required double geminiConfidence,
  }) async {
    try {
      final record = AIEvaluationRecord(
        id: '',
        isActualEmergency: isActualEmergency,
        isGeminiPredicted: isGeminiPredicted,
        geminiConfidence: geminiConfidence,
        timestamp: DateTime.now(),
      );
      
      await _firestore.collection(_collectionName).add(record.toMap());
    } catch (e) {
      print('Error saving AI Evaluation: $e');
      rethrow;
    }
  }

  // Fetch all evaluations and calculate metrics
  Future<Map<String, dynamic>> calculateMetrics() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      List<AIEvaluationRecord> records = snapshot.docs
          .map((doc) => AIEvaluationRecord.fromMap(doc.id, doc.data()))
          .toList();

      int tp = 0; // True Positives
      int tn = 0; // True Negatives
      int fp = 0; // False Positives
      int fn = 0; // False Negatives
      double logLossSum = 0.0;

      if (records.isEmpty) {
        return {
          "Total Data": 0,
          "Accuracy": "0.0%",
          "Precision": "0.0%",
          "Recall": "0.0%",
          "F1-Score": "0.0%",
          "Log Loss": "0.0000",
          "ROC AUC": "0.0000",
        };
      }

      for (var record in records) {
        if (record.isGeminiPredicted && record.isActualEmergency) tp++;
        if (!record.isGeminiPredicted && !record.isActualEmergency) tn++;
        if (record.isGeminiPredicted && !record.isActualEmergency) fp++;
        if (!record.isGeminiPredicted && record.isActualEmergency) fn++;

        // Log Loss calculation
        double y = record.isActualEmergency ? 1.0 : 0.0;
        double p = record.geminiConfidence;
        // prevent probability from being 0 or 1
        p = max(min(p, 1.0 - 1e-15), 1e-15);
        logLossSum += -(y * log(p) + (1 - y) * log(1 - p));
      }

      int total = records.length;
      
      double accuracy = total > 0 ? (tp + tn) / total : 0.0;
      double precision = (tp + fp) > 0 ? tp / (tp + fp) : 0.0;
      double recall = (tp + fn) > 0 ? tp / (tp + fn) : 0.0;
      double f1Score = (precision + recall) > 0 ? 2 * (precision * recall) / (precision + recall) : 0.0;
      double logLoss = total > 0 ? logLossSum / total : 0.0;
      double rocAuc = _calculateSimpleRocAuc(records);

      return {
        "Total Data": total,
        "Accuracy": "${(accuracy * 100).toStringAsFixed(1)}%",
        "Precision": "${(precision * 100).toStringAsFixed(1)}%",
        "Recall": "${(recall * 100).toStringAsFixed(1)}%",
        "F1-Score": "${(f1Score * 100).toStringAsFixed(1)}%",
        "Log Loss": logLoss.toStringAsFixed(4),
        "ROC AUC": rocAuc.toStringAsFixed(4),
      };
    } catch (e) {
      print('Error calculating metrics: $e');
      return {
        "Total Data": 0,
        "Accuracy": "Error",
        "Precision": "Error",
        "Recall": "Error",
        "F1-Score": "Error",
        "Log Loss": "Error",
        "ROC AUC": "Error",
      };
    }
  }

  double _calculateSimpleRocAuc(List<AIEvaluationRecord> records) {
    var positiveDocs = records.where((r) => r.isActualEmergency).toList();
    var negativeDocs = records.where((r) => !r.isActualEmergency).toList();

    if (positiveDocs.isEmpty || negativeDocs.isEmpty) return 0.0;

    int correctPairs = 0;
    int totalPairs = positiveDocs.length * negativeDocs.length;

    for (var p in positiveDocs) {
      for (var n in negativeDocs) {
        if (p.geminiConfidence > n.geminiConfidence) {
          correctPairs += 1;
        } else if (p.geminiConfidence == n.geminiConfidence) {
          correctPairs += 0; // Or 0.5 for ties
        }
      }
    }
    return correctPairs / totalPairs;
  }
}
