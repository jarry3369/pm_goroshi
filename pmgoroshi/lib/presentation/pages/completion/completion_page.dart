import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pmgoroshi/data/services/supabase_service.dart';
import 'package:pmgoroshi/domain/entities/form_data.dart';

class CompletionPage extends StatefulWidget {
  const CompletionPage({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  State<CompletionPage> createState() => _CompletionPageState();
}

class _CompletionPageState extends State<CompletionPage> {
  bool _isUploading = true;
  String _statusMessage = '리포트를 작성하는 중...';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _processDataAndUpload();
  }

  Future<void> _processDataAndUpload() async {
    try {
      // Supabase 서비스 인스턴스 생성
      final supabaseService = SupabaseService();

      // 이미지 경로 가져오기
      final List<String> imagePaths =
          widget.data['imagePaths'] != null
              ? List<String>.from(widget.data['imagePaths'])
              : [];

      List<String> uploadedImageUrls = [];

      // 이미지가 있는 경우 업로드
      if (imagePaths.isNotEmpty) {
        setState(() {
          _statusMessage = '이미지를 압축하고 업로드하는 중...';
        });

        // 이미지 압축 및 업로드
        uploadedImageUrls = await supabaseService.uploadImages(imagePaths);

        // 원본 데이터에 이미지 URL 업데이트
        widget.data['imagePaths'] = uploadedImageUrls;
      }

      // Supabase 데이터베이스에 데이터 저장
      setState(() {
        _statusMessage = '데이터를 저장하는 중...';
      });

      // 데이터 저장에 필요한 객체 생성
      final reportData = {
        'qrData': widget.data['qrData'] ?? '',
        'description': widget.data['description'] ?? '',
        'imagePaths': uploadedImageUrls,
        'submissionTime':
            widget.data['submissionTime'] ?? DateTime.now().toIso8601String(),
        'location': widget.data['location'] ?? '',
        'companyName': widget.data['companyName'] ?? '',
        'serialNumber': widget.data['serialNumber'] ?? '',
        'violationType': widget.data['violationType'] ?? {},
      };

      // Supabase에 데이터 저장
      await supabaseService.saveReportData(SubmissionData.fromJson(reportData));

      // 작업 완료
      setState(() {
        _isUploading = false;
        _statusMessage = '리포트가 성공적으로 제출되었습니다';
      });
    } catch (e) {
      // 오류 처리
      setState(() {
        _isUploading = false;
        _isError = true;
        _statusMessage = '오류 발생: $e';
      });
      debugPrint('데이터 처리 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('yyyy년 MM월 dd일 HH:mm');
    final submissionTime =
        widget.data['submissionTime'] != null
            ? DateTime.parse(widget.data['submissionTime'])
            : DateTime.now();
    final formattedTime = formatter.format(submissionTime);

    final List<String> imagePaths =
        widget.data['imagePaths'] != null
            ? List<String>.from(widget.data['imagePaths'])
            : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('제출 완료'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
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
            // 업로드 진행 중일 때 보여줄 오버레이
            if (_isUploading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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
              widget.data['qrData'] ?? '데이터 없음',
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
              widget.data['description'] ?? '설명 없음',
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
              // URL인지 로컬 파일 경로인지 확인
              final isUrl = imagePaths[index].startsWith('http');

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      isUrl
                          ? Image.network(
                            imagePaths[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.error),
                              );
                            },
                          )
                          : Image.file(
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
        onPressed:
            _isUploading
                ? null // 업로드 중에는 버튼 비활성화
                : () => context.go('/scan'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          disabledBackgroundColor: Colors.grey,
        ),
        child: const Text(
          '확인',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
