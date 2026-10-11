import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final dio = context.read<Dio>();
      final res = await dio.get('/collections/users/records');
      setState(() {
        _users = res.data['items'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление пользователями и ролями')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, i) {
                final u = _users[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.manage_accounts, color: Colors.indigo),
                    title: Text(u['fullName'] ?? u['username'] ?? 'Без имени', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Email: ${u['email']} | Роль: ${u['role']}'),
                    trailing: Chip(
                      label: Text(u['role'] ?? 'user'),
                      backgroundColor: u['role'] == 'admin' ? Colors.red.shade100 : Colors.blue.shade100,
                    ),
                  ),
                );
              },
            ),
    );
  }
}