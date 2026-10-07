import 'package:flutter/material.dart';

class TeamInfoScreen extends StatelessWidget {
  const TeamInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ព័ត៌មានគម្រោង និងសមាជិកក្រុម'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade800,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_rounded, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ប្រព័ន្ធគ្រប់គ្រងការលក់នៅម៉ាត',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Mart Point of Sale (POS) & Inventory System',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Build Bright University (BBU) • Year 4 Semester 2',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Team Members Section
            const Text(
              '👥 សមាជិកក្រុម (Team Members):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _buildMemberCard(
              number: '1',
              khmerName: 'គុយ ដាលី',
              role: 'UI/UX & Testing',
              icon: Icons.person_outline,
              color: Colors.teal,
            ),
            const SizedBox(height: 10),
            _buildMemberCard(
              number: '2',
              khmerName: 'គក់ ស្រីផ្កាយ',
              role: 'Database & Firestore Flow',
              icon: Icons.person_pin_circle_outlined,
              color: Colors.purple,
            ),
            const SizedBox(height: 10),
            _buildMemberCard(
              number: '3',
              khmerName: 'នី បញ្ញា',
              role: 'Full-stack & Flutter Logic Lead',
              icon: Icons.laptop_mac_rounded,
              color: Colors.blueAccent,
            ),

            const SizedBox(height: 20),

            // Technology Stack Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.code_rounded, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text('បច្ចេកវិទ្យាប្រើប្រាស់ (Tech Stack):',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildTechRow('Frontend App', 'Flutter 3.47 (Dart)'),
                    _buildTechRow('Backend / DB', 'Google Firebase (Cloud Firestore & Auth)'),
                    _buildTechRow('Architecture', 'Provider State Management + Repository Pattern'),
                    _buildTechRow('Key Features', 'POS Cart, Barcode Search, Dual Currency (USD/៛), KHQR'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard({
    required String number,
    required String khmerName,
    required String role,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          child: Text(number, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(
          khmerName,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(role, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
        trailing: Icon(icon, color: color),
      ),
    );
  }

  Widget _buildTechRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
