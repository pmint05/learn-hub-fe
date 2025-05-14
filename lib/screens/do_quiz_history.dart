import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/router_config.dart';
import 'package:learn_hub/const/result_manager_config.dart';
import 'package:learn_hub/services/result_manager.dart';
import 'package:learn_hub/utils/date_helper.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DoQuizHistoryScreen extends StatefulWidget {
  const DoQuizHistoryScreen({super.key});

  @override
  State<DoQuizHistoryScreen> createState() => _DoQuizHistoryScreenState();
}

class _DoQuizHistoryScreenState extends State<DoQuizHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _results = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await ResultManager.instance.getResultsByUserId(
        GetResultsByUserIdConfig(sortBy: 'last_modified_date', sortOrder: -1),
      );

      if (response['status'] == 'success' && response['data'] != null) {
        setState(() {
          _results = List<Map<String, dynamic>>.from(response['data']);
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load results';
        });
      }
    } catch (e) {
      if (e is DioException) {
        setState(() {
          _errorMessage = 'Network error: ${e.message}';
        });
      } else {
        setState(() {
          _errorMessage = 'An error occurred';
        });
      }
      print('Error loading results: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quiz Attempts History',
          style: TextStyle(fontFamily: 'BricolageGrotesque'),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(onRefresh: _loadResults, child: _buildContent(cs)),
    );
  }

  Widget _buildContent(ColorScheme cs) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIconsBold.warning, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontFamily: 'BricolageGrotesque',
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadResults, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIconsBold.notepad,
              size: 64,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No quiz history found',
              style: TextStyle(
                fontFamily: 'BricolageGrotesque',
                fontSize: 18,
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete some quizzes to see your history here',
              style: TextStyle(
                fontFamily: 'BricolageGrotesque',
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        final status = List<Map<String, dynamic>>.from(result['status'] ?? []);
        final total = status.length;
        final completed = status.where((item) => item['answer'] != -1).length;
        final correct = (result['num_correct'] ?? 0) as int;
        final lastModified = DateHelper.utcStringToLocal(
          result['last_modified_date'] ?? '',
        );

        return GestureDetector(
          onTap: () {
            context.pushNamed(
              AppRoute.doQuizzes.name,
              extra: {
                'quiz_id': result['quiz_id'],
                'result_id': result['result_id'],
              },
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.surfaceDim),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        result['title'] ?? result['quiz_id'] ?? 'Quiz',
                        style: TextStyle(
                          fontFamily: 'BricolageGrotesque',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        Moment.parse(lastModified.toString()).fromNow(),
                        style: TextStyle(
                          fontFamily: 'BricolageGrotesque',
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatusBox(
                        'Progress',
                        '$completed/$total',
                        cs.primary,
                      ),
                      const SizedBox(width: 12),
                      _buildStatusBox(
                        'Correct',
                        '$correct/$total',
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildStatusBox(
                        'Incorrect',
                        '${(result['num_incorrect'] ?? 0)}/$total',
                        Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: total > 0 ? completed / total : 0,
                    backgroundColor: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'BricolageGrotesque',
                fontSize: 12,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'BricolageGrotesque',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
