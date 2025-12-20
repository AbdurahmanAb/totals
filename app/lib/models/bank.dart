class Bank {
  final int id;
  final String name;
  final String shortName;
  final List<String> codes;
  final String image;
  final int? maskPattern;
  final bool? uniformMasking;
  final bool? simBased;

  Bank({
    required this.id,
    required this.name,
    required this.shortName,
    required this.codes,
    required this.image,
    this.maskPattern,
    this.uniformMasking,
    this.simBased,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'],
      name: json['name'],
      shortName: json['shortName'],
      codes: json['codes'] != null ? List<String>.from(json['codes']) : [],
      image: json['image'],
      maskPattern: json['maskPattern'],
      uniformMasking: json['uniformMasking'],
      simBased: json['simBased'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'codes': codes,
      'image': image,
      'maskPattern': maskPattern,
      'uniformMasking': uniformMasking,
      'simBased': simBased,
    };
  }
}
