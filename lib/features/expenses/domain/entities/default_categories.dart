import 'app_category.dart';
import 'category_source.dart';

/// Built-in categories stored once under `Splitwise/categories`.
///
/// Display names stay compatible with existing expenses and icon matching.
class DefaultCategories {
  DefaultCategories._();

  static const general = AppCategory(
    id: 'general',
    name: 'General',
    iconKey: 'receipt',
    source: CategorySource.defaultSource,
  );

  static const food = AppCategory(
    id: 'food',
    name: 'Food & Dining',
    iconKey: 'restaurant',
    source: CategorySource.defaultSource,
  );

  static const groceries = AppCategory(
    id: 'groceries',
    name: 'Groceries',
    iconKey: 'local_grocery_store',
    source: CategorySource.defaultSource,
  );

  static const home = AppCategory(
    id: 'home',
    name: 'Home',
    iconKey: 'home',
    source: CategorySource.defaultSource,
  );

  static const utilities = AppCategory(
    id: 'utilities',
    name: 'Utilities',
    iconKey: 'bolt',
    source: CategorySource.defaultSource,
  );

  static const transportation = AppCategory(
    id: 'transportation',
    name: 'Transportation',
    iconKey: 'directions_car',
    source: CategorySource.defaultSource,
  );

  static const entertainment = AppCategory(
    id: 'entertainment',
    name: 'Entertainment',
    iconKey: 'movie',
    source: CategorySource.defaultSource,
  );

  static const health = AppCategory(
    id: 'health',
    name: 'Health',
    iconKey: 'local_hospital',
    source: CategorySource.defaultSource,
  );

  static const shopping = AppCategory(
    id: 'shopping',
    name: 'Shopping',
    iconKey: 'shopping_bag',
    source: CategorySource.defaultSource,
  );

  static const travel = AppCategory(
    id: 'travel',
    name: 'Travel',
    iconKey: 'flight_takeoff',
    source: CategorySource.defaultSource,
  );

  /// Not shown in the picker; used when recording a settlement.
  static const settlement = AppCategory(
    id: 'settlement',
    name: 'Settlement',
    iconKey: 'payments',
    source: CategorySource.defaultSource,
  );

  static const List<AppCategory> all = [
    general,
    food,
    groceries,
    home,
    utilities,
    transportation,
    entertainment,
    health,
    shopping,
    travel,
    settlement,
  ];

  static const List<AppCategory> forPicker = [
    general,
    food,
    groceries,
    home,
    utilities,
    transportation,
    entertainment,
    health,
    shopping,
    travel,
  ];

  static final Set<String> ids = {for (final category in all) category.id};

  static AppCategory? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final category in all) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// Resolves a legacy name-only expense to a default category when possible.
  static AppCategory? byName(String? name) {
    final needle = name?.trim().toLowerCase() ?? '';
    if (needle.isEmpty) return general;
    for (final category in all) {
      if (category.name.toLowerCase() == needle) return category;
    }
    if (needle == 'food') return food;
    return null;
  }
}
