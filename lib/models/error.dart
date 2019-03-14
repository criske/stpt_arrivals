class ExceptionError extends RetryableError {
  final Exception exception;

  ExceptionError(this.exception, [bool canRetry = false]) : super(canRetry);
}

class MessageError extends RetryableError {
  final String message;

  MessageError(this.message, [bool canRetry = false]) : super(canRetry);
}

class RetryableError extends Error {
  final canRetry;

  RetryableError([this.canRetry = false]);
}
