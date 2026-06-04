class StoreCartModel {
  final String cartId;
  final String branchId;
  final String branchName;
  final String branchImageUrl;
  final String distance;
  final String deliveryTime;
  final bool isClosed;
  final String closedNote;
  final int totalItems;

  const StoreCartModel({
    required this.cartId,
    required this.branchId,
    required this.branchName,
    required this.branchImageUrl,
    required this.distance,
    required this.deliveryTime,
    required this.isClosed,
    required this.closedNote,
    required this.totalItems,
  });

  factory StoreCartModel.fromJson(Map<String, dynamic> json) {
    return StoreCartModel(
      cartId: json['cartId'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      branchName: json['branchName'] as String? ?? '',
      branchImageUrl: json['branchImageUrl'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      deliveryTime: json['deliveryTime'] as String? ?? '',
      isClosed: json['isClosed'] as bool? ?? false,
      closedNote: json['closedNote'] as String? ?? '',
      totalItems: json['totalItems'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cartId': cartId,
      'branchId': branchId,
      'branchName': branchName,
      'branchImageUrl': branchImageUrl,
      'distance': distance,
      'deliveryTime': deliveryTime,
      'isClosed': isClosed,
      'closedNote': closedNote,
      'totalItems': totalItems,
    };
  }
}
