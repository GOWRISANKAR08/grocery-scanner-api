class UserProfile {
  final int id;
  final String name;
  final String email;
  final bool isDiabetic;
  final String plan;
  UserProfile({required this.id, required this.name, required this.email, required this.isDiabetic, required this.plan});
  bool get isPremium => plan == 'premium';
  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
      id: j['id'], name: j['name'], email: j['email'], isDiabetic: j['is_diabetic'] ?? false, plan: j['plan'] ?? 'free');
}

class Alternative {
  final String barcode, name;
  final String? brand, imageUrl;
  final double score;
  Alternative({required this.barcode, required this.name, this.brand, this.imageUrl, required this.score});
  factory Alternative.fromJson(Map<String, dynamic> j) => Alternative(
      barcode: j['barcode'], name: j['name'], brand: j['brand'], imageUrl: j['image_url'], score: (j['score'] as num).toDouble());
}

class Product {
  final String barcode, name, grade, summary;
  final String? brand, imageUrl;
  final double score, diabeticScore;
  final bool diabeticFriendly, locked;
  final List<String> ingredients, flags;
  final List<Map<String, dynamic>> preservatives;
  final Map<String, dynamic> nutrition;
  final List<Alternative> alternatives;

  Product({
    required this.barcode, required this.name, required this.grade, required this.summary,
    this.brand, this.imageUrl, required this.score, required this.diabeticScore,
    required this.diabeticFriendly, required this.locked, this.ingredients = const [],
    this.flags = const [], this.preservatives = const [], this.nutrition = const {}, this.alternatives = const [],
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        barcode: j['barcode'], name: j['name'], brand: j['brand'], imageUrl: j['image_url'],
        grade: j['grade'], summary: j['summary'],
        score: (j['score'] as num).toDouble(), diabeticScore: (j['diabetic_score'] as num).toDouble(),
        diabeticFriendly: j['diabetic_friendly'], locked: j['locked'],
        ingredients: List<String>.from(j['ingredients'] ?? []),
        flags: List<String>.from(j['flags'] ?? []),
        preservatives: List<Map<String, dynamic>>.from(j['preservatives'] ?? []),
        nutrition: Map<String, dynamic>.from(j['nutrition_breakdown'] ?? {}),
        alternatives: (j['alternatives'] as List? ?? []).map((e) => Alternative.fromJson(e)).toList(),
      );
}

class HistoryItem {
  final String barcode, name;
  final double score;
  final DateTime scannedAt;
  HistoryItem({required this.barcode, required this.name, required this.score, required this.scannedAt});
  factory HistoryItem.fromJson(Map<String, dynamic> j) => HistoryItem(
      barcode: j['barcode'], name: j['product_name'], score: (j['score'] as num).toDouble(), scannedAt: DateTime.parse(j['scanned_at']));
}

class TrendPoint {
  final String date;
  final double avg;
  TrendPoint(this.date, this.avg);
}
