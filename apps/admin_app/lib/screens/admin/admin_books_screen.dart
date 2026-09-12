import 'package:flutter/material.dart';

import '../../app/routes.dart';
import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/models.dart';
import 'package:dodomed_core/theme/app_colors.dart';
import 'package:dodomed_core/widgets/app_image.dart';
import 'admin_scaffold.dart';

/// Full CRUD over the premium book collection.
class AdminBooksScreen extends StatelessWidget {
  const AdminBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final books = state.books;

    return AdminScaffold(
      title: 'E-books (${books.length})',
      onBack: () => Navigator.of(context).maybePop(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.yellow,
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.adminBookForm),
        icon: const Icon(Icons.add),
        label: const Text('New book',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: books.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No books yet.\nTap “New book” — set a title, price, cover, '
                  'how many pages are free, and the page contents.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: books.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final b = books[i];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.adminBookForm, arguments: b),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AppImage(b.cover,
                                width: 52, height: 66, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.title,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(
                                  'ETB ${b.priceBirr} · '
                                  '${b.hasPdf ? 'PDF' : '${b.pageCount} pages'} · '
                                  '${b.freePages} free · ${b.subjects.length} subjects',
                                  style: TextStyle(
                                      color: Colors.black
                                          .withValues(alpha: 0.5),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _confirmDelete(context, state, b),
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.wrong),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState state, EBook b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text('“${b.title}” will be removed from the collection.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.wrong),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      state.deleteBook(b.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book deleted')),
        );
      }
    }
  }
}
