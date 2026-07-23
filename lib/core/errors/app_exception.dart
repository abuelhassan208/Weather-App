sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);
}

final class TimeoutException extends AppException {
  const TimeoutException([super.message = 'The request timed out.']);
}

final class BadRequestException extends AppException {
  const BadRequestException([super.message = 'Invalid request.']);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized request.']);
}

final class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'The requested resource was not found.',
  ]);
}

final class ServerException extends AppException {
  const ServerException([super.message = 'Server error occurred.']);
}

final class ConfigurationException extends AppException {
  const ConfigurationException([
    super.message = 'The application is not configured correctly.',
  ]);
}

final class CacheException extends AppException {
  const CacheException([
    super.message = 'An error occurred while accessing cached data.',
  ]);
}

final class DataParsingException extends AppException {
  const DataParsingException([
    super.message = 'The weather data has an invalid format.',
  ]);
}

final class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong.']);
}
