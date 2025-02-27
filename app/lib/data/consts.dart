class Bank {
  final int id;
  final String name;
  final String shortName;
  final List<String> codes;
  final String image;

  const Bank({
    required this.id,
    required this.name,
    required this.shortName,
    required this.codes,
    required this.image,
  });
}

class AppConstants {
  static const List<Bank> banks = [
    Bank(
      id: 1,
      name: "Commercial Bank Of Ethiopia",
      shortName: "CBE",
      codes: ["CBE", "cbe", "889", "Commercial Bank Of Ethiopia"],
      image: "assets/images/cbe.png",
    ),
    Bank(
      id: 2,
      name: "Awash Bank",
      shortName: "Awash",
      codes: ["Awash", "Awash Bank"],
      image: "assets/images/awash.png",
    ),
    Bank(
      id: 3,
      name: "Cooperative Bank Of Oromia",
      shortName: "COOP",
      codes: ["COOP", "Cooperative Bank Of Oromia"],
      image: "assets/images/coop.png",
    ),
    Bank(
      id: 4,
      name: "Global Bank Ethiopia",
      shortName: "Global",
      codes: ["Global Bank", "Global"],
      image: "assets/images/global.png",
    ),
    Bank(
      id: 5,
      name: "Oromia International Bank",
      shortName: "OIB",
      codes: ["OIB", "Oromia International Bank"],
      image: "assets/images/oib.png",
    ),
  ];
}
