/// A tiny, dependency-free "either succeeded or failed" wrapper used across
/// the repository layer. This is the one piece of ceremony kept from
/// classic Clean Architecture error handling — it keeps failure handling
/// explicit at the ViewModel layer instead of relying on try/catch call
/// sites scattered around the UI.
sealed class Result<T> {
  const Result();

  /// Runs [onSuccess] or [onFailure] and returns whichever branch runs —
  /// the standard functional "fold" for a two-case union.
  R fold<R>(R Function(T value) onSuccess, R Function(Failure failure) onFailure) {
    final self = this;
    if (self is Success<T>) return onSuccess(self.value);
    if (self is FailureResult<T>) return onFailure(self.failure);
    throw StateError('Unreachable: unknown Result subtype');
  }

  bool get isSuccess => this is Success<T>;

  /// Only safe to call when [isSuccess] is true.
  T get value => (this as Success<T>).value;
}

class Success<T> extends Result<T> {
  const Success(this.value);
  @override
  final T value;
}

class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;
}

/// A plain-English, developer-facing description of what went wrong (for
/// logs / debugging). Deliberately NOT localized here — the domain/data
/// layer shouldn't know about languages. The presentation layer decides
/// what to actually show the user (usually a generic localized message via
/// `context.l10n`, since most failures here are the same handful of local
/// I/O problems: disk full, permission denied, file not found).
class Failure {
  const Failure(this.message, {this.exception});

  final String message;
  final Object? exception;

  @override
  String toString() => 'Failure($message)';
}
