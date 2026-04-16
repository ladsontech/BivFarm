class AppConstants {
  static const String appName = 'BivFarm';

  static const List<String> bunyoroDistricts = [
    'Hoima City',
    'Hoima',
    'Masindi',
    'Kikuube',
    'Kakumiro',
    'Kibaale',
    'Kagadi',
    'Kiryandongo',
    'Buliisa',
  ];

  static const List<String> allDistricts = [
    'Hoima City',
    'Hoima',
    'Masindi',
    'Kikuube',
    'Kakumiro',
    'Kibaale',
    'Kagadi',
    'Kiryandongo',
    'Buliisa',
    'Kampala',
    'Wakiso',
    'Mukono',
    'Jinja',
    'Mbale',
    'Gulu',
    'Lira',
    'Soroti',
    'Mbarara',
    'Fort Portal',
    'Kasese',
    'Kabale',
    'Arua',
    'Moroto',
  ];

  static const Map<String, List<String>> productCategories = {
    'Produce': [
      'Maize',
      'Beans',
      'Groundnuts',
      'Soybeans',
      'Rice',
      'Coffee',
      'Cocoa',
      'Cassava',
      'Sweet potatoes',
      'Irish potatoes',
      'Sugarcane',
      'Maize flour',
      'Cassava flour',
      'Others',
    ],
    'Poultry & Livestock': [
      'Poultry',
      'Fish',
      'Pigs',
      'Goats',
      'Cattle',
      'Sheep',
      'Rabbits',
      'Others',
    ],
    'Fruits & Vegetables': [
      'Tomatoes',
      'Onions',
      'Mangoes',
      'Pineapples',
      'Oranges',
      'Cucumber',
      'Ginger',
      'Green pepper',
      'Lemons',
      'Others',
    ],
  };

  static const List<String> availabilityOptions = [
    'Available Now',
    'Available in 1 Week',
    'Available in 2 Weeks',
    'Available in 4 Weeks',
  ];

  static const List<String> quantityUnits = [
    'Kg',
    'Tonnes',
    'Bags',
    'Bunches',
    'Pieces',
    'Litres',
    'Crates',
    'Trays',
  ];

  static const List<String> bidStatuses = [
    'Pending',
    'Under Review',
    'Accepted',
    'Rejected',
    'Completed',
  ];

  static const List<String> userRoles = [
    'Farmer',
    'Buyer',
    'Agent',
    'Registry',
    'Admin',
  ];

  static const List<String> genderOptions = [
    'Male',
    'Female',
  ];

  static const List<String> userCategories = [
    'Farmer',
    'Buyer',
    'Both',
  ];

  static const List<String> inputProductTypes = [
    'Seeds',
    'Fertilizers',
    'Pesticides',
    'Farm equipment',
  ];
}
