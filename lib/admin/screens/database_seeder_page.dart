import 'package:flutter/material.dart';
import '../../services/simple_firebase_seeder.dart';
import '../../theme/app_theme.dart';

/// Database Migration/Seeder Page
/// Run this to populate your Firebase database with initial data
class DatabaseSeederPage extends StatefulWidget {
  const DatabaseSeederPage({super.key});

  @override
  State<DatabaseSeederPage> createState() => _DatabaseSeederPageState();
}

class _DatabaseSeederPageState extends State<DatabaseSeederPage> {
  final SimpleFirebaseSeeder _seeder = SimpleFirebaseSeeder();
  bool _isSeeding = false;
  List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
  }

  Future<void> _runSeeder() async {
    setState(() {
      _isSeeding = true;
      _logs.clear();
    });

    _addLog('🌱 Starting database seeding...');

    try {
      await _seeder.runAllSeeders();
      _addLog('✅ Database seeding completed successfully!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Database seeded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('⚠️ Warning', style: TextStyle(color: Colors.red)),
        content: const Text(
          'This will DELETE ALL DATA from your database. This action cannot be undone!\n\nAre you sure?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All Data'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSeeding = true;
      _logs.clear();
    });

    _addLog('🗑️ Clearing all data...');

    try {
      await _seeder.clearAllData();
      _addLog('✅ All data cleared!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All data cleared!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Seeder'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              '🌱 Database Seeder',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Populate your Firebase database with initial data (like Laravel migrations)',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyText,
              ),
            ),
            const SizedBox(height: 32),

            // What will be seeded
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What will be seeded:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('👥', 'Users Collection', '5 users (including 1 admin)'),
                  _buildInfoRow('🍳', 'Recipes Collection', '3 sample recipes'),
                  _buildInfoRow('⚙️', 'Settings Collection', 'API config, app settings, email templates'),
                  const SizedBox(height: 16),
                  const Text(
                    '⚠️ Note: If users already exist, they will be skipped',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.greyText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSeeding ? null : _runSeeder,
                    icon: _isSeeding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isSeeding ? 'Seeding...' : 'Run Seeder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSeeding ? null : _clearData,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Clear All Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Logs
            const Text(
              'Logs:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'No logs yet. Click "Run Seeder" to start.',
                          style: TextStyle(
                            color: AppTheme.greyText,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              _logs[index],
                              style: TextStyle(
                                color: _logs[index].contains('❌')
                                    ? Colors.red
                                    : _logs[index].contains('✅')
                                        ? Colors.green
                                        : Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Credentials Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔑 Seeded User Credentials:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Admin: admin@gourmetai.com / Admin123456',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  Text(
                    'Users: test@example.com / Test123456',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.greyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
