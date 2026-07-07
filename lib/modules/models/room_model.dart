import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomStatus {
  empty('Boʻsh'),
  occupied('Band'),
  paymentPending('Toʻlov kutilmoqda'),
  renovation('Taʼmirlashda');

  final String displayName;
  const RoomStatus(this.displayName);
}

class RoomModel {
  final String id;
  final int roomNumber;
  final int floor;
  final int capacity;
  final int currentOccupants;
  final RoomStatus status;
  final List<String> amenities; // UI va model ichida 'amenities' bo'lib qoladi
  final List<String> studentIds;
  final double pricePerMonth;
  final DateTime? lastPaymentDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RoomModel({
    required this.id,
    required this.roomNumber,
    required this.floor,
    required this.capacity,
    required this.currentOccupants,
    required this.status,
    required this.amenities,
    required this.studentIds,
    required this.pricePerMonth,
    this.lastPaymentDate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  // Qulaylik uchun getter'lar
  int get floorNumber => floor;
  int get currentOccupancy => currentOccupants;
  double get monthlyRate => pricePerMonth;
  List<String> get occupants => studentIds;

  // Firestore'ga yozish uchun Map'ga o'girish
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      'floor': floor,
      'capacity': capacity,
      'currentOccupants': currentOccupants,
      'status': status.name,
      // ⚠️ DIQQAT: Agar bazada 'facilities' ishlatilgan bo'lsa, ikkala kalitga ham moslik uchun:
      'amenities': amenities,
      'facilities':
          amenities, // Kod xato bermasligi va bazaga to'g'ri yozilishi uchun
      'studentIds': studentIds,
      'pricePerMonth': pricePerMonth,
      'lastPaymentDate':
          lastPaymentDate != null ? Timestamp.fromDate(lastPaymentDate!) : null,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Firestore'dan kelgan JSON ma'lumotni obyektga o'girish
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String? ?? '',
      roomNumber: json['roomNumber'] is int
          ? json['roomNumber'] as int
          : int.tryParse(json['roomNumber']?.toString() ?? '') ?? 0,
      floor: json['floor'] is int
          ? json['floor'] as int
          : json['floorNumber'] is int
              ? json['floorNumber'] as int
              : int.tryParse(json['floor']?.toString() ?? '') ?? 0,
      capacity: json['capacity'] as int? ?? 0,
      currentOccupants: json['currentOccupants'] as int? ??
          json['currentOccupancy'] as int? ??
          0,
      status: _getRoomStatus(json['status'] as String?),

      // ⚠️ FIRESTORE MOSLIGI: Agar bazada 'facilities' bo'lsa ham, 'amenities' bo'lsa ham xavfsiz o'qiydi
      amenities: List<String>.from(
          json['amenities'] as List? ?? json['facilities'] as List? ?? []),

      studentIds: List<String>.from(
          json['studentIds'] as List? ?? json['occupants'] as List? ?? []),
      pricePerMonth:
          (json['pricePerMonth'] as num? ?? json['monthlyRate'] as num? ?? 0)
              .toDouble(),

      // Timestamp'larni xavfsiz tarzda DateTime'ga o'tkazish
      lastPaymentDate: json['lastPaymentDate'] != null
          ? (json['lastPaymentDate'] as dynamic).toDate()
          : null,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as dynamic).toDate()
          : null,
    );
  }

  RoomModel copyWith({
    String? id,
    int? roomNumber,
    int? floor,
    int? capacity,
    int? currentOccupants,
    RoomStatus? status,
    List<String>? amenities,
    List<String>? studentIds,
    double? pricePerMonth,
    DateTime? lastPaymentDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      floor: floor ?? this.floor,
      capacity: capacity ?? this.capacity,
      currentOccupants: currentOccupants ?? this.currentOccupants,
      status: status ?? this.status,
      amenities: amenities ?? this.amenities,
      studentIds: studentIds ?? this.studentIds,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static RoomStatus _getRoomStatus(String? status) {
    if (status == null) return RoomStatus.empty;
    try {
      return RoomStatus.values.firstWhere((e) => e.name == status);
    } catch (e) {
      return RoomStatus.empty;
    }
  }
}
