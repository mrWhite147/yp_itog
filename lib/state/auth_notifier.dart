import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

enum Role { customer(1), manager(2), admin(3); const Role(this.level); final int level; }

class AppUser {
  final int id; 
  final String username; 
  final String fullName; 
  final Role role;
  
  AppUser({required this.id, required this.username, required this.fullName, required this.role});
  
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: int.tryParse(j['id'].toString()) ?? 0, 
    username: j['username'] ?? '', 
    fullName: j['fullName'] ?? '', 
    role: Role.values.firstWhere((e) => e.name == j['role'], orElse: () => Role.customer),
  );
  
  Map<String, dynamic> toJson() => {'id': id, 'username': username, 'fullName': fullName, 'role': role.name};
}

class AuthNotifier extends ChangeNotifier {
  final SharedPreferences _prefs;
  final Dio _dio;
  
  AppUser? _user;
  String? _token;
  DateTime? _loginTime;

  AuthNotifier(this._prefs, this._dio);

  AppUser? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _user != null;
  bool hasRole(Role requiredRole) => _user != null && _user!.role.level >= requiredRole.level;

  Future<void> restore() async {
    final tokenData = _prefs.getString('pb_token');
    final userJson = _prefs.getString('pb_user');
    final loginIso = _prefs.getString('login_time');

    if (tokenData == null || userJson == null || loginIso == null) return;

    _loginTime = DateTime.parse(loginIso);
    if (DateTime.now().difference(_loginTime!).inHours >= 24) {
      await logout(); 
      return;
    }

    _token = tokenData;
    _user = AppUser.fromJson(jsonDecode(userJson));

    try {
      await refreshTokens();
    } catch (e) {
      await logout();
    }
  }

  Future<void> login(String username, String password) async {
    final res = await _dio.post('/collections/users/auth-with-password', data: {
      'identity': username, 
      'password': password
    });
    _saveSession(res.data);
  }

  Future<void> register(String username, String password, String fullName) async {
    await _dio.post('/collections/users/records', data: {
      'username': username, 
      'password': password, 
      'passwordConfirm': password, 
      'fullName': fullName,
      'role': 'customer'
    });

    try {
      final cardNumber = 'CARD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      await _dio.post('/collections/customers/records', data: {
        'fullName': fullName,
        'email': username.contains('@') ? username : '$username@store.local',
        'card': {
          'number': cardNumber,
          'issuedAt': DateTime.now().toIso8601String(),
        }
      });
    } catch (_) {}

    await login(username, password); 
  }

  Future<void> refreshTokens() async {
    if (_token == null) return;
    try {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      final res = await _dio.post('/collections/users/auth-refresh');
      _saveSession(res.data);
    } catch (_) {
      throw Exception('Session expired');
    }
  }

  void _saveSession(Map<String, dynamic> data) {
    _token = data['token'];
    _user = AppUser.fromJson(data['record']);
    _loginTime = DateTime.now();
    
    _prefs.setString('pb_token', _token!);
    _prefs.setString('pb_user', jsonEncode(_user!.toJson()));
    _prefs.setString('login_time', _loginTime!.toIso8601String());
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null; 
    _token = null; 
    _loginTime = null;
    _prefs.remove('pb_token'); 
    _prefs.remove('pb_user'); 
    _prefs.remove('login_time');
    notifyListeners();
  }
}