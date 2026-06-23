import 'package:flutter/material.dart';

class QuizResultsScreen extends StatelessWidget {
  final Map<String, dynamic> resultsData;
  final String testTitle;
  final bool isDarkMode;

  const QuizResultsScreen({
    super.key,
    required this.resultsData,
    required this.testTitle,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final bgDark = const Color(0xFF111116);
    final bgLight = const Color(0xFFF8FAFC);
    final cardDark = const Color(0xFF181824);
    final cardLight = const Color(0xFFFFFFFF);
    final textDark = const Color(0xFFF1F5F9);
    final textLight = const Color(0xFF0F172A);
    final borderDark = Colors.white10;
    final borderLight = const Color(0xFFE2E8F0);

    final currentBg = isDarkMode ? bgDark : bgLight;
    final currentCard = isDarkMode ? cardDark : cardLight;
    final currentText = isDarkMode ? textDark : textLight;
    final currentBorder = isDarkMode ? borderDark : borderLight;

    final score = resultsData['score'] ?? 0;
    final totalMarks = resultsData['totalMarks'] ?? 100;
    final correctCount = resultsData['correctCount'] ?? 0;
    final totalQuestions = resultsData['totalQuestions'] ?? 0;
    final gradingDetails = resultsData['gradingDetails'] as List? ?? [];

    final percentage = totalMarks > 0 ? (score / totalMarks) * 100 : 0.0;
    final isPassed = percentage >= 50.0;

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        title: const Text(
          'Exam Score Report 📊',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Circular Score Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: currentCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: currentBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              children: [
                Text(
                  testTitle,
                  style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Spacer(), // dummy spacer just in case
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: totalMarks > 0 ? score / totalMarks : 0,
                        strokeWidth: 10,
                        backgroundColor: isDarkMode ? Colors.white10 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isPassed ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: isPassed ? Colors.green : Colors.orange,
                          ),
                        ),
                        Text(
                          '$score / $totalMarks Marks',
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Passed', isPassed ? 'Yes' : 'No', isPassed ? Colors.green : Colors.orange),
                    _buildStatItem('Correct', '$correctCount / $totalQuestions', currentText),
                    _buildStatItem('Accuracy', '${totalQuestions > 0 ? ((correctCount / totalQuestions) * 100).toStringAsFixed(0) : 0}%', currentText),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Detailed Review Title
          Row(
            children: [
              Icon(Icons.list_alt_rounded, color: const Color(0xFF4F46E5), size: 18),
              const SizedBox(width: 8),
              Text(
                'Question-by-Question Review',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: currentText),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Question-by-Question review list
          ...gradingDetails.map((detail) {
            final qIndex = (detail['questionIndex'] ?? 0) + 1;
            final qText = detail['questionText'] ?? '';
            final studentAns = detail['studentAnswer'] ?? '';
            final correctAns = detail['correctAnswer'] ?? '';
            final isCorrect = detail['isCorrect'] ?? false;
            final explanation = detail['explanation'] ?? '';

            final detailColor = isCorrect ? Colors.green : Colors.redAccent;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: currentBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: detailColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Q$qIndex',
                          style: TextStyle(color: detailColor, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          qText,
                          style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Answers review row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your Answer', style: TextStyle(color: Colors.grey, fontSize: 9)),
                            const SizedBox(height: 4),
                            Text(
                              studentAns,
                              style: TextStyle(
                                color: isCorrect ? Colors.green : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Correct Answer', style: TextStyle(color: Colors.grey, fontSize: 9)),
                              const SizedBox(height: 4),
                              Text(
                                correctAns,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  // AI Explanation block
                  if (explanation.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: currentBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Color(0xFF4F46E5), size: 12),
                              SizedBox(width: 6),
                              Text(
                                'AI Explanation',
                                style: TextStyle(color: Color(0xFF4F46E5), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            explanation,
                            style: TextStyle(color: currentText.withOpacity(0.8), fontSize: 11, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 12),

          // Return Home Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Back to Exam Portal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
