// lib/core/providers.dart
// Central barrel — re-export all major providers so screens
// only need one import for common state.

export 'api/api_client.dart';
export 'api/api_service.dart';
export 'api/api_exception.dart';
export 'models/models.dart';
export 'router/app_router.dart';
export 'theme/app_theme.dart';
export 'constants/app_constants.dart';
export '../features/auth/auth_repository.dart';
export '../features/university/university_repository.dart';
export '../features/course/course_repository.dart';
export '../features/semester/semester_repository.dart';
export '../features/subscription/subscription_repository.dart';
