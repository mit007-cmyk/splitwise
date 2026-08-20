import 'package:flutter/material.dart';

/// Maps persisted `icon` keys to Material icons.
class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> _byKey = {
    'receipt': Icons.receipt_long_rounded,
    'restaurant': Icons.restaurant_rounded,
    'local_grocery_store': Icons.local_grocery_store_rounded,
    'home': Icons.home_rounded,
    'bolt': Icons.bolt_rounded,
    'directions_car': Icons.directions_car_rounded,
    'movie': Icons.movie_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'flight_takeoff': Icons.flight_takeoff_rounded,
    'payments': Icons.payments_rounded,
    'pets': Icons.pets_rounded,
    'camera': Icons.photo_camera_rounded,
    'coffee': Icons.local_cafe_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'school': Icons.school_rounded,
    'music_note': Icons.music_note_rounded,
    'sports_soccer': Icons.sports_soccer_rounded,
    'beach_access': Icons.beach_access_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'child_care': Icons.child_care_rounded,
    'build': Icons.build_rounded,
    'wifi': Icons.wifi_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'park': Icons.park_rounded,
    'spa': Icons.spa_rounded,
    'laptop': Icons.laptop_rounded,
    'hotel': Icons.hotel_rounded,
    'local_bar': Icons.local_bar_rounded,
    'cleaning_services': Icons.cleaning_services_rounded,
  };

  static const List<String> pickerKeys = [
    'receipt',
    'restaurant',
    'local_grocery_store',
    'home',
    'bolt',
    'directions_car',
    'movie',
    'local_hospital',
    'shopping_bag',
    'flight_takeoff',
    'pets',
    'camera',
    'coffee',
    'fitness_center',
    'school',
    'music_note',
    'sports_soccer',
    'beach_access',
    'card_giftcard',
    'child_care',
    'build',
    'wifi',
    'local_gas_station',
    'park',
    'spa',
    'laptop',
    'hotel',
    'local_bar',
    'cleaning_services',
  ];

  static IconData dataFor(String? iconKey) {
    if (iconKey == null || iconKey.isEmpty) {
      return Icons.receipt_long_rounded;
    }
    return _byKey[iconKey] ?? Icons.receipt_long_rounded;
  }
}
