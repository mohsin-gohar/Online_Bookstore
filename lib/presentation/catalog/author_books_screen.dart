import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/author_model.dart';
import '../../data/models/book_model.dart';
import '../../data/repositories/author_repository.dart';
import '../../data/repositories/book_repository.dart';
import '../common_widgets/book_card.dart';
import '../common_widgets/empty_state.dart';
import '../common_widgets/loading_indicator.dart';

/// Screen displaying an author's profile and all their books in the catalogue.
/// Satisfies the functional requirement: "Books should be categorized by genres and authors."
class AuthorBooksScreen extends StatefulWidget {
  const AuthorBooksScreen({super.key, required this.authorName, this.authorId});

  final String authorName;
  final String? authorId;

  @override
  State<AuthorBooksScreen> createState() => _AuthorBooksScreenState();
}

class _AuthorBooksScreenState extends State<AuthorBooksScreen> {
  AuthorModel? _author;
  List<BookModel> _books = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authorRepo = context.read<AuthorRepository>();
      final bookRepo = context.read<BookRepository>();

      // Try finding author record
      AuthorModel? foundAuthor;
      if (widget.authorId != null && widget.authorId!.isNotEmpty) {
        foundAuthor = await authorRepo.getAuthor(widget.authorId!);
      }
      if (foundAuthor == null) {
        final matches = await authorRepo.searchAuthors(widget.authorName);
        if (matches.isNotEmpty) {
          foundAuthor = matches.firstWhere(
            (a) => a.name.toLowerCase() == widget.authorName.toLowerCase(),
            orElse: () => matches.first,
          );
        }
      }

      // Load books by this author
      List<BookModel> books = [];
      if (foundAuthor != null && foundAuthor.id.isNotEmpty) {
        books = await authorRepo.getBooksByAuthor(foundAuthor.id);
      }
      if (books.isEmpty) {
        final pageResult = await bookRepo.queryBooks(
          BookQuery(searchTerm: widget.authorName, pageSize: 50),
        );
        books = pageResult.items
            .where(
              (b) => b.author.toLowerCase().contains(
                widget.authorName.toLowerCase(),
              ),
            )
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _author =
            foundAuthor ??
            AuthorModel(
              id: widget.authorId ?? '',
              name: widget.authorName,
              bio: 'Acclaimed author published in the Folio collection.',
              bookCount: books.length,
            );
        _books = books;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.authorName),
      ),
      body: _loading
          ? const FullScreenLoader()
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.danger,
                      size: 48,
                    ),
                    Gaps.md,
                    Text(_error!, textAlign: TextAlign.center),
                    Gaps.md,
                    ElevatedButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.md),
                children: [
                  // ── Author Header Card ──
                  Card(
                    elevation: 0,
                    color: Theme.of(context).cardTheme.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: AppColors.accent.withValues(
                              alpha: 0.2,
                            ),
                            backgroundImage:
                                _author?.photoUrl.isNotEmpty == true
                                ? CachedNetworkImageProvider(_author!.photoUrl)
                                : null,
                            child: _author?.photoUrl.isEmpty != false
                                ? Text(
                                    _author?.initials ?? 'A',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  )
                                : null,
                          ),
                          Gaps.sm,
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _author?.name ?? widget.authorName,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Gaps.xs,
                              const Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: AppColors.verified,
                              ),
                            ],
                          ),
                          Gaps.xs,
                          Text(
                            '${_books.length} ${_books.length == 1 ? "Book" : "Books"} Available',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_author?.bio.isNotEmpty == true) ...[
                            Gaps.md,
                            Text(
                              _author!.bio,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    height: 1.5,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Gaps.lg,

                  // ── Section Title ──
                  Row(
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      Gaps.xs,
                      Text(
                        'Published Books',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Gaps.md,

                  // ── Books Grid ──
                  if (_books.isEmpty)
                    const EmptyState(
                      icon: Icons.auto_stories_rounded,
                      title: 'No books found',
                      message: 'No books listed for this author yet.',
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: AppSizes.sm,
                            mainAxisSpacing: AppSizes.sm,
                          ),
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        return BookCard(
                          book: book,
                          onTap: () =>
                              context.push(AppRoutes.bookDetails(book.id)),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
