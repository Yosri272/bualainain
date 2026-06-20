import 'package:flutter/material.dart';
class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_top,
                size: 100,
                color: Colors.orange,
              ),
              SizedBox(height: 20),
              Text(
                'طلبك قيد المراجعة',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'تم تسجيل طلب العضوية بنجاح\nبانتظار موافقة الإدارة',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}