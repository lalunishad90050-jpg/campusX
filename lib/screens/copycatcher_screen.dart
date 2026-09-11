import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CopyCatcherScreen extends StatefulWidget {
  const CopyCatcherScreen({super.key});

  @override
  State<CopyCatcherScreen> createState() => _CopyCatcherScreenState();
}

class _CopyCatcherScreenState extends State<CopyCatcherScreen> {
  static const String apiUrl =
      'https://campusx-backend-43jp.onrender.com/copycatcher/analyze';

  bool isAnalyzing = false;
  String? selectedFileName;

  double similarityPercentage = 0;
  double originalityPercentage = 0;
  double aiPercentage = 0;

  String summary = '';
  List<String> matchedAreas = [];
  List<String> recommendations = [];

  Future<void> pickAndAnalyzeFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
      );

      if (files.isEmpty) {
        return;
      }

      final pickedFile = files.first;

      setState(() {
        selectedFileName = pickedFile.name;
        isAnalyzing = true;
        similarityPercentage = 0;
        originalityPercentage = 0;
        aiPercentage = 0;
        summary = '';
        matchedAreas = [];
        recommendations = [];
      });

      final bytes = await pickedFile.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('Selected file is empty.');
      }

      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: pickedFile.name),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server error ${response.statusCode}');
      }

      final decoded = jsonDecode(responseBody);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid server response.');
      }

      if (!mounted) return;

      setState(() {
        similarityPercentage = _toDouble(decoded['similarity_percentage']);

        originalityPercentage = _toDouble(decoded['originality_percentage']);

        aiPercentage = _toDouble(decoded['ai_percentage']);

        summary = (decoded['summary'] ?? '').toString();

        matchedAreas = _toStringList(decoded['matched_areas']);

        recommendations = _toStringList(decoded['recommendations']);
      });

      showMessage('Analysis complete ✅');
    } catch (e) {
      if (!mounted) return;

      showMessage('Analysis failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isAnalyzing = false;
        });
      }
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return [];
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void showReport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.78,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detailed Report',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 20),

                    _ReportItem(
                      title: 'Similarity',
                      value: '${similarityPercentage.toStringAsFixed(0)}%',
                      icon: Icons.copy_all_rounded,
                    ),

                    const SizedBox(height: 12),

                    _ReportItem(
                      title: 'Originality',
                      value: '${originalityPercentage.toStringAsFixed(0)}%',
                      icon: Icons.verified_rounded,
                    ),

                    const SizedBox(height: 12),

                    _ReportItem(
                      title: 'AI Indicator',
                      value: '${aiPercentage.toStringAsFixed(0)}%',
                      icon: Icons.smart_toy_outlined,
                    ),

                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 24),

                      Text(
                        'Summary',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      Text(summary),
                    ],

                    if (matchedAreas.isNotEmpty) ...[
                      const SizedBox(height: 24),

                      Text(
                        'Matched Areas',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      ...matchedAreas.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item)),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (recommendations.isNotEmpty) ...[
                      const SizedBox(height: 24),

                      Text(
                        'Recommendations',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      ...recommendations.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('CopyCatcher')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.fact_check_rounded,
                          size: 42,
                          color: theme.colorScheme.primary,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'Assignment Analyzer',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Check plagiarism, originality and AI-generated content.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Upload Assignment',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Supported formats: PDF, DOCX',
                        style: theme.textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 18),

                      if (selectedFileName != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.description_outlined),
                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  selectedFileName!,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (selectedFileName != null) const SizedBox(height: 14),

                      ElevatedButton.icon(
                        onPressed: isAnalyzing ? null : pickAndAnalyzeFile,
                        icon: isAnalyzing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_file_rounded),
                        label: Text(
                          isAnalyzing
                              ? 'Analyzing...'
                              : 'Choose File & Analyze',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (selectedFileName != null && !isAnalyzing)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Analysis Result',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 18),

                        _ResultTile(
                          title: 'Similarity',
                          value: '${similarityPercentage.toStringAsFixed(0)}%',
                          icon: Icons.copy_all_rounded,
                        ),

                        const SizedBox(height: 10),

                        _ResultTile(
                          title: 'Originality',
                          value: '${originalityPercentage.toStringAsFixed(0)}%',
                          icon: Icons.verified_rounded,
                        ),

                        const SizedBox(height: 10),

                        _ResultTile(
                          title: 'AI Indicator',
                          value: '${aiPercentage.toStringAsFixed(0)}%',
                          icon: Icons.smart_toy_outlined,
                        ),

                        const SizedBox(height: 18),

                        OutlinedButton.icon(
                          onPressed: showReport,
                          icon: const Icon(Icons.analytics_outlined),
                          label: const Text('View Detailed Report'),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: theme.colorScheme.primary,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'CopyCatcher uses the CampusX backend to analyze your uploaded assignment.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ResultTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ReportItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
