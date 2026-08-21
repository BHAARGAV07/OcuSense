import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SymptomSelectorItem {
  final String id;
  final String label;
  final String emoji;

  const SymptomSelectorItem({
    required this.id,
    required this.label,
    required this.emoji,
  });
}

class SymptomSelector extends StatelessWidget {
  final List<SymptomSelectorItem> items;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  const SymptomSelector({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedIds.contains(item.id);

        return InkWell(
          onTap: () {
            final updated = List<String>.from(selectedIds);
            if (isSelected) {
              updated.remove(item.id);
            } else {
              updated.add(item.id);
            }
            onChanged(updated);
          },
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
