import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pmgoroshi/presentation/pages/data_form/data_form_controller.dart';
import 'package:pmgoroshi/domain/entities/form_data.dart';

class DataFormPage extends ConsumerWidget {
  const DataFormPage({super.key, required this.qrData});

  final String qrData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dataFormControllerProvider(qrData));
    final controller = ref.read(dataFormControllerProvider(qrData).notifier);

    // 제출 성공 시 완료 화면으로 이동
    ref.listen(dataFormControllerProvider(qrData).select((s) => s.isSuccess), (
      previous,
      isSuccess,
    ) {
      if (isSuccess && previous == false) {
        final submissionData = SubmissionData(
          qrData: state.qrData,
          description: state.description,
          imagePaths: state.imagePaths,
          submissionTime: DateTime.now(),
        );

        context.go('/completion', extra: submissionData.toJson());
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('데이터 입력'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQRDataSection(context, state.qrData),
              const SizedBox(height: 24),
              _buildDescriptionField(context, state, controller),
              const SizedBox(height: 24),
              _buildImagePickerSection(context, state, controller),
              const SizedBox(height: 32),
              if (state.errorMessage != null)
                _buildErrorMessage(context, state.errorMessage!),
              const SizedBox(height: 16),
              _buildSubmitButton(context, state, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRDataSection(BuildContext context, String qrData) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QR 코드 데이터',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              qrData,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField(
    BuildContext context,
    dynamic state,
    DataFormController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '상세 설명',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: state.description,
          onChanged: controller.updateDescription,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: '상세 내용을 입력하세요',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerSection(
    BuildContext context,
    dynamic state,
    DataFormController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '사진 첨부',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: controller.pickImageFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('갤러리'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: controller.pickImageFromCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('카메라'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.imagePaths.isNotEmpty)
          _buildImagePreviewGrid(context, state, controller),
      ],
    );
  }

  Widget _buildImagePreviewGrid(
    BuildContext context,
    dynamic state,
    DataFormController controller,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: state.imagePaths.length,
      itemBuilder: (context, index) {
        final imagePath = state.imagePaths[index];
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(imagePath),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => controller.removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorMessage(BuildContext context, String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    dynamic state,
    DataFormController controller,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: state.isSubmitting ? null : () => controller.submitForm(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            state.isSubmitting
                ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                : const Text(
                  '제출하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }
}
