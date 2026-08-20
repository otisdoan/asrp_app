import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/user_model.dart';

/// Bubble tin nhắn chat.
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final double maxWidthFraction;
  final Function(String)? onSuggestionTap;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.maxWidthFraction = 0.72,
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    // Tách phần gợi ý (bắt đầu bằng 💡) và dùng Regex bóc tách các chuỗi trong dấu nháy đơn '...'
    final parts = text.split('💡');
    List<String> suggestions = [];
    if (parts.length > 1 && !isUser) {
      final suggestionText = parts[1];
      final matches = RegExp(r"'([^']+)'").allMatches(suggestionText);
      suggestions = matches.map((m) => m.group(1)!).where((s) => s.trim().isNotEmpty).toList();
    }

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width * maxWidthFraction),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isUser
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color:
                isUser ? null : const Color(0xFFFFFDFB),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 20),
            ),
            border: isUser
                ? null
                : Border.all(
                    color: const Color(0xFFFFE5DA), width: 1.0),
            boxShadow: isUser
                ? [
                    BoxShadow(
                      color:
                          AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.015),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: isUser
                  ? Colors.white
                  : const Color(0xFF1F2937),
            ),
          ),
        ),

        // Auto-rendered Interactive Action Chips below AI response
        if (suggestions.isNotEmpty && !isUser && onSuggestionTap != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: suggestions.map((suggestion) {
              return ActionChip(
                avatar: const Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                label: Text(
                  suggestion,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25), width: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onPressed: () => onSuggestionTap!(suggestion),
              );
            }).toList(),
          ),
        ]
      ],
    );
  }
}

/// Avatar người dùng (có fallback về initials).
class UserAvatar extends StatelessWidget {
  final UserModel? user;

  const UserAvatar({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    if (user != null &&
        user!.avatar != null &&
        user!.avatar!.isNotEmpty) {
      if (user!.avatar!.startsWith('http') ||
          user!.avatar!.startsWith('https')) {
        return Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(left: 8, top: 2),
          child: ClipOval(
            child: Image.network(
              user!.avatar!,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _InitialsAvatar(user: user),
            ),
          ),
        );
      }
    }
    return _InitialsAvatar(user: user);
  }
}

class _InitialsAvatar extends StatelessWidget {
  final UserModel? user;

  const _InitialsAvatar({this.user});

  @override
  Widget build(BuildContext context) {
    final String initial =
        user != null && user!.displayName.isNotEmpty
            ? user!.displayName.trim().substring(0, 1).toUpperCase()
            : 'U';

    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(left: 8, top: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border:
            Border.all(color: const Color(0xFFFFE5DA), width: 1.0),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// AI Avatar (dùng app_icon).
class AiAvatar extends StatelessWidget {
  const AiAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(right: 8, top: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/icons/app_icon.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Chips gợi ý câu hỏi nhanh.
class SuggestiveChips extends StatelessWidget {
  final List<dynamic>? recommendations;
  final void Function(String) onChipTap;

  const SuggestiveChips({
    super.key,
    this.recommendations,
    required this.onChipTap,
  });

  @override
  Widget build(BuildContext context) {
    final chips = (recommendations != null &&
            recommendations!.isNotEmpty)
        ? recommendations!.cast<String>()
        : [
            'Cho tôi chi nhánh bán món Bún Bò Huế ngon, rẻ nhất',
            'Phở bò ngon Quận 1',
            'Có món nước gì rẻ không?'
          ];

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips.map((chipText) {
          return ActionChip(
            avatar: const Icon(Icons.auto_awesome,
                size: 12, color: Color(0xFFEA580C)),
            label: Text(
              chipText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
            onPressed: () => onChipTap(chipText),
            backgroundColor: const Color(0xFFFFF4F0),
            side: const BorderSide(
                color: Color(0xFFFFECE2), width: 0.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            materialTapTargetSize:
                MaterialTapTargetSize.shrinkWrap,
          );
        }).toList(),
      ),
    );
  }
}
