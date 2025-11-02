
class WrapResponse {

  String error;

  final dynamic object;

  WrapResponse({
    this.error = '',
    this.object,
  });

  T? tryCast<T>(dynamic value) {
    try {
      return (value as T);
    } on TypeError catch (_) {
      return null;
    }
  }

  @override
  String toString() {
    return "Error: $error, Object: $object";
  }

}