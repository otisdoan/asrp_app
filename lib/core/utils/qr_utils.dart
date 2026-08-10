/// Utility functions for QR Code generation and parsing across ASRP application.
class QrUtils {
  static const String orderPrefix = 'ASRP_ORDER:';

  /// Generates a standardized QR code payload string for an order.
  static String generateOrderQrPayload(String orderId) {
    return '$orderPrefix$orderId';
  }

  /// Parses a raw QR scan string and extracts the order ID if valid.
  /// Returns the extracted order ID, or null if the payload is not an ASRP order QR code.
  static String? parseOrderQrPayload(String rawPayload) {
    final trimmed = rawPayload.trim();
    if (trimmed.startsWith(orderPrefix)) {
      return trimmed.substring(orderPrefix.length).trim();
    }
    // Fallback: If rawPayload looks like a Guid (36 chars with hyphens), accept it directly
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (uuidRegex.hasMatch(trimmed)) {
      return trimmed;
    }
    return null;
  }
}
