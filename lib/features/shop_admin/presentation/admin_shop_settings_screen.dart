import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/page_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_shop_provider.dart';
import '../services/admin_shop_service.dart';

class AdminShopSettingsScreen extends ConsumerStatefulWidget {
  const AdminShopSettingsScreen({super.key});
  @override
  ConsumerState<AdminShopSettingsScreen> createState() =>
      _AdminShopSettingsScreenState();
}

class _AdminShopSettingsScreenState
    extends ConsumerState<AdminShopSettingsScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _taxEnabled = false;
  String _currency = 'KHR';
  bool _initialised = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save(ShopSettingsModel current) async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    try {
      await ref
          .read(adminShopServiceProvider)
          .saveSettings(
            user,
            ShopSettingsModel(
              shopId: current.shopId,
              shopName: _name.text,
              phone: _phone.text,
              address: _address.text,
              currency: _currency,
              taxEnabled: _taxEnabled,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop settings saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save settings: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(adminShopSettingsProvider);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: settings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(
            'Unable to load settings: $e',
            style: const TextStyle(color: AppColors.danger),
          ),
          data: (current) {
            if (!_initialised) {
              _name.text = current.shopName;
              _phone.text = current.phone;
              _address.text = current.address;
              _currency = current.currency;
              _taxEnabled = current.taxEnabled;
              _initialised = true;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeader(
                  eyebrow: 'Shop admin',
                  title: 'Shop settings',
                  description: 'Manage the details shown on receipts and operational reports.',
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Shop name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _address,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _currency,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'KHR',
                            child: Text('KHR (៛)'),
                          ),
                          DropdownMenuItem(
                            value: 'USD',
                            child: Text('USD (\$)'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _currency = value ?? 'KHR'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enable tax on reports'),
                        value: _taxEnabled,
                        onChanged: (value) =>
                            setState(() => _taxEnabled = value),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: () => _save(current),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save settings'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
