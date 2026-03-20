import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Higa/models/brew.dart';
import 'package:Higa/screens/home/brew_tile.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  @override
  Widget build(BuildContext context) {
    final brews = Provider.of<List<Brew>>(context) ?? [];

    return ListView.builder(
      itemCount: brews.length,
      itemBuilder: (context, index) {
        final brew = brews[index];
        return BrewTile(brew: brew);
      },
    );
  }
}

