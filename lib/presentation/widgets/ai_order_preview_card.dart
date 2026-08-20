import 'package:flutter/material.dart';

class AiOrderPreviewCard extends StatelessWidget {
  final Map<String, dynamic> responseData;

  const AiOrderPreviewCard({super.key, required this.responseData});

  @override
  Widget build(BuildContext context) {
    final reply = responseData['reply'] ?? '';
    final orderDraftPreview = responseData['orderDraftPreview'];
    final branchRecommendations = responseData['branchRecommendations'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tin nhắn từ AI
          Text(reply, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const Divider(height: 16),

          // Nếu có Order Draft Preview -> Hiển thị khung tổng tiền
          if (orderDraftPreview != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tạm tính:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "${orderDraftPreview['finalAmount']} đ",
                    style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Danh sách món gợi ý
          if (branchRecommendations.isNotEmpty) ...[
            const Text("Các lựa chọn tương tự:", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: branchRecommendations.length,
                itemBuilder: (context, index) {
                  final item = branchRecommendations[index];
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            item['imageUrl'] ?? '',
                            height: 60,
                            width: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(color: Colors.grey[200], height: 60),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(item['dishName'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(item['priceText'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.red)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
