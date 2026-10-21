import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/book_model.dart';

/// A reader sheet allowing the customer to "Look Inside" and read a sample
/// chapter before purchasing. Features adjustable font size and reading theme
/// (Dark, Sepia, Light).
class BookSampleReaderSheet extends StatefulWidget {
  const BookSampleReaderSheet({super.key, required this.book});

  final BookModel book;

  static Future<void> show(BuildContext context, BookModel book) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookSampleReaderSheet(book: book),
    );
  }

  @override
  State<BookSampleReaderSheet> createState() => _BookSampleReaderSheetState();
}

class _BookSampleReaderSheetState extends State<BookSampleReaderSheet> {
  double _fontSize = 17.0;
  int _themeIndex = 0; // 0 = Dark Ink, 1 = Sepia Parchment, 2 = Clean Light

  static const List<Map<String, dynamic>> _themes = [
    {
      'name': 'Dark Ink',
      'bg': Color(0xFF0F172A),
      'text': Color(0xFFE2E8F0),
      'accent': AppColors.accent,
      'appbar': Color(0xFF1E293B),
    },
    {
      'name': 'Parchment',
      'bg': Color(0xFFFBF0D9),
      'text': Color(0xFF2C2216),
      'accent': Color(0xFF8B5E2B),
      'appbar': Color(0xFFEFE2C5),
    },
    {
      'name': 'Clean Light',
      'bg': Color(0xFFFFFFFF),
      'text': Color(0xFF1E293B),
      'accent': AppColors.brand,
      'appbar': Color(0xFFF8FAFC),
    },
  ];

  String _buildSampleText() {
    final title = widget.book.title;
    final author = widget.book.author;
    final desc = widget.book.description.isNotEmpty
        ? widget.book.description
        : 'An engaging journey begins in the pages that follow.';

    return '''
Chapter 1: The First Step

$desc

The morning was crisp, with mist hanging like spun silver over the quiet avenues. $author writes with a quiet conviction that immediately sets the stage for what unfolds. Every corner of the town carried the residue of long-kept secrets, and as the clock tower struck seven, a solitary figure paused beneath the stone archway.

"Some journeys are chosen," the stranger whispered, their fingers tracing the weathered leather binding of the ledger. "Others choose us, regardless of whether we feel ready to bear their weight."

To understand the mystery of $title, one must return to the events of that autumn. The documents discovered in the old archive revealed that nothing had transpired by mere coincidence. Every event, from the quietest decision to the storm that followed, was linked by an unseen thread.

The path ahead was neither clear nor forgiving, yet with every stride forward, the truth drew nearer—inevitable, compelling, and utterly transformative.

[End of free sample preview. Add $title to your cart to read the complete book!]
''';
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = _themes[_themeIndex];
    final Color bg = activeTheme['bg'] as Color;
    final Color textColor = activeTheme['text'] as Color;
    final Color accentColor = activeTheme['accent'] as Color;
    final Color appbarBg = activeTheme['appbar'] as Color;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl),
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 4),
            ],
          ),
          child: Column(
            children: [
              // ── Header Bar ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm,
                ),
                decoration: BoxDecoration(
                  color: appbarBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusXl),
                  ),
                ),
                child: Column(
                  children: [
                    // Pill handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSizes.sm),
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SAMPLE PREVIEW',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                widget.book.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Font size controls
                        IconButton(
                          tooltip: 'Smaller text',
                          icon: Icon(
                            Icons.text_fields_rounded,
                            size: 18,
                            color: textColor,
                          ),
                          onPressed: () {
                            if (_fontSize > 13) {
                              setState(() => _fontSize -= 1.5);
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Larger text',
                          icon: Icon(
                            Icons.format_size_rounded,
                            size: 24,
                            color: textColor,
                          ),
                          onPressed: () {
                            if (_fontSize < 25) {
                              setState(() => _fontSize += 1.5);
                            }
                          },
                        ),
                        // Theme toggle
                        IconButton(
                          tooltip: 'Change reading theme',
                          icon: Icon(
                            Icons.palette_outlined,
                            size: 20,
                            color: textColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _themeIndex = (_themeIndex + 1) % _themes.length;
                            });
                          },
                        ),
                        IconButton(
                          tooltip: 'Close sample',
                          icon: Icon(Icons.close_rounded, color: textColor),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Reader Content ──
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          widget.book.author.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            color: accentColor,
                            fontSize: 13,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          widget.book.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        color: textColor.withValues(alpha: 0.15),
                        thickness: 1,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _buildSampleText(),
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          color: textColor,
                          fontSize: _fontSize,
                          height: 1.7,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(AppSizes.md),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.auto_stories_rounded,
                                color: accentColor,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Want to keep reading?',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Get the full edition for ${widget.book.priceLabel}',
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
