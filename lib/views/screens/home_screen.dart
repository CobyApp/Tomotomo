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
    return Scaffold(
      appBar: AppBar(
        title: const Text('NMIXX 채팅'),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/nmixx_background.jpg'),
            fit: BoxFit.cover,
            opacity: 0.2,
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: MembersData.members.length,
          itemBuilder: (context, index) {
            final member = MembersData.members[index];
            return GestureDetector(
              onTap: () {
                // 새로운 AIService와 ChatViewModel 생성
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
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.asset(
                          member.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: member.primaryColor,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 