class ExceptionError extends Error {
  final Exception exception;

  ExceptionError(this.exception);
}

class MessageError extends Error {
  final String message;

  MessageError(this.message);
}
