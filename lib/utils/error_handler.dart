import 'package:supabase_flutter/supabase_flutter.dart';

/// 앱 전체에서 사용할 표준화된 에러 타입
enum AppErrorType {
  network,
  authentication,
  authorization,
  validation,
  notFound,
  server,
  timeout,
  unknown,
}

/// 표준화된 앱 에러 클래스
class AppError implements Exception {
  final AppErrorType type;
  final String message;
  final String? code;
  final dynamic originalError;

  const AppError({
    required this.type,
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// 통합 에러 처리 유틸리티
class ErrorHandler {
  /// Supabase 에러를 AppError로 변환
  static AppError handleSupabaseError(dynamic error) {
    if (error is AuthException) {
      return _handleAuthException(error);
    } else if (error is PostgrestException) {
      return _handlePostgrestException(error);
    } else if (error is StorageException) {
      return _handleStorageException(error);
    } else {
      return _handleGenericError(error);
    }
  }

  /// 네트워크 관련 에러 처리
  static AppError handleNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('timeout') || errorString.contains('시간')) {
      return const AppError(
        type: AppErrorType.timeout,
        message: '요청 시간이 초과되었습니다. 다시 시도해주세요.',
      );
    }
    
    if (errorString.contains('network') || errorString.contains('connection') || errorString.contains('internet')) {
      return const AppError(
        type: AppErrorType.network,
        message: '네트워크 연결을 확인해주세요.',
      );
    }
    
    if (errorString.contains('404') || errorString.contains('not found')) {
      return const AppError(
        type: AppErrorType.notFound,
        message: '요청한 리소스를 찾을 수 없습니다.',
      );
    }
    
    return AppError(
      type: AppErrorType.network,
      message: '네트워크 오류가 발생했습니다.',
      originalError: error,
    );
  }

  /// 일반적인 에러를 AppError로 변환
  static AppError handleGenericError(dynamic error) {
    if (error is AppError) {
      return error;
    }
    
    final errorString = error.toString();
    
    // 네트워크 관련 에러 체크
    if (_isNetworkError(errorString)) {
      return handleNetworkError(error);
    }
    
    // 인증 관련 에러 체크
    if (_isAuthError(errorString)) {
      return AppError(
        type: AppErrorType.authentication,
        message: '인증에 실패했습니다. 다시 로그인해주세요.',
        originalError: error,
      );
    }
    
    return AppError(
      type: AppErrorType.unknown,
      message: '알 수 없는 오류가 발생했습니다.',
      originalError: error,
    );
  }

  /// 사용자 친화적인 에러 메시지 반환
  static String getUserFriendlyMessage(dynamic error) {
    if (error is AppError) {
      return error.message;
    }
    
    final appError = handleGenericError(error);
    return appError.message;
  }

  // Private methods
  static AppError _handleAuthException(AuthException error) {
    switch (error.message) {
      case 'Invalid login credentials':
        return const AppError(
          type: AppErrorType.authentication,
          message: '이메일 또는 비밀번호가 올바르지 않습니다.',
        );
      case 'User already registered':
        return const AppError(
          type: AppErrorType.validation,
          message: '이미 등록된 이메일입니다.',
        );
      case 'Password should be at least 6 characters':
        return const AppError(
          type: AppErrorType.validation,
          message: '비밀번호는 최소 6자 이상이어야 합니다.',
        );
      case 'Invalid email':
        return const AppError(
          type: AppErrorType.validation,
          message: '올바른 이메일 형식을 입력해주세요.',
        );
      case 'Email not confirmed':
        return const AppError(
          type: AppErrorType.authentication,
          message: '이메일 인증이 필요합니다. 이메일을 확인해주세요.',
        );
      case 'Too many requests':
        return const AppError(
          type: AppErrorType.server,
          message: '너무 많은 요청이 있었습니다. 잠시 후 다시 시도해주세요.',
        );
      case 'User not found':
        return const AppError(
          type: AppErrorType.notFound,
          message: '등록되지 않은 이메일입니다.',
        );
      default:
        return AppError(
          type: AppErrorType.authentication,
          message: '인증 오류: ${error.message}',
          originalError: error,
        );
    }
  }

  static AppError _handlePostgrestException(PostgrestException error) {
    switch (error.code) {
      case '42501': // permission denied
        return const AppError(
          type: AppErrorType.authorization,
          message: '접근 권한이 없습니다.',
        );
      case '23505': // unique violation
        return const AppError(
          type: AppErrorType.validation,
          message: '중복된 데이터입니다.',
        );
      case '23503': // foreign key violation
        return const AppError(
          type: AppErrorType.validation,
          message: '참조된 데이터가 존재하지 않습니다.',
        );
      default:
        return AppError(
          type: AppErrorType.server,
          message: '서버 오류가 발생했습니다.',
          code: error.code,
          originalError: error,
        );
    }
  }

  static AppError _handleStorageException(StorageException error) {
    return AppError(
      type: AppErrorType.server,
      message: '파일 처리 중 오류가 발생했습니다.',
      originalError: error,
    );
  }

  static AppError _handleGenericError(dynamic error) {
    return AppError(
      type: AppErrorType.unknown,
      message: '예기치 못한 오류가 발생했습니다.',
      originalError: error,
    );
  }

  static bool _isNetworkError(String errorString) {
    final networkKeywords = [
      'network', 'connection', 'internet', 'timeout', 'socket',
      '404', '500', '502', '503', '504', 'empty response'
    ];
    
    return networkKeywords.any((keyword) => 
        errorString.toLowerCase().contains(keyword));
  }

  static bool _isAuthError(String errorString) {
    final authKeywords = [
      'unauthorized', '401', 'authentication', 'token', 'session'
    ];
    
    return authKeywords.any((keyword) => 
        errorString.toLowerCase().contains(keyword));
  }
}

/// 에러 처리를 위한 확장 메서드
extension ErrorHandling on Future {
  /// Future에 통합 에러 처리 적용
  Future<T> handleErrors<T>() async {
    try {
      return await this as T;
    } catch (error) {
      throw ErrorHandler.handleGenericError(error);
    }
  }
}
