import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';
import 'pricing_view.dart';

class AccountProfileView extends ConsumerStatefulWidget {
  const AccountProfileView({super.key});

  @override
  ConsumerState<AccountProfileView> createState() => _AccountProfileViewState();
}

class _AccountProfileViewState extends ConsumerState<AccountProfileView> {
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  bool _saving = false;
  bool _populated = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _populateFromProfile(Map<String, dynamic>? data) {
    if (_populated || data == null) return;
    _populated = true;
    _phoneController.text = data['phone']?.toString() ?? '';
    _ageController.text = data['age']?.toString() ?? '';
    _addressController.text = data['address']?.toString() ?? '';
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    try {
      await ref.read(dbServiceProvider).saveProfileData({
        'phone': _phoneController.text.trim(),
        'age': _ageController.text.trim(),
        'address': _addressController.text.trim(),
      });
      ref.invalidate(userProfileDataProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final profileDataAsync = ref.watch(userProfileDataProvider);
    final tier = ref.watch(tierProvider).valueOrNull ?? 'free';
    final isPro = tier == 'pro' || tier == 'proMax';

    final displayName = user?.displayName ?? 'Hi User';
    final email = user?.email ?? 'Unknown Email';
    final photoUrl = user?.photoURL;
    final creationDate = user?.metadata.creationTime?.toLocal().toString().split(' ')[0] ?? 'N/A';

    final profileData = profileDataAsync.value;
    _populateFromProfile(profileData);

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
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [context.gradientPrimary.withValues(alpha: 0.1), context.gradientSecondary.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                border: Border.all(color: context.gradientPrimary.withValues(alpha: 0.3), width: 2),
                image: photoUrl != null ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
              ),
              child: photoUrl == null ? Icon(Icons.person_outline_rounded, size: 60, color: context.gradientPrimary) : null,
            ),
          ),
          const SizedBox(height: 24),

          _buildReadOnlyField(context, 'Full Name', displayName),
          const SizedBox(height: 16),
          _buildReadOnlyField(context, 'Email Address', email),

          if (profileDataAsync.isLoading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
          else if (profileDataAsync.hasError)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_off, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('Could not load profile data', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            )
          else ...[
            const SizedBox(height: 16),
            _buildEditableField(context, 'Phone Number', _phoneController, hint: '+1 (555) 000-0000', keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildEditableField(context, 'Age', _ageController, hint: 'Your age', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildEditableField(context, 'Address', _addressController, hint: 'Your address'),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Get.to(() => const PricingView()),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isPro
                      ? LinearGradient(colors: [context.gradientPrimary.withValues(alpha: 0.1), context.gradientSecondary.withValues(alpha: 0.1)])
                      : context.subtleGradient,
                  border: Border.all(
                    color: isPro
                        ? context.gradientPrimary.withValues(alpha: 0.3)
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Subscription Plan', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          tier == 'proMax' ? 'Pro Max' : isPro ? 'Pro' : 'Free',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isPro ? context.gradientPrimary : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPro ? context.gradientPrimary.withValues(alpha: 0.15) : context.gradientPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPro ? 'Manage' : 'Upgrade',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.gradientPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildReadOnlyField(context, 'Account Created', creationDate),
          ],

          const SizedBox(height: 32),

          // Save Changes
          GestureDetector(
            onTap: _saving ? null : _saveChanges,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [context.gradientPrimary, context.gradientSecondary],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

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

  Widget _buildReadOnlyField(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: context.subtleGradient,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Text(value, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        ),
      ],
    );
  }

  Widget _buildEditableField(BuildContext context, String label, TextEditingController controller, {String hint = '', TextInputType? keyboardType}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: context.subtleGradient,
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black26),
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _reauthenticate(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return false;

    final hasGoogle = user.providerData.any((p) => p.providerId == 'google.com');
    final hasPassword = user.providerData.any((p) => p.providerId == 'password');

    if (hasGoogle) {
      try {
        await ref.read(authServiceProvider).reauthenticateWithGoogle();
        return true;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Google re-authentication failed: ${e.toString().replaceAll("Exception: ", "")}')),
          );
        }
        return false;
      }
    }

    if (hasPassword) {
      String? password;
      final result = await Get.dialog<String>(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Re-authentication Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please enter your password to confirm your identity before deleting your account.', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                onChanged: (val) => password = val,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(result: null), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Get.back(result: password),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (result == null || result.trim().isEmpty) return false;
      try {
        await ref.read(authServiceProvider).reauthenticateWithPassword(result.trim());
        return true;
      } catch (e) {
        Get.snackbar('Re-authentication Failed', e.toString().replaceAll('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
        return false;
      }
    }

    return false;
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setDialogState) {
          String confirmationText = '';
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This action is permanent and cannot be undone. All your tasks, settings, and profile data will be erased immediately.', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                const Text('Type "DELETE" to confirm:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (val) => setDialogState(() => confirmationText = val),
                  decoration: InputDecoration(
                    hintText: 'DELETE',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
              TextButton(
                onPressed: confirmationText.trim() != 'DELETE' ? null : () async {
                  Get.back();
                  Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                  try {
                    await ref.read(dbServiceProvider).clearAllData();
                    final auth = ref.read(authServiceProvider);
                    try {
                      await auth.deleteAccount();
                    } catch (e) {
                      if (e.toString().contains('requires-recent-login')) {
                        Get.back();
                        if (!context.mounted) return;
                        final reauthed = await _reauthenticate(context, ref);
                        if (!reauthed) {
                          Get.snackbar('Account Not Deleted', 'Re-authentication was cancelled or failed.',
                            snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
                          return;
                        }
                        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                        await auth.deleteAccount();
                      } else {
                        rethrow;
                      }
                    }
                    Get.back();
                  } catch (e) {
                    Get.back();
                    Get.snackbar('Action Failed', e.toString().replaceAll('Exception: ', ''),
                      snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('Permanently Delete', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
