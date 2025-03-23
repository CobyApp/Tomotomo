import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/members_data.dart';
import '../../services/ai_service.dart';
import '../../viewmodels/chat_viewmodel.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          padding: EdgeInsets.only(top: statusBarHeight),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black,
                Colors.purple.shade900,
                Colors.purple.shade800,
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'NMIXX CHAT',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black87,
              Colors.black54,
              Colors.black38,
            ],
          ),
          image: DecorationImage(
            image: AssetImage('assets/images/nmixx_background.jpg'),
            fit: BoxFit.cover,
            opacity: 0.15,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7, // 카드 비율 조정
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
            ),
            itemCount: MembersData.members.length,
            itemBuilder: (context, index) {
              final member = MembersData.members[index];
              return GestureDetector(
                onTap: () {
                  final aiService = AIService();
                  final chatViewModel = ChatViewModel(aiService: aiService);
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: chatViewModel,
                        child: ChatScreen(memberId: member.id),
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: member.primaryColor.withOpacity(0.6),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 이미지
                        Hero(
                          tag: 'member-${member.id}',
                          child: Image.asset(
                            member.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // 그라데이션 오버레이
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                  member.primaryColor.withOpacity(0.7),
                                  member.primaryColor,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // 텍스트
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: TextStyle(
                                    fontFamily: 'Quicksand',
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 4,
                                        color: Colors.black45,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  member.description,
                                  style: TextStyle(
                                    fontFamily: 'Quicksand',
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    shadows: const [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 4,
                                        color: Colors.black45,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 반짝이는 효과
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            height: 8,
                            width: 8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 