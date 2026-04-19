import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:resq_flutter/services/ai_metrics_service.dart';

class AIMetricsScreen extends StatefulWidget {
  const AIMetricsScreen({super.key});

  @override
  State<AIMetricsScreen> createState() => _AIMetricsScreenState();
}

class _AIMetricsScreenState extends State<AIMetricsScreen> {
  final AIMetricsService _metricsService = AIMetricsService();
  Map<String, dynamic>? _metricsSnapshot;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final metrics = await _metricsService.calculateMetrics();
      setState(() {
        _metricsSnapshot = metrics;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('AI Performance Metrics'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loadMetrics,
            tooltip: 'Refresh Metrics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error loading metrics: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadMetrics, child: const Text('Retry'))
                    ],
                  ),
                )
              : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    if (_metricsSnapshot == null) return const SizedBox.shrink();
    
    final metrics = _metricsSnapshot!;
    final total = metrics['Total Data'];
    
    if (total == 0) {
      return const Center(
        child: Text('No evaluation data available yet. Use the photo analyzer rating feature to collect data.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMetricRow('Accuracy', metrics['Accuracy'], LucideIcons.target, const Color(0xFF10B981)),
        _buildMetricRow('Precision', metrics['Precision'], LucideIcons.crosshair, const Color(0xFF3B82F6)),
        _buildMetricRow('Recall', metrics['Recall'], LucideIcons.activity, const Color(0xFFF59E0B)),
        _buildMetricRow('F1-Score', metrics['F1-Score'], LucideIcons.award, const Color(0xFF8B5CF6)),
        const SizedBox(height: 16),
        _buildDetailedCard(metrics),
      ],
    );
  }

  Widget _buildMetricRow(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          ),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildDetailedCard(Map<String, dynamic> metrics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Advanced Metrics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildDetailRow('Total Evaluations', metrics['Total Data'].toString()),
          const Divider(color: Colors.white12, height: 24),
          _buildDetailRow('Log Loss', metrics['Log Loss']),
          const Divider(color: Colors.white12, height: 24),
          _buildDetailRow('ROC AUC', metrics['ROC AUC']),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
