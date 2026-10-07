import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/firestore/models/category_model.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';

class CategoryManagerDialog extends ConsumerStatefulWidget {
  const CategoryManagerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const CategoryManagerDialog(),
    );
  }

  @override
  ConsumerState<CategoryManagerDialog> createState() => _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends ConsumerState<CategoryManagerDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _isAdding = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAddCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(categoryRepositoryProvider);
      final categories = ref.read(categoriesStreamProvider).value ?? [];
      final nextSortOrder = categories.isEmpty
          ? 1
          : (categories.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1);

      await repo.createCategory(name: name, sortOrder: nextSortOrder);
      _nameController.clear();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to create category: $e');
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _handleEditCategory(CategoryModel category) async {
    final editController = TextEditingController(text: category.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('កែប្រែប្រភេទទំនិញ (Rename Category)'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'ឈ្មោះប្រភេទទំនិញ (Category Name)',
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('បោះបង់'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('រក្សាទុក'),
          ),
        ],
      ),
    );

    if (confirmed == true && editController.text.trim().isNotEmpty) {
      try {
        await ref
            .read(categoryRepositoryProvider)
            .updateCategory(category.id, name: editController.text.trim());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteCategory(CategoryModel category) async {
    final repo = ref.read(categoryRepositoryProvider);
    final inUse = await repo.isCategoryInUse(category.id);

    if (inUse) {
      final count = await repo.countProductsInCategory(category.id);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
                SizedBox(width: 8),
                Text('មិនអាចលុបបានទេ (Blocked)'),
              ],
            ),
            content: Text(
              'មិនអាចលុបប្រភេទ "${category.name}" បានទេ ព្រោះមានទំនិញចំនួន $count កំពុងប្រើប្រាស់ប្រភេទនេះ។ សូមផ្លាស់ប្តូរប្រភេទនៃទំនិញទាំងនោះជាមុនសិន។\n\n(Cannot delete category assigned to $count products).',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('យល់ព្រម (OK)'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('លុបប្រភេទទំនិញ?'),
        content: Text('តើអ្នកពិតជាចង់លុប "${category.name}" មែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('បោះបង់'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('លុប (Delete)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await repo.deleteCategory(category.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('បានលុប "${category.name}" រួចរាល់')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final allProducts = ref.watch(productsStreamProvider).value ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('គ្រប់គ្រងប្រភេទទំនិញ', style: AppTextStyles.titleLG),
                    const Text('Categories Management', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Add new category input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'ឈ្មោះប្រភេទថ្មី (e.g. នំប៉័ង Bakery)...',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _handleAddCategory(),
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  text: '+ បន្ថែម (ADD)',
                  isLoading: _isAdding,
                  onPressed: _handleAddCategory,
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Category list
            Expanded(
              child: categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Center(child: Text('គ្មានប្រភេទទំនិញទេ (No categories found)'));
                  }
                  return ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final productCount = allProducts.where((p) => p.categoryId == cat.id).length;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.category_outlined, size: 18, color: AppColors.primary),
                        ),
                        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('$productCount products', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'កែប្រែ (Edit)',
                              onPressed: () => _handleEditCategory(cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                              tooltip: 'លុប (Delete)',
                              onPressed: () => _handleDeleteCategory(cat),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
