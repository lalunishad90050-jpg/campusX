import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExamWarriorScreen extends StatefulWidget {
  const ExamWarriorScreen({super.key});

  @override
  State<ExamWarriorScreen> createState() => _ExamWarriorScreenState();
}

class _ExamWarriorScreenState extends State<ExamWarriorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String apiUrl =
      'https://campusx-backend-43jp.onrender.com/examwarrior/generate';

  String selectedSubject = 'All';
  String selectedUnit = 'All';

  String generatorSubject = 'Mathematics-I';
  String generatorUnit = 'Unit 1';
  String generatorTopic = 'Limits and Continuity';
  String generatorDifficulty = 'Medium';

  String? generatedQuestion;
  bool isGenerating = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> get pyqStream {
    return _firestore
        .collection('pyqs')
        .orderBy('year', descending: true)
        .snapshots();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> getSubjects(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> records,
  ) {
    final subjects = <String>{};

    for (final record in records) {
      final subject = record.data()['subject']?.toString();

      if (subject != null && subject.isNotEmpty) {
        subjects.add(subject);
      }
    }

    return ['All', ...subjects.toList()..sort()];
  }

  List<String> getUnits(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> records,
  ) {
    final units = <String>{};

    for (final record in records) {
      final unit = record.data()['unit']?.toString();

      if (unit != null && unit.isNotEmpty) {
        units.add(unit);
      }
    }

    return ['All', ...units.toList()..sort()];
  }

  List<String> getGeneratorTopics(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> records,
  ) {
    final topics = <String>{};

    for (final record in records) {
      final data = record.data();

      if (data['subject']?.toString() == generatorSubject &&
          data['unit']?.toString() == generatorUnit) {
        final topic = data['topic']?.toString();

        if (topic != null && topic.isNotEmpty) {
          topics.add(topic);
        }
      }
    }

    if (topics.isEmpty) {
      return [generatorTopic];
    }

    return topics.toList()..sort();
  }

  Map<String, int> calculateTopicFrequency(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> records,
  ) {
    final frequency = <String, int>{};

    for (final record in records) {
      final data = record.data();

      final subjectMatches =
          selectedSubject == 'All' ||
          data['subject']?.toString() == selectedSubject;

      final unitMatches =
          selectedUnit == 'All' || data['unit']?.toString() == selectedUnit;

      if (!subjectMatches || !unitMatches) {
        continue;
      }

      final topic = data['topic']?.toString();

      if (topic == null || topic.isEmpty) {
        continue;
      }

      frequency[topic] = (frequency[topic] ?? 0) + 1;
    }

    return frequency;
  }

  String getPriority(int count, int highestCount) {
    if (highestCount <= 0) {
      return 'Low';
    }

    final ratio = count / highestCount;

    if (ratio >= 0.66) {
      return 'High';
    }

    if (ratio >= 0.33) {
      return 'Medium';
    }

    return 'Low';
  }

  Color getPriorityColor(String priority, ThemeData theme) {
    if (priority == 'High') {
      return theme.colorScheme.error;
    }

    if (priority == 'Medium') {
      return Colors.orange;
    }

    return theme.colorScheme.primary;
  }

  Future<void> generatePracticeQuestion() async {
    if (generatorSubject.isEmpty ||
        generatorUnit.isEmpty ||
        generatorTopic.isEmpty) {
      showMessage('Please select Subject, Unit and Topic.');
      return;
    }

    setState(() {
      isGenerating = true;
      generatedQuestion = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'subject': generatorSubject,
              'unit': generatorUnit,
              'topic': generatorTopic,
              'difficulty': generatorDifficulty,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        final question = data['question']?.toString();

        if (question == null || question.isEmpty) {
          throw Exception('AI returned an empty question.');
        }

        setState(() {
          generatedQuestion = question;
        });
      } else {
        String message = 'AI request failed.';

        try {
          final errorData = jsonDecode(response.body);

          if (errorData is Map && errorData['detail'] != null) {
            message = errorData['detail'].toString();
          }
        } catch (_) {}

        throw Exception(message);
      }
    } on http.ClientException {
      if (!mounted) return;

      showMessage('Backend se connection nahi ho pa raha.');
    } on FormatException {
      if (!mounted) return;

      showMessage('Backend ne invalid response diya.');
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      showMessage('Question generate nahi hua: $message');
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  void showTopicDetails(String topic, int frequency, String priority) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Topic Analysis',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  topic,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoRow(label: 'PYQ Frequency', value: '$frequency times'),
                _InfoRow(label: 'Priority', value: priority),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);

                      setState(() {
                        generatorTopic = topic;
                      });

                      showMessage('Topic selected for question generation.');
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate Questions'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildGenerator(
    BuildContext context,
    List<String> subjects,
    List<String> units,
    List<String> topics,
  ) {
    final theme = Theme.of(context);

    if (!subjects.contains(generatorSubject) && subjects.length > 1) {
      generatorSubject = subjects.firstWhere(
        (item) => item != 'All',
        orElse: () => 'Mathematics-I',
      );
    }

    if (!units.contains(generatorUnit) && units.length > 1) {
      generatorUnit = units.firstWhere(
        (item) => item != 'All',
        orElse: () => 'Unit 1',
      );
    }

    if (!topics.contains(generatorTopic)) {
      generatorTopic = topics.isNotEmpty ? topics.first : 'General Topic';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Question Generator',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Text(
              'Generate real AI practice questions from your selected topic.',
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              initialValue: subjects.contains(generatorSubject)
                  ? generatorSubject
                  : null,
              decoration: const InputDecoration(
                labelText: 'Subject',
                prefixIcon: Icon(Icons.book_outlined),
              ),
              items: subjects
                  .where((item) => item != 'All')
                  .map(
                    (subject) => DropdownMenuItem<String>(
                      value: subject,
                      child: Text(subject),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  generatorSubject = value;
                  generatedQuestion = null;
                });
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: units.contains(generatorUnit)
                  ? generatorUnit
                  : null,
              decoration: const InputDecoration(
                labelText: 'Unit',
                prefixIcon: Icon(Icons.layers_outlined),
              ),
              items: units
                  .where((item) => item != 'All')
                  .map(
                    (unit) => DropdownMenuItem<String>(
                      value: unit,
                      child: Text(unit),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  generatorUnit = value;
                  generatedQuestion = null;
                });
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: topics.contains(generatorTopic)
                  ? generatorTopic
                  : null,
              decoration: const InputDecoration(
                labelText: 'Topic',
                prefixIcon: Icon(Icons.topic_outlined),
              ),
              items: topics
                  .map(
                    (topic) => DropdownMenuItem<String>(
                      value: topic,
                      child: Text(topic),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  generatorTopic = value;
                  generatedQuestion = null;
                });
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: generatorDifficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                prefixIcon: Icon(Icons.speed_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                DropdownMenuItem(value: 'Hard', child: Text('Hard')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  generatorDifficulty = value;
                  generatedQuestion = null;
                });
              },
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: isGenerating ? null : generatePracticeQuestion,
              icon: isGenerating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                isGenerating ? 'Generating with AI...' : 'Generate AI Question',
              ),
            ),

            if (generatedQuestion != null) ...[
              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Generated Question',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(generatedQuestion!, style: theme.textTheme.bodyLarge),

                    const SizedBox(height: 14),

                    Text(
                      '$generatorSubject • $generatorUnit • '
                      '$generatorTopic • $generatorDifficulty',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ExamWarrior')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: pyqStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Data load nahi ho raha.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data?.docs ?? [];

          final subjects = getSubjects(records);
          final units = getUnits(records);
          final topics = getGeneratorTopics(records);

          final topicFrequency = calculateTopicFrequency(records);

          final sortedTopics = topicFrequency.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final highestCount = sortedTopics.isEmpty
              ? 0
              : sortedTopics.first.value;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: theme.colorScheme.primary,
                            child: Icon(
                              Icons.emoji_events_rounded,
                              color: theme.colorScheme.onPrimary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'ExamWarrior',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Prepare smarter. Score better.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  'Preparation Progress',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Overall Preparation',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '68%',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(
                          value: 0.68,
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                buildGenerator(context, subjects, units, topics),

                const SizedBox(height: 26),

                Text(
                  'Topic Predictor',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: subjects.contains(selectedSubject)
                            ? selectedSubject
                            : 'All',
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          prefixIcon: Icon(Icons.book_outlined),
                        ),
                        items: subjects.map((subject) {
                          return DropdownMenuItem<String>(
                            value: subject,
                            child: Text(subject),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            selectedSubject = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: units.contains(selectedUnit)
                            ? selectedUnit
                            : 'All',
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          prefixIcon: Icon(Icons.layers_outlined),
                        ),
                        items: units.map((unit) {
                          return DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            selectedUnit = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                if (sortedTopics.isEmpty)
                  Card(
                    child: const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          'No topic data found.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  ...sortedTopics.asMap().entries.map((entry) {
                    final index = entry.key;
                    final topic = entry.value.key;
                    final frequency = entry.value.value;

                    final priority = getPriority(frequency, highestCount);

                    final priorityColor = getPriorityColor(priority, theme);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          showTopicDetails(topic, frequency, priority);
                        },
                        leading: CircleAvatar(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          topic,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Appeared $frequency time(s)'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            priority,
                            style: TextStyle(
                              color: priorityColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
