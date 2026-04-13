import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/responder_with_distance.dart';

class ResponderCard extends StatelessWidget {
  final ResponderWithDistance responder;
  final VoidCallback onRequest;
  final VoidCallback? onChat;

  const ResponderCard({
    super.key,
    required this.responder,
    required this.onRequest,
    this.onChat,
  });

  Future<void> _makeCall() async {
    if (responder.phoneNumber == null) return;
    final Uri url = Uri(scheme: 'tel', path: responder.phoneNumber!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAvailable = responder.status == 'Available';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: responder.profilePhoto != null 
                  ? NetworkImage(responder.profilePhoto!) 
                  : null,
                child: responder.profilePhoto == null 
                  ? const Icon(LucideIcons.user, size: 30, color: Colors.grey)
                  : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      responder.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      responder.type.toUpperCase(),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text("${responder.distance.toStringAsFixed(1)} km away"),
                        const SizedBox(width: 12),
                        const Icon(LucideIcons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(responder.rating.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  responder.status,
                  style: TextStyle(
                    color: isAvailable ? Colors.green.shade700 : Colors.orange.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _makeCall,
                  icon: const Icon(LucideIcons.phone, size: 18),
                  label: const Text("Call"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChat,
                  icon: const Icon(LucideIcons.messageSquare, size: 18),
                  label: const Text("Chat"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isAvailable ? onRequest : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Request This Responder", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
