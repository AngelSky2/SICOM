import '../error/failures.dart';

/// Resultado tipado: o éxito con valor, o error con [Failure].
/// Evita propagar excepciones entre capas.
sealed class Result<T> {
  const Result();

  R fold<R>(R Function(Failure failure) onError, R Function(T value) onSuccess) {
    return switch (this) {
      Success<T>(:final value) => onSuccess(value),
      Error<T>(:final failure) => onError(failure),
    };
  }

  bool get isSuccess => this is Success<T>;
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Error<T> extends Result<T> {
  const Error(this.failure);
  final Failure failure;
}
