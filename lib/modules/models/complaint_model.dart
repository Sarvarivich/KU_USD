enum ComplaintStatus {
  pending('Kutilmoqda'),
  reviewing('Ko\'rib chiqilmoqda'),
  resolved('Hal qilindi'),
  closed('Yopilgan');

  final String displayName;
  const ComplaintStatus(this.displayName);
}

enum ComplaintPriority {
  low('Past'),
  medium('O\'rtacha'),
  high('Muhim');

  final String displayName;
  const ComplaintPriority(this.displayName);
}

class ComplaintModel {
  final String id;
  final String studentId;
  final String title;
  final String description;
  final String category;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final String? assignedTo;
  String? response;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final List<String> attachments;

  ComplaintModel({
    required this.id,
    required this.studentId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    this.assignedTo,
    this.response,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    required this.attachments,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'title': title,
      'description': description,
      'category': category,
      'status': status.name,
      'priority': priority.name,
      'assignedTo': assignedTo,
      'response': response,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'resolvedAt': resolvedAt,
      'attachments': attachments,
    };
  }

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Umumiy',
      status: _getComplaintStatus(json['status'] as String?),
      priority: _getComplaintPriority(json['priority'] as String?),
      assignedTo: json['assignedTo'] as String?,
      response: json['response'] as String?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as dynamic).toDate()
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? (json['resolvedAt'] as dynamic).toDate()
          : null,
      attachments: List<String>.from(json['attachments'] as List? ?? []),
    );
  }

  ComplaintModel copyWith({
    String? id,
    String? studentId,
    String? title,
    String? description,
    String? category,
    ComplaintStatus? status,
    ComplaintPriority? priority,
    String? assignedTo,
    String? response,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    List<String>? attachments,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      attachments: attachments ?? this.attachments,
    );
  }

  static ComplaintStatus _getComplaintStatus(String? status) {
    if (status == null) return ComplaintStatus.pending;
    try {
      return ComplaintStatus.values.firstWhere((e) => e.name == status);
    } catch (e) {
      return ComplaintStatus.pending;
    }
  }

  static ComplaintPriority _getComplaintPriority(String? priority) {
    if (priority == null) return ComplaintPriority.medium;
    try {
      return ComplaintPriority.values.firstWhere((e) => e.name == priority);
    } catch (e) {
      return ComplaintPriority.medium;
    }
  }
}
