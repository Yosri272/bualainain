import 'package:flutter/material.dart';
class RejectedAccountScreen extends StatelessWidget {
  const RejectedAccountScreen({super.key});

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
                Icons.cancel,
                size: 100,
                color: Colors.red,
              ),
              SizedBox(height: 20),
              Text(
                'تم رفض الطلب',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'عذراً، تم رفض طلب العضوية.\nيرجى التواصل مع الإدارة.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}