// lib/core/models/models.dart
// Single file housing all data models for simplicity.

// ── User ──────────────────────────────────────────────────────────────────
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) {
    return UserModel(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: j['name']?.toString() ?? 'User',
      email: j['email']?.toString() ?? '',
      phone: (j['phone'] ?? j['mobile'])?.toString(),
      avatar: j['avatar']?.toString(),
      createdAt: j['created_at'] != null 
          ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar': avatar,
        'created_at': createdAt.toIso8601String(),
      };
}

// ── University ────────────────────────────────────────────────────────────
class UniversityModel {
  final int id;
  final String name;
  final String? shortName;
  final String? logo;
  final String? city;
  final int coursesCount;

  const UniversityModel({
    required this.id,
    required this.name,
    this.shortName,
    this.logo,
    this.city,
    this.coursesCount = 0,
  });

  factory UniversityModel.fromJson(Map<String, dynamic> j) => UniversityModel(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name']?.toString() ?? 'Unknown University',
        shortName: j['short_name']?.toString(),
        logo: j['logo']?.toString(),
        city: j['city']?.toString(),
        coursesCount: (j['courses_count'] ?? j['coursesCount'] ?? j['total_courses'] ?? (j['courses'] is List ? (j['courses'] as List).length : 0)) as int? ?? 0,
      );
}

// ── Course ────────────────────────────────────────────────────────────────
class CourseModel {
  final int id;
  final int universityId;
  final String name;
  final String? description;
  final String? shortName;
  final int semestersCount;

  const CourseModel({
    required this.id,
    required this.universityId,
    required this.name,
    this.description,
    this.shortName,
    this.semestersCount = 0,
  });

  factory CourseModel.fromJson(Map<String, dynamic> j) => CourseModel(
        id: (j['id'] as num?)?.toInt() ?? 0,
        universityId: (j['university_id'] as num?)?.toInt() ?? 0,
        name: j['name']?.toString() ?? '',
        description: j['description']?.toString(),
        shortName: j['short_name']?.toString(),
        semestersCount: (j['semesters_count'] ?? j['semestersCount'] ?? j['total_semesters'] ?? (j['semesters'] is List ? (j['semesters'] as List).length : 0)) as int? ?? 0,
      );
}

// ── Semester ──────────────────────────────────────────────────────────────
class SemesterModel {
  final int id;
  final int courseId;
  final String name;
  final int semesterNumber;
  final String? summary;
  final int papersCount;
  final bool isSubscribed;
  final bool isActive;

  const SemesterModel({
    required this.id,
    required this.courseId,
    required this.name,
    required this.semesterNumber,
    this.summary,
    this.papersCount = 0,
    this.isSubscribed = false,
    this.isActive = true,
  });

  factory SemesterModel.fromJson(Map<String, dynamic> j) {
    int getInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return SemesterModel(
      id: getInt(j['id']),
      courseId: getInt(j['course_id']),
      name: (j['name'] ?? j['label'] ?? j['title'] ?? '').toString(),
      semesterNumber: getInt(j['number'] ?? j['semester_number'] ?? j['semesterNumber']),
      summary: j['summary']?.toString(),
      papersCount: getInt(j['papers_count'] ?? j['papersCount'] ?? 0),
      isSubscribed: j['is_subscribed'] == true ||
          j['is_subscribed'] == 1 ||
          j['isSubscribed'] == true ||
          j['isSubscribed'] == 1,
      isActive: j['is_active'] != false && j['is_active'] != 0,
    );
  }
}

// ── Subject ───────────────────────────────────────────────────────────────
class SubjectModel {
  final int id;
  final int semesterId;
  final String name;
  final String? code;
  final String? description;
  final String? summary;

  const SubjectModel({
    required this.id,
    required this.semesterId,
    required this.name,
    this.code,
    this.description,
    this.summary,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> j) {
    int getInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return SubjectModel(
      id: getInt(j['id'] ?? j['subject_id']),
      semesterId: getInt(j['semester_id'] ?? j['semesterId']),
      name: j['name']?.toString() ?? j['title']?.toString() ?? '',
      code: j['code']?.toString(),
      description: j['description']?.toString(),
      summary: j['summary']?.toString(),
    );
  }
}

// ── Old Paper ─────────────────────────────────────────────────────────────
class OldPaperModel {
  final int id;
  final int semesterId;
  final String title;
  final String subject;
  final int year;
  final String? pdfUrl;
  final int? pagesCount;
  final DateTime createdAt;
  final bool isFree;
  final bool isLocked;

  const OldPaperModel({
    required this.id,
    this.semesterId = 0,
    required this.title,
    required this.subject,
    this.year = 0,
    this.pdfUrl,
    this.pagesCount,
    required this.createdAt,
    this.isFree = false,
    this.isLocked = true,
  });

  factory OldPaperModel.fromJson(Map<String, dynamic> j) {
    int getInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return OldPaperModel(
      id: getInt(j['id']),
      semesterId: getInt(j['semester_id'] ?? j['semesterId'] ?? 0),
      title: j['title']?.toString() ?? 'Untitled',
      subject: j['subject']?.toString() ?? j['subject_name']?.toString() ?? '',
      year: getInt(j['year'] ?? j['exam_year'] ?? 0),
      pdfUrl: j['pdf_url']?.toString() ?? j['pdfUrl']?.toString() ?? j['file']?.toString() ?? j['url']?.toString() ?? j['view_url']?.toString(),
      pagesCount: j['pages_count'] != null ? getInt(j['pages_count']) : null,
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isFree: j['is_free'] == true || j['is_free'] == 1 || j['is_free'] == "1" || j['free'] == 1,
      isLocked: j['is_locked'] == true || j['is_locked'] == 1 || j['is_locked'] == "1",
    );
  }
}

// ── Subscription ──────────────────────────────────────────────────────────
class SubscriptionPriceModel {
  final bool success;
  final int amount;
  final double price;
  final String formattedPrice;
  final String currency;

  const SubscriptionPriceModel({
    required this.success,
    required this.amount,
    required this.price,
    required this.formattedPrice,
    required this.currency,
  });

  factory SubscriptionPriceModel.fromJson(Map<String, dynamic> j) {
    return SubscriptionPriceModel(
      success: j['success'] == true,
      amount: (j['amount'] as num?)?.toInt() ?? 0,
      price: (j['price'] as num?)?.toDouble() ?? 0.0,
      formattedPrice: j['formatted_price']?.toString() ?? '',
      currency: j['currency']?.toString() ?? 'INR',
    );
  }
}

class SubscriptionModel {
  final int id;
  final int userId;
  final int semesterId;
  final String status; // active | expired | cancelled
  final DateTime startDate;
  final DateTime endDate;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.semesterId,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.razorpayOrderId,
    this.razorpayPaymentId,
  });

  bool get isActive =>
      status == 'active' && endDate.isAfter(DateTime.now());

  factory SubscriptionModel.fromJson(Map<String, dynamic> j) {
    int getInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return SubscriptionModel(
      id: getInt(j['id']),
      userId: getInt(j['user_id'] ?? j['userId']),
      semesterId: getInt(j['semester_id'] ?? j['semesterId']),
      status: j['status']?.toString() ?? 'unknown',
      startDate: j['start_date'] != null
          ? DateTime.tryParse(j['start_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: j['end_date'] != null
          ? DateTime.tryParse(j['end_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      razorpayOrderId: j['razorpay_order_id']?.toString(),
      razorpayPaymentId: j['razorpay_payment_id']?.toString(),
    );
  }
}
