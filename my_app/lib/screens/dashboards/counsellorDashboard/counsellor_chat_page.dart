import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/api_utils.dart';
import '../../../optimizations/api_cache.dart';
import 'counsellor_chatting_page.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class ChatPage extends StatefulWidget {
  final String counsellorId;
  final Future<void> Function() onSignOut;

  ChatPage({required this.counsellorId, required this.onSignOut});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> allChats = [];
  List<Map<String, dynamic>> visibleChats = [];
  List<StreamSubscription> _chatListeners = [];
  final ScrollController _scrollController = ScrollController();
  final Map<String, Timer> _debounceTimers = {};
  final String cacheKey = 'counsellor_chat_cache';
  bool isLoading = true;
  int visibleLimit = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCachedChats();
    _fetchChats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final sub in _chatListeners) {
      sub.cancel();
    }
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        visibleChats.length < allChats.length) {
      setState(() {
        visibleLimit += 10;
        visibleChats = allChats.take(visibleLimit).toList();
      });
    }
  }

  Future<void> _loadCachedChats() async {
    final cached = await ApiCache.get(cacheKey);
    if (cached != null && mounted) {
      final list = List<Map<String, dynamic>>.from(json.decode(cached));
      setState(() {
        allChats = list;
        visibleChats = list.take(visibleLimit).toList();
        isLoading = false;
      });
      _listenToRealtimeMessages(allChats);
    }
  }

  Future<void> _fetchChats() async {
    try {
      final res = await http.get(Uri.parse(
          '${ApiUtils.baseUrl}/api/counsellor/${widget.counsellorId}'));
      if (res.statusCode != 200) throw Exception('Failed to fetch chat list');

      final data = json.decode(res.body);
      final chatList = List<Map<String, dynamic>>.from(
          data['chatIdsCreatedForCounsellor'] ?? []);
      List<Map<String, dynamic>> fetchedChats = [];

      for (final chat in chatList) {
        final userId = chat['user2'];
        final chatId = chat['chatId'];

        final userRes =
            await http.get(Uri.parse('${ApiUtils.baseUrl}/api/user/$userId'));
        if (userRes.statusCode != 200) continue;

        final user = json.decode(userRes.body);
        final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}';
        final photoUrl = user['photo'] ?? 'https://via.placeholder.com/150';
        final role = user['role'] ?? 'user';

        Map<String, dynamic> chatInfo = {
          'chatId': chatId,
          'userId': userId,
          'name': name,
          'photoUrl': photoUrl,
          'role': role,
        };

        try {
          final msgRes = await http
              .get(Uri.parse('${ApiUtils.baseUrl}/api/chats/$chatId/messages'));
          if (msgRes.statusCode == 200) {
            final messages = json.decode(msgRes.body);
            if (messages.isNotEmpty) {
              final last = messages.last;
              final ts = last['timestamp'];
              final senderId = last['senderId'] ?? '';
              final isSeen = last['isSeen'] ?? true;

              String text = last['text'] ?? 'Media';
              if (last['text'] == null && last['fileType'] != null) {
                final type = last['fileType'];
                text = type.startsWith('image/')
                    ? '📷 Image'
                    : type.startsWith('video/')
                        ? '🎥 Video'
                        : '📄 File';
              }

              chatInfo.addAll({
                'lastMessage': text,
                'timestampRaw': ts,
                'timestamp': DateFormat('dd MMM, h:mm a')
                    .format(DateTime.fromMillisecondsSinceEpoch(ts)),
                'isSeen': isSeen,
                'senderId': senderId,
              });
            }
          }
        } catch (_) {}

        fetchedChats.add(chatInfo);
      }

      fetchedChats.sort(
          (a, b) => (b['timestampRaw'] ?? 0).compareTo(a['timestampRaw'] ?? 0));
      await ApiCache.set(cacheKey, json.encode(fetchedChats));

      if (!mounted) return;
      setState(() {
        allChats = fetchedChats;
        visibleChats = fetchedChats.take(visibleLimit).toList();
        isLoading = false;
      });

      _listenToRealtimeMessages(fetchedChats);
    } catch (e) {
      print("❌ Chat fetch error: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _listenToRealtimeMessages(List<Map<String, dynamic>> chats) {
    for (final chat in chats) {
      final chatId = chat['chatId'];
      final ref = FirebaseDatabase.instance.ref('chats/$chatId/messages');

      final sub1 =
          ref.onChildAdded.listen((e) => _debouncedUpdate(chatId, e.snapshot));
      final sub2 = ref.onChildChanged
          .listen((e) => _debouncedUpdate(chatId, e.snapshot));

      _chatListeners.addAll([sub1, sub2]);
    }
  }

  void _debouncedUpdate(String chatId, DataSnapshot snap) {
    _debounceTimers[chatId]?.cancel();
    _debounceTimers[chatId] =
        Timer(Duration(milliseconds: 150), () => _updateChat(chatId, snap));
  }

  void _updateChat(String chatId, DataSnapshot snapshot) {
    if (!mounted) return;
    final msg = Map<String, dynamic>.from(snapshot.value as Map);
    final index = allChats.indexWhere((c) => c['chatId'] == chatId);
    if (index == -1) return;

    final chat = allChats[index];
    final ts = msg['timestamp'];
    final isSeen = msg['isSeen'] ?? true;
    final senderId = msg['senderId'] ?? '';

    String text = msg['text'] ?? 'Media';
    if (msg['text'] == null && msg['fileType'] != null) {
      final type = msg['fileType'];
      text = type.startsWith('image/')
          ? '📷 Image'
          : type.startsWith('video/')
              ? '🎥 Video'
              : '📄 File';
    }

    chat['lastMessage'] = text;
    chat['timestampRaw'] = ts;
    chat['timestamp'] = DateFormat('dd MMM, h:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(ts));
    chat['isSeen'] = isSeen;
    chat['senderId'] = senderId;

    allChats.removeAt(index);
    allChats.insert(0, chat);

    setState(() {
      visibleChats = allChats.take(visibleLimit).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Chats")),
      body: isLoading
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.deepOrange, size: 50))
          : visibleChats.isEmpty
              ? Center(child: Text("No chats found"))
              : ListView.separated(
                  controller: _scrollController,
                  itemCount: visibleChats.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (context, i) {
                    final chat = visibleChats[i];
                    return ListTile(
                      leading: CircleAvatar(
                          backgroundImage: NetworkImage(chat['photoUrl'])),
                      title: Text(chat['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(chat['lastMessage'] ?? '',
                              overflow: TextOverflow.ellipsis),
                          Text(chat['timestamp'] ?? '',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      trailing: (chat['isSeen'] == false &&
                              chat['senderId'] != widget.counsellorId)
                          ? Icon(Icons.circle, size: 10, color: Colors.blue)
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChattingPage(
                              itemName: chat['name'],
                              userId: chat['userId'],
                              counsellorId: widget.counsellorId,
                              onSignOut: widget.onSignOut,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
