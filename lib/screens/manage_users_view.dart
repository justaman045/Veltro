import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';

class ManageUsersView extends ConsumerStatefulWidget {
  const ManageUsersView({super.key});

  @override
  ConsumerState<ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends ConsumerState<ManageUsersView> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final db = ref.read(dbServiceProvider);
      final users = await db.getAllUserProfiles();
      if (mounted) {
        setState(() {
          _users = users;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        Get.snackbar('Error', 'Could not load users: $e',
            snackPosition: SnackPosition.TOP, backgroundColor: Colors.redAccent,
            colorText: Colors.white, margin: const EdgeInsets.all(16),
            borderRadius: 12);
      }
    }
  }

  Future<void> _setTier(String email, String tier) async {
    final svc = ref.read(subscriptionServiceProvider);
    await svc.setTier(email, tier);
    Get.snackbar('Updated', '$email → $tier',
        snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87,
        colorText: Colors.white, margin: const EdgeInsets.all(16),
        borderRadius: 12, duration: const Duration(seconds: 2));
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Manage Users', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No users found', style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final email = user['_email']?.toString() ?? 'unknown@email.com';
                      final tier = user['tier']?.toString() ?? 'free';
                      final isAdmin = user['isAdmin'] == true;
                      final displayName = user['displayName']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                      ? Colors.amber.withValues(alpha: 0.15)
                                      : context.gradientPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isAdmin ? Icons.shield_rounded : Icons.person_outline,
                                  size: 20,
                                  color: isAdmin ? Colors.amber : context.gradientPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName.isNotEmpty ? displayName : email.split('@')[0],
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(email, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _tierColor(tier).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: tier,
                                    isDense: true,
                                    dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _tierColor(tier),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'free', child: Text('Free')),
                                      DropdownMenuItem(value: 'pro', child: Text('Pro')),
                                      DropdownMenuItem(value: 'proMax', child: Text('Pro Max')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null && val != tier) {
                                        _setTier(email, val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'proMax':
        return Colors.amber;
      case 'pro':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
