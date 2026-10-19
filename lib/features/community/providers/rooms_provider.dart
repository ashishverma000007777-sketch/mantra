import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../data/models/room_model.dart';

final roomsProvider =
    AsyncNotifierProvider<RoomsNotifier, List<RoomModel>>(RoomsNotifier.new);

class RoomsNotifier extends AsyncNotifier<List<RoomModel>> {
  @override
  Future<List<RoomModel>> build() async {
    try {
      final res = await ApiClient.instance.get('/rooms');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['data'] as List;
        return list.map((item) => RoomModel.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (_) {}
    return RoomModel.mockRooms();
  }

  Future<void> joinRoom(String roomId) async {
    try {
      await ApiClient.instance.post('/rooms/join', data: {'room_id': roomId});
    } catch (_) {}
    final rooms = state.value ?? [];
    state = AsyncData(rooms
        .map((r) => r.id == roomId
            ? RoomModel(
                id: r.id,
                name: r.name,
                description: r.description,
                emoji: r.emoji,
                type: r.type,
                memberCount: r.memberCount + 1,
                isMember: true,
                isFeatured: r.isFeatured,
                isWomenOnly: r.isWomenOnly,
                latestPost: r.latestPost,
                color: r.color,
              )
            : r)
        .toList());
  }
}
