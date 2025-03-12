import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CompletionPage extends StatelessWidget {
  const CompletionPage({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('yyyy년 MM월 dd일 HH:mm');
    final submissionTime =
        data['submissionTime'] != null
            ? DateTime.parse(data['submissionTime'])
            : DateTime.now();
    final formattedTime = formatter.format(submissionTime);

    final List<String> imagePaths =
        data['imagePaths'] != null ? List<String>.from(data['imagePaths']) : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('제출 완료'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                '완료되었습니다',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '데이터가 성공적으로 제출되었습니다',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildDataSummaryCard(context),
              const SizedBox(height: 24),
              if (imagePaths.isNotEmpty) ...[
                _buildImagePreviewSection(context, imagePaths),
                const SizedBox(height: 24),
              ],
              _buildSubmissionInfo(context, formattedTime),
              const SizedBox(height: 32),
              _buildHomeButton(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataSummaryCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'QR 코드 데이터',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data['qrData'] ?? '데이터 없음',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Divider(height: 32),
            Row(
              children: [
                const Icon(Icons.description, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '상세 설명',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data['description'] ?? '설명 없음',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewSection(
    BuildContext context,
    List<String> imagePaths,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '첨부된 이미지',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePaths[index]),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionInfo(BuildContext context, String formattedTime) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.access_time, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '제출 시간: $formattedTime',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => context.go('/scan'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          '확인',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
