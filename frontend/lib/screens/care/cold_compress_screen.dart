import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_colors.dart';

class ColdCompressScreen extends StatefulWidget {
  const ColdCompressScreen({super.key});

  @override
  State<ColdCompressScreen> createState() => _ColdCompressScreenState();
}

class _ColdCompressScreenState extends State<ColdCompressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CareProvider>(context, listen: false).fetchCareData();
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final careProvider = Provider.of<CareProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cold Compress Therapy'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              Text(
                'Soothing Ocular Relief Timer',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Software-guided cold compress therapy reduces histamine-induced swelling and conjunctival hyperemia.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),

              // Duration Selector Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [300, 600, 900].map((sec) {
                  final mins = sec ~/ 60;
                  final isSelected = careProvider.initialSeconds == sec;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: ChoiceChip(
                      label: Text('$mins Mins'),
                      selected: isSelected,
                      selectedColor: AppColors.accent,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: careProvider.isTimerRunning
                          ? null
                          : (val) {
                              if (val) careProvider.setTimerDuration(sec);
                            },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Timer Dial Circular Container
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: careProvider.isTimerRunning ? AppColors.accent : AppColors.border,
                    width: careProvider.isTimerRunning ? 4 : 2,
                  ),
                  boxShadow: const [
                    BoxShadow(color: AppColors.shadowColor, blurRadius: 20, offset: Offset(0, 8))
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.ac_unit_rounded, size: 40, color: AppColors.accent),
                      const SizedBox(height: 12),
                      Text(
                        _formatTime(careProvider.timerSecondsRemaining),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        careProvider.isTimerRunning
                            ? 'THERAPY IN PROGRESS'
                            : careProvider.isTimerCompleted
                                ? 'SESSION COMPLETED 🎉'
                                : 'READY TO START',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: careProvider.isTimerRunning ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Control Buttons (Start / Pause / Reset)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!careProvider.isTimerRunning) ...[
                    ElevatedButton.icon(
                      onPressed: () => careProvider.startTimer(),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start Compress'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size(180, 54),
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: () => careProvider.pauseTimer(),
                      icon: const Icon(Icons.pause_rounded),
                      label: const Text('Pause'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.riskModerate,
                        minimumSize: const Size(140, 54),
                      ),
                    ),
                  ],
                  const SizedBox(width: 14),
                  OutlinedButton(
                    onPressed: () => careProvider.resetTimer(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(100, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Session History List
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Previous Sessions', style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 14),

              if (careProvider.compressSessions.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No previous compress sessions recorded.', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: careProvider.compressSessions.length,
                  itemBuilder: (context, index) {
                    final session = careProvider.compressSessions[index];
                    final mins = session.durationSeconds ~/ 60;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.riskLow),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$mins Minute Cold Compress',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    session.timestamp.toString().split('.')[0],
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Text(
                            'Completed',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.riskLow, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
