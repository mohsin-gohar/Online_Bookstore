import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/snackbar_helper.dart';

/// Result of the write-review sheet.
class ReviewDraft {
  const ReviewDraft({required this.rating, required this.comment});

  final double rating;
  final String comment;
}

/// Bottom sheet for writing or editing a review.
///
/// Returns a [ReviewDraft] via `Navigator.pop`, or null when cancelled.
class WriteReviewSheet extends StatefulWidget {
  const WriteReviewSheet({
    super.key,
    this.initialRating = 0,
    this.initialComment = '',
  });

  final double initialRating;
  final String initialComment;

  static Future<ReviewDraft?> show(
    BuildContext context, {
    double initialRating = 0,
    String initialComment = '',
  }) {
    return showModalBottomSheet<ReviewDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => WriteReviewSheet(
        initialRating: initialRating,
        initialComment: initialComment,
      ),
    );
  }

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  late double _rating = widget.initialRating;
  late final TextEditingController _comment = TextEditingController(
    text: widget.initialComment,
  );

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating < 1) {
      SnackbarHelper.showWarning(context, 'Please select a star rating.');
      return;
    }
    if (_comment.text.trim().isEmpty) {
      SnackbarHelper.showWarning(context, 'Please write a short comment.');
      return;
    }
    Navigator.of(
      context,
    ).pop(ReviewDraft(rating: _rating, comment: _comment.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.xs,
        AppSizes.md,
        AppSizes.md + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.writeReview,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          Gaps.lg,

          // Star picker
          Center(
            child: RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 40,
              itemBuilder: (_, _) =>
                  const Icon(Icons.star_rounded, color: AppColors.rating),
              onRatingUpdate: (v) => setState(() => _rating = v),
            ),
          ),
          Gaps.sm,
          Text(
            _rating == 0
                ? 'Tap to rate'
                : 'You rated ${_rating.toStringAsFixed(1)} / 5',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          Gaps.lg,

          TextField(
            controller: _comment,
            maxLines: 5,
            minLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Share your thoughts about this book…',
            ),
          ),
          Gaps.sm,

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(AppStrings.cancel),
                ),
              ),
              Gaps.hSm,
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
