import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../data/character/characters_data.dart';
import '../../domain/entities/character.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../chat/chat_screen.dart';
import '../locale/l10n_context.dart';

class CharacterListScreen extends StatelessWidget {
  const CharacterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppPageScaffold(
      title: context.tr('characterBrowseTitle'),
      subtitle: context.tr('characterBrowseSubtitle'),
      transparentBackground: false,
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 16, AppSpacing.pageH, AppSpacing.pageBottom),
        itemCount: characters.length,
        itemBuilder: (context, index) {
          final character = characters[index];
          return _buildCharacterCard(context, character, scheme, textTheme);
        },
      ),
    );
  }

  Widget _buildCharacterCard(
    BuildContext context,
    Character character,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    final radius = BorderRadius.circular(AppRadii.card + 8);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.listGap + 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      color: character.primaryColor.withValues(alpha: 0.04),
      child: InkWell(
        borderRadius: radius,
        onTap: () => _onCharacterTap(context, character),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card + 8)),
                  border: Border.all(
                    color: character.primaryColor.withValues(alpha: 0.22),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: character.primaryColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  image: DecorationImage(
                    image: character.imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: character.primaryColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          character.level,
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.displayNamePrimary,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (character.displayNameSecondary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      character.displayNameSecondary,
                      style: textTheme.titleSmall?.copyWith(
                        height: 1.2,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    character.description,
                    style: textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: character.interests
                        .where((interest) => interest.category == '취미')
                        .expand((interest) => interest.items)
                        .map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: character.primaryColor,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: character.primaryColor.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              item,
                              style: textTheme.labelLarge?.copyWith(
                                color: character.primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCharacterTap(BuildContext context, Character character) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          character: character,
          chatRepository: context.read<ChatRepository>(),
          aiChatRepository: context.read<AiChatRepository>(),
        ),
      ),
    );
  }
}
