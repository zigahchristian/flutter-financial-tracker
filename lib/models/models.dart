class Sale {
  final int? id;
  final DateTime date;
  final String description;
  final double amount;
  final String category;

  Sale({
    this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
      'amount': amount,
      'category': category,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      amount: map['amount'] as double,
      category: map['category'],
    );
  }
}

class Expense {
  final int? id;
  final DateTime date;
  final String description;
  final double amount;
  final String category;

  Expense({
    this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
      'amount': amount,
      'category': category,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      amount: map['amount'] as double,
      category: map['category'],
    );
  }
}

class BusinessOwner {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String businessName;
  final String address;
  final DateTime createdAt;

  BusinessOwner({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.businessName,
    required this.address,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'businessName': businessName,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BusinessOwner.fromMap(Map<String, dynamic> map) {
    return BusinessOwner(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      businessName: map['businessName'],
      address: map['address'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  BusinessOwner copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? businessName,
    String? address,
    DateTime? createdAt,
  }) {
    return BusinessOwner(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}