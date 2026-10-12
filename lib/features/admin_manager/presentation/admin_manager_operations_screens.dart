import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/admin_manager_models.dart';
import '../providers/admin_manager_providers.dart';
import 'manager_widgets.dart';

class AdminManagerShopsScreen extends ConsumerWidget {
  const AdminManagerShopsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shops = ref.watch(managerShopsProvider);
    return ManagerPage(
      title: 'Shops',
      description: 'Provision, monitor, and manage every Kambuja-POS shop.',
      actions: [
        FilledButton.icon(
          onPressed: () => _showProvisionShop(context, ref),
          icon: const Icon(Icons.add_business_outlined),
          label: const Text('New shop'),
        ),
      ],
      child: shops.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            managerError(error, () => ref.invalidate(managerShopsProvider)),
        data: (items) => ManagerSectionCard(
          title: '${items.length} shops',
          child: items.isEmpty
              ? const Text('No shops have been provisioned.')
              : _shopsTable(context, items),
        ),
      ),
    );
  }

  Widget _shopsTable(BuildContext context, List<ShopSummary> shops) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Shop')),
          DataColumn(label: Text('Owner')),
          DataColumn(label: Text('Plan')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Created')),
        ],
        rows: shops
            .map(
              (shop) => DataRow(
                cells: [
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (shop.address.isNotEmpty)
                          Text(
                            shop.address,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      shop.ownerEmail.isEmpty
                          ? shop.ownerName
                          : shop.ownerEmail,
                    ),
                  ),
                  DataCell(Text(shop.subscription.toUpperCase())),
                  DataCell(
                    ManagerStatusChip(
                      label: shop.status,
                      positive: shop.status == 'active',
                    ),
                  ),
                  DataCell(Text(managerDate(shop.createdAt))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class AdminManagerAdminsScreen extends ConsumerWidget {
  const AdminManagerAdminsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shops =
        ref.watch(managerShopsProvider).value ?? const <ShopSummary>[];
    final admins = ref.watch(managerAdminsProvider(null));
    return ManagerPage(
      title: 'Shop administrators',
      description: 'Review shop owners and create administrator accounts through the trusted backend.',
      actions: [
        FilledButton.icon(
          onPressed: shops.isEmpty
              ? null
              : () => _showProvisionAdmin(context, ref, shops),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('New administrator'),
        ),
      ],
      child: admins.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => managerError(
          error,
          () => ref.invalidate(managerAdminsProvider(null)),
        ),
        data: (items) => ManagerSectionCard(
          title: '${items.length} administrators',
          child: items.isEmpty
              ? const Text('No shop administrators found.')
              : _adminsTable(items),
        ),
      ),
    );
  }

  Widget _adminsTable(List<AdminOwner> admins) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Shop')),
        DataColumn(label: Text('Role')),
        DataColumn(label: Text('Status')),
      ],
      rows: admins
          .map(
            (admin) => DataRow(
              cells: [
                DataCell(Text(admin.displayName)),
                DataCell(Text(admin.email)),
                DataCell(
                  Text(admin.shopName.isEmpty ? admin.shopId : admin.shopName),
                ),
                DataCell(Text(admin.role)),
                DataCell(
                  ManagerStatusChip(
                    label: admin.active ? 'active' : 'inactive',
                    positive: admin.active,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    ),
  );
}

class AdminManagerLocationsScreen extends ConsumerWidget {
  const AdminManagerLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shops =
        ref.watch(managerShopsProvider).value ?? const <ShopSummary>[];
    final locations = ref.watch(managerLocationsProvider(null));
    return ManagerPage(
      title: 'Locations',
      description: 'Manage branches and selling locations across the platform.',
      actions: [
        FilledButton.icon(
          onPressed: shops.isEmpty
              ? null
              : () => _showLocationForm(context, ref, shops),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('New location'),
        ),
      ],
      child: locations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => managerError(
          error,
          () => ref.invalidate(managerLocationsProvider(null)),
        ),
        data: (items) => ManagerSectionCard(
          title: '${items.length} locations',
          child: items.isEmpty
              ? const Text('No locations have been configured.')
              : _locationsList(context, ref, items),
        ),
      ),
    );
  }

  Widget _locationsList(
    BuildContext context,
    WidgetRef ref,
    List<ShopLocation> locations,
  ) => Column(
    children: locations
        .map(
          (location) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              child: Icon(Icons.location_on_outlined),
            ),
            title: Text(location.name),
            subtitle: Text(
              [
                location.shopId,
                location.address,
                location.phone,
              ].where((value) => value.isNotEmpty).join(' • '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ManagerStatusChip(
                  label: location.active ? 'active' : 'inactive',
                  positive: location.active,
                ),
                IconButton(
                  tooltip: 'Delete location',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  onPressed: () async {
                    try {
                      await ref
                          .read(adminManagerServiceProvider)
                          .deleteLocation(location.id);
                      ref.invalidate(managerLocationsProvider(null));
                    } catch (error) {
                      if (context.mounted) showManagerError(context, error);
                    }
                  },
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}

class AdminManagerSubscriptionsScreen extends ConsumerWidget {
  const AdminManagerSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(managerSubscriptionsProvider);
    return ManagerPage(
      title: 'Subscriptions',
      description: 'Control plan, seat, and account status for each shop.',
      child: subscriptions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => managerError(
          error,
          () => ref.invalidate(managerSubscriptionsProvider),
        ),
        data: (items) => ManagerSectionCard(
          title: '${items.length} subscriptions',
          child: items.isEmpty
              ? const Text(
                  'Subscription records will appear after shop provisioning.',
                )
              : _subscriptionsTable(context, ref, items),
        ),
      ),
    );
  }

  Widget _subscriptionsTable(
    BuildContext context,
    WidgetRef ref,
    List<SubscriptionSummary> items,
  ) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('Shop')),
        DataColumn(label: Text('Plan')),
        DataColumn(label: Text('Seats')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Expires')),
        DataColumn(label: Text('Actions')),
      ],
      rows: items
          .map(
            (item) => DataRow(
              cells: [
                DataCell(Text(item.shopId)),
                DataCell(Text(item.plan.toUpperCase())),
                DataCell(Text('${item.seats}')),
                DataCell(
                  ManagerStatusChip(
                    label: item.status,
                    positive: item.status == 'active',
                  ),
                ),
                DataCell(Text(managerDate(item.expiresAt))),
                DataCell(
                  TextButton(
                    onPressed: () => _showSubscriptionForm(context, ref, item),
                    child: const Text('Change'),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    ),
  );
}

class AdminManagerCatalogScreen extends ConsumerWidget {
  const AdminManagerCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shops =
        ref.watch(managerShopsProvider).value ?? const <ShopSummary>[];
    final products = ref.watch(managerProductsProvider(null));
    return ManagerPage(
      title: 'Cross shop catalog',
      description: 'Search product and stock health across all shops using rule-scoped reads.',
      child: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => managerError(
          error,
          () => ref.invalidate(managerProductsProvider(null)),
        ),
        data: (items) => ManagerSectionCard(
          title: '${items.length} products',
          child: items.isEmpty
              ? const Text('No shop products are available.')
              : _catalogTable(items, shops),
        ),
      ),
    );
  }

  Widget _catalogTable(List<PlatformProduct> items, List<ShopSummary> shops) {
    final names = {for (final shop in shops) shop.id: shop.name};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Shop')),
          DataColumn(label: Text('SKU / Barcode')),
          DataColumn(label: Text('Stock')),
          DataColumn(label: Text('Price')),
        ],
        rows: items.map((item) {
          final low =
              item.lowStockThreshold > 0 &&
              item.stockQty <= item.lowStockThreshold;
          return DataRow(
            cells: [
              DataCell(Text(item.name)),
              DataCell(
                Text(
                  item.shopName.isEmpty
                      ? names[item.shopId] ?? item.shopId
                      : item.shopName,
                ),
              ),
              DataCell(
                Text(
                  [
                    item.sku,
                    item.barcode,
                  ].where((value) => value.isNotEmpty).join(' / '),
                ),
              ),
              DataCell(
                Text(
                  '${item.stockQty}',
                  style: TextStyle(
                    color: low ? AppColors.danger : null,
                    fontWeight: low ? FontWeight.bold : null,
                  ),
                ),
              ),
              DataCell(Text(managerMoney(item.salePrice))),
            ],
          );
        }).toList(),
      ),
    );
  }
}

Future<void> _showProvisionShop(BuildContext context, WidgetRef ref) async {
  final form = await showDialog<_ShopFormValue>(
    context: context,
    builder: (_) => const _ShopFormDialog(),
  );
  if (form == null || !context.mounted) return;
  try {
    await ref
        .read(adminManagerServiceProvider)
        .provisionShop(
          name: form.name,
          ownerName: form.ownerName,
          ownerEmail: form.ownerEmail,
          phone: form.phone,
          address: form.address,
        );
    ref.invalidate(managerShopsProvider);
  } catch (error) {
    if (context.mounted) showManagerError(context, error);
  }
}

Future<void> _showProvisionAdmin(
  BuildContext context,
  WidgetRef ref,
  List<ShopSummary> shops,
) async {
  final value = await showDialog<_AdminFormValue>(
    context: context,
    builder: (_) => _AdminFormDialog(shops: shops),
  );
  if (value == null || !context.mounted) return;
  try {
    await ref
        .read(adminManagerServiceProvider)
        .provisionShopAdmin(
          shopId: value.shopId,
          displayName: value.name,
          email: value.email,
          temporaryPassword: value.password,
        );
    ref.invalidate(managerAdminsProvider(null));
  } catch (error) {
    if (context.mounted) showManagerError(context, error);
  }
}

Future<void> _showLocationForm(
  BuildContext context,
  WidgetRef ref,
  List<ShopSummary> shops,
) async {
  final value = await showDialog<_LocationFormValue>(
    context: context,
    builder: (_) => _LocationFormDialog(shops: shops),
  );
  if (value == null || !context.mounted) return;
  try {
    await ref
        .read(adminManagerServiceProvider)
        .createLocation(
          shopId: value.shopId,
          name: value.name,
          address: value.address,
          phone: value.phone,
        );
    ref.invalidate(managerLocationsProvider(null));
  } catch (error) {
    if (context.mounted) showManagerError(context, error);
  }
}

Future<void> _showSubscriptionForm(
  BuildContext context,
  WidgetRef ref,
  SubscriptionSummary item,
) async {
  final value = await showDialog<_SubscriptionFormValue>(
    context: context,
    builder: (_) => _SubscriptionFormDialog(item: item),
  );
  if (value == null || !context.mounted) return;
  try {
    await ref
        .read(adminManagerServiceProvider)
        .setShopSubscription(
          shopId: item.shopId,
          plan: value.plan,
          status: value.status,
          seats: value.seats,
        );
    ref.invalidate(managerSubscriptionsProvider);
  } catch (error) {
    if (context.mounted) showManagerError(context, error);
  }
}

class _ShopFormValue {
  final String name, ownerName, ownerEmail, phone, address;
  const _ShopFormValue(
    this.name,
    this.ownerName,
    this.ownerEmail,
    this.phone,
    this.address,
  );
}

class _AdminFormValue {
  final String shopId, name, email, password;
  const _AdminFormValue(this.shopId, this.name, this.email, this.password);
}

class _LocationFormValue {
  final String shopId, name, address, phone;
  const _LocationFormValue(this.shopId, this.name, this.address, this.phone);
}

class _SubscriptionFormValue {
  final String plan, status;
  final int seats;
  const _SubscriptionFormValue(this.plan, this.status, this.seats);
}

class _ShopFormDialog extends StatefulWidget {
  const _ShopFormDialog();
  @override
  State<_ShopFormDialog> createState() => _ShopFormDialogState();
}

class _ShopFormDialogState extends State<_ShopFormDialog> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(),
      ownerName = TextEditingController(),
      ownerEmail = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController();
  @override
  void dispose() {
    name.dispose();
    ownerName.dispose();
    ownerEmail.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Provision shop'),
    content: Form(
      key: formKey,
      child: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _field(name, 'Shop name'),
              _field(ownerName, 'Owner name'),
              _field(ownerEmail, 'Owner email', email: true),
              _field(phone, 'Phone'),
              _field(address, 'Address'),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (formKey.currentState!.validate()) {
            Navigator.pop(
              context,
              _ShopFormValue(
                name.text,
                ownerName.text,
                ownerEmail.text,
                phone.text,
                address.text,
              ),
            );
          }
        },
        child: const Text('Provision'),
      ),
    ],
  );
}

class _AdminFormDialog extends StatefulWidget {
  final List<ShopSummary> shops;
  const _AdminFormDialog({required this.shops});
  @override
  State<_AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends State<_AdminFormDialog> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  String? shopId;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create administrator'),
    content: Form(
      key: formKey,
      child: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: shopId,
                decoration: const InputDecoration(labelText: 'Shop'),
                items: widget.shops
                    .map(
                      (shop) => DropdownMenuItem(
                        value: shop.id,
                        child: Text(shop.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => shopId = value),
                validator: (value) => value == null ? 'Select a shop' : null,
              ),
              _field(name, 'Full name'),
              _field(email, 'Email', email: true),
              _field(
                password,
                'Temporary password',
                required: false,
                obscure: true,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (formKey.currentState!.validate()) {
            Navigator.pop(
              context,
              _AdminFormValue(shopId!, name.text, email.text, password.text),
            );
          }
        },
        child: const Text('Create'),
      ),
    ],
  );
}

class _LocationFormDialog extends StatefulWidget {
  final List<ShopSummary> shops;
  const _LocationFormDialog({required this.shops});
  @override
  State<_LocationFormDialog> createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends State<_LocationFormDialog> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(),
      address = TextEditingController(),
      phone = TextEditingController();
  String? shopId;
  @override
  void dispose() {
    name.dispose();
    address.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New location'),
    content: Form(
      key: formKey,
      child: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: shopId,
                decoration: const InputDecoration(labelText: 'Shop'),
                items: widget.shops
                    .map(
                      (shop) => DropdownMenuItem(
                        value: shop.id,
                        child: Text(shop.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => shopId = value),
                validator: (value) => value == null ? 'Select a shop' : null,
              ),
              _field(name, 'Location name'),
              _field(address, 'Address', required: false),
              _field(phone, 'Phone', required: false),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (formKey.currentState!.validate()) {
            Navigator.pop(
              context,
              _LocationFormValue(shopId!, name.text, address.text, phone.text),
            );
          }
        },
        child: const Text('Create'),
      ),
    ],
  );
}

class _SubscriptionFormDialog extends StatefulWidget {
  final SubscriptionSummary item;
  const _SubscriptionFormDialog({required this.item});
  @override
  State<_SubscriptionFormDialog> createState() =>
      _SubscriptionFormDialogState();
}

class _SubscriptionFormDialogState extends State<_SubscriptionFormDialog> {
  late String plan = widget.item.plan, status = widget.item.status;
  late final seats = TextEditingController(
    text: '${widget.item.seats == 0 ? 1 : widget.item.seats}',
  );
  @override
  void dispose() {
    seats.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Subscription · ${widget.item.shopId}'),
    content: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: plan,
            decoration: const InputDecoration(labelText: 'Plan'),
            items: const ['trial', 'basic', 'pro', 'enterprise']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => plan = value ?? plan),
          ),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const ['active', 'paused', 'cancelled']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => status = value ?? status),
          ),
          _field(seats, 'Seats', keyboard: TextInputType.number),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          _SubscriptionFormValue(plan, status, int.tryParse(seats.text) ?? 1),
        ),
        child: const Text('Save'),
      ),
    ],
  );
}

Widget _field(
  TextEditingController controller,
  String label, {
  bool email = false,
  bool required = true,
  bool obscure = false,
  TextInputType? keyboard,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard ?? (email ? TextInputType.emailAddress : null),
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) return 'Required';
              if (email && !value.contains('@')) return 'Enter a valid email';
              return null;
            }
          : null,
    ),
  );
}
