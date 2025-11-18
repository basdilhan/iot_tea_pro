import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentProvider with ChangeNotifier {
  double _pricePerKg = 100.0; // Default price LKR per kg
  bool _isLoaded = false;

  double get pricePerKg => _pricePerKg;

  Future<void> loadPrice() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _pricePerKg = prefs.getDouble('price_per_kg') ?? 100.0;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setPrice(double price) async {
    _pricePerKg = price;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('price_per_kg', price);
    notifyListeners();
  }

  double calculateEarnings(double weight) {
    return weight * _pricePerKg;
  }
}
