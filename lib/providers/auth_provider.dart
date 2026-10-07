import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel _currentUser = UserModel(
    uid: 'u_panha',
    name: 'នី បញ្ញា (Panha)',
    email: 'panha@bbu.edu.kh',
    role: 'ADMIN',
    shopName: 'ម៉ាត សាមគ្គី (BBU Mart POS)',
  );

  bool _isLoggedIn = true;

  UserModel get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _currentUser.role == 'ADMIN';

  // Quick switch role or member for demo convenience in BBU class presentation
  void switchDemoUser({required String name, required String role, required String email}) {
    _currentUser = UserModel(
      uid: 'u_${name.replaceAll(" ", "_").toLowerCase()}',
      name: name,
      email: email,
      role: role,
      shopName: 'ម៉ាត សាមគ្គី (BBU Mart POS)',
    );
    _isLoggedIn = true;
    notifyListeners();
  }

  void login(String email, String password) {
    if (email.contains('admin')) {
      _currentUser = UserModel(
        uid: 'u_admin',
        name: 'នី បញ្ញា (Admin)',
        email: email,
        role: 'ADMIN',
      );
    } else {
      _currentUser = UserModel(
        uid: 'u_cashier',
        name: 'គក់ ស្រីផ្កាយ (Cashier)',
        email: email,
        role: 'CASHIER',
      );
    }
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}
