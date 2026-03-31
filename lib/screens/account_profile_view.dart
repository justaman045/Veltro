import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class AccountProfileView extends ConsumerWidget {
  const AccountProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final profileDataAsync = ref.watch(userProfileDataProvider);
    
    final displayName = user?.displayName ?? 'Hi User';
    final email = user?.email ?? 'Unknown Email';
    final photoUrl = user?.photoURL;
    final creationDate = user?.metadata.creationTime?.toLocal().toString().split(' ')[0] ?? 'N/A';

    final profileData = profileDataAsync.value;
    final phone = profileData?['phone']?.toString() ?? 'Not provided';
    final age = profileData?['age']?.toString() ?? 'Not provided';
    final subscriptionStatus = profileData?['subscriptionStatus']?.toString() ?? (profileData?['isPro'] == true ? 'pro' : 'free');
    final address = profileData?['address']?.toString() ?? 'Not provided';
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Account Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 2),
                image: photoUrl != null 
                    ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) 
                    : null,
              ),
              child: photoUrl == null 
                  ? Icon(Icons.person_outline_rounded, size: 60, color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(context, 'Full Name', displayName, readOnly: true),
          const SizedBox(height: 16),
          _buildTextField(context, 'Email Address', email, readOnly: true),
          if (profileDataAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            const SizedBox(height: 16),
            _buildTextField(context, 'Phone Number', phone, readOnly: true),
            const SizedBox(height: 16),
            _buildTextField(context, 'Age', age, readOnly: true),
            const SizedBox(height: 16),
            _buildTextField(context, 'Address', address, readOnly: true),
            const SizedBox(height: 16),
            _buildTextField(context, 'Subscription Plan', subscriptionStatus.toUpperCase(), readOnly: true),
            const SizedBox(height: 16),
            _buildTextField(context, 'Account Created', creationDate, readOnly: true),
          ],
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Delete Account Trigger
          TextButton(
            onPressed: () => _showDeleteConfirmation(context, ref),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    String confirmationText = '';
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is permanent and cannot be undone. All your tasks, settings, and profile data will be erased immediately.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text('Type "DELETE" to confirm:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              onChanged: (val) => confirmationText = val,
              decoration: InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (confirmationText.trim() != 'DELETE') {
                Get.snackbar('Error', 'Please type DELETE exactly to confirm.', snackPosition: SnackPosition.BOTTOM);
                return;
              }
              
              Get.back(); // close dialog
              
              // Show loading overlay
              Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
              
              try {
                // 1. Wipe all data from Firestore
                await ref.read(dbServiceProvider).clearAllData();
                // 2. Kill the Auth token and Google session
                await ref.read(authServiceProvider).deleteAccount();
                // Close loading
                Get.back();
              } catch (e) {
                Get.back(); // Close loading
                Get.snackbar('Action Failed', e.toString().replaceAll('Exception: ', ''),
                  snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Permanently Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, String value, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withValues(alpha: 0.05) 
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.05 : 0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            readOnly: readOnly,
            controller: TextEditingController(text: value),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
