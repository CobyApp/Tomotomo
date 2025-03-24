import 'package:flutter/material.dart';
import '../../models/character.dart';

class CharacterProfileDialog extends StatelessWidget {
  final Character character;

  const CharacterProfileDialog({
    Key? key,
    required this.character,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 캐릭터 이미지
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  character.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이름과 나이
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${character.name} (${character.nameKanji})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: character.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${character.age}세 (${character.schoolYear})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 성격
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: character.traits.map((trait) => Chip(
                      label: Text(trait.trait),
                      backgroundColor: character.primaryColor.withOpacity(0.1),
                      labelStyle: TextStyle(color: character.primaryColor),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  // 관심사
                  _buildSection(
                    context,
                    '관심사',
                    character.interests.map((interest) =>
                      '• ${interest.category}: ${interest.items.join(", ")}'
                    ).toList(),
                  ),
                  const SizedBox(height: 16),
                  // 외형
                  _buildSection(
                    context,
                    '외형',
                    [
                      '${character.hairColor} ${character.hairStyle}',
                      '${character.eyeColor} 눈동자',
                      character.outfit,
                      '액세서리: ${character.accessories.join(", ")}',
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            item,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        )),
      ],
    );
  }
} 