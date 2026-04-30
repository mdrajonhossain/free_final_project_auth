/// Custom exception for GraphQL-related errors.
class GqlException implements Exception {
  final String message;

  const GqlException(this.message);

  @override
  String toString() => 'GqlException: $message';
}
