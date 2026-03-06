import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:resq_flutter/data/first_aid_guide_data.dart';
import 'package:resq_flutter/screens/first_aid_detail_screen.dart';
import 'package:resq_flutter/services/speech_service.dart';

class FirstAidGuideScreen extends StatefulWidget {
  const FirstAidGuideScreen({super.key});

  @override
  State<FirstAidGuideScreen> createState() => _FirstAidGuideScreenState();
}

class _FirstAidGuideScreenState extends State<FirstAidGuideScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SpeechService _speechService = SpeechService();

  List<FirstAidCategory> _filteredCategories = [];
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _filteredCategories = firstAidDatabase;
    _speechService.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCategories(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCategories = firstAidDatabase;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredCategories = firstAidDatabase.where((category) {
        return category.title.toLowerCase().contains(lowerQuery) ||
            category.description.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  void _toggleVoiceSearch() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
    } else {
      bool canListen = await _speechService.initialize();
      if (!canListen) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Speech recognition not available or denied permissions.')),
        );
        return;
      }

      setState(() => _isListening = true);
      _searchController.text = "Listening...";

      await _speechService.startListening(onResult: (text) {
        setState(() {
          _searchController.text = text;
        });
        _filterCategories(text);
      }, onFinished: () {
        setState(() => _isListening = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('First Aid Guide'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(LucideIcons.wifiOff, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text('Offline Ready',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterCategories,
                    decoration: InputDecoration(
                        hintText: 'Search "Burns", "Choking"...',
                        prefixIcon:
                            const Icon(LucideIcons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0)),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _toggleVoiceSearch,
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: _isListening
                          ? Colors.red.withOpacity(0.1)
                          : const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isListening ? LucideIcons.micOff : LucideIcons.mic,
                      color: _isListening ? Colors.red : Colors.white,
                    ),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 8),

          // List Body
          Expanded(
            child: _filteredCategories.isEmpty
                ? const Center(
                    child:
                        Text('No emergency guidelines found for that query.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredCategories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final category = _filteredCategories[index];
                      return _buildCategoryCard(context, category);
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, FirstAidCategory category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FirstAidDetailScreen(category: category),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(category.icon, color: const Color(0xFFDC2626), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(category.title,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A))),
                      if (category.requiresEmergency) ...[
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.alertTriangle,
                            color: Colors.orange, size: 16),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  )
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.grey)
          ],
        ),
      ),
    );
  }
}
