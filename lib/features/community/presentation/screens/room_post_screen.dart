import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RoomPostScreen extends StatelessWidget {
  final String roomId, postId;
  const RoomPostScreen({super.key, required this.roomId, required this.postId});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(backgroundColor: Colors.transparent),
    body: Center(child: Text('Post $postId in Room $roomId')),
  );
}
