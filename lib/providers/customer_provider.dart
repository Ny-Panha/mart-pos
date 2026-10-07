import 'package:flutter/material.dart';
import '../models/customer_model.dart';

class CustomerProvider extends ChangeNotifier {
  final List<CustomerModel> _customers = [
    CustomerModel(id: 'c1', name: 'សុខ ជា', phone: '012 889 900', points: 150, address: 'បាត់ដំបង'),
    CustomerModel(id: 'c2', name: 'ចាន់ ធីតា', phone: '096 778 899', points: 80, address: 'បាត់ដំបង'),
    CustomerModel(id: 'c3', name: 'កែវ រតនា', phone: '077 554 433', points: 300, address: 'សៀមរាប'),
    CustomerModel(id: 'c4', name: 'ហេង វិសាល', phone: '088 123 456', points: 45, address: 'ភ្នំពេញ'),
  ];

  List<CustomerModel> get customers => List.unmodifiable(_customers);

  void addCustomer(CustomerModel customer) {
    _customers.add(customer);
    notifyListeners();
  }

  void updateCustomer(CustomerModel customer) {
    int index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
      notifyListeners();
    }
  }

  void deductPoints(String customerId, int pointsUsed) {
    int index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      int remaining = _customers[index].points - pointsUsed;
      _customers[index] = _customers[index].copyWith(points: remaining < 0 ? 0 : remaining);
      notifyListeners();
    }
  }

  void addPoints(String customerId, int pointsEarned) {
    int index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      _customers[index] = _customers[index].copyWith(points: _customers[index].points + pointsEarned);
      notifyListeners();
    }
  }

  void deleteCustomer(String customerId) {
    _customers.removeWhere((c) => c.id == customerId);
    notifyListeners();
  }
}
