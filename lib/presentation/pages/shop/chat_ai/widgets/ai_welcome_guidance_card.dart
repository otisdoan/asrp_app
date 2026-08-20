import 'package:flutter/material.dart';

class AiWelcomeGuidanceCard extends StatelessWidget {
  final Function(String) onActionTap;

  const AiWelcomeGuidanceCard({super.key, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.blue.withValues(alpha: 0.2), width: 1.5),
            ),
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('🤖', style: TextStyle(fontSize: 28)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chào bạn! Tôi là Trợ lý AI DineX',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tôi có thể hỗ trợ bạn các công việc sau:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.search, 'Tìm món theo ngân sách (VD: dưới 50k)', Colors.orange),
                  _buildFeatureItem(Icons.auto_awesome, 'Gợi ý món ngon hợp khẩu vị', Colors.purple),
                  _buildFeatureItem(Icons.qr_code_scanner, 'Chốt đơn & Sinh mã thanh toán nhanh', Colors.green),
                  _buildFeatureItem(Icons.notifications_active, 'Kiểm tra tiến trình đơn hàng', Colors.redAccent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Thử hỏi tôi nhé:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildActionChip('💡 Tìm món phở dưới 100k'),
              _buildActionChip('✨ tôi muốn ăn cơm'),
              _buildActionChip('🔔 trà ngon'),
              _buildActionChip('🥗 cho tôi món tráng miệng '),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.3))),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      onPressed: () => onActionTap(label.replaceAll(RegExp(r'[💡✨🔔🥗]\s*'), '')),
    );
  }
}
