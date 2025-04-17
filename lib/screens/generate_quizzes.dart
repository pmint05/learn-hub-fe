import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn_hub/const/quizzes_generator_config.dart';
import 'package:learn_hub/services/quizzes_generator.dart';
import 'package:learn_hub/widgets/select_menu_tile.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'do_quizzes.dart';

class GenerateQuizzesScreen extends StatefulWidget {
  const GenerateQuizzesScreen({super.key});

  @override
  State<GenerateQuizzesScreen> createState() => _GenerateQuizzesScreenState();
}

class _GenerateQuizzesScreenState extends State<GenerateQuizzesScreen>
    with SingleTickerProviderStateMixin {
  void _startStatusRefreshTimer() {
    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      if (isCheckingStatus) return;
      if (_quizGenerator.currentTask != null &&
          [
            'pending',
            'processing',
          ].contains(_quizGenerator.currentTask!.status)) {
        try {
          if (mounted) {
            setState(() {
              isCheckingStatus = true;
            });
          }
          final status = await _quizGenerator.checkTaskStatus(
            _quizGenerator.currentTask!.taskId,
          );

          if (status == 'completed' || status == 'failed') {
            timer.cancel();
          }
        } catch (e) {
          print('Error refreshing status: $e');
        } finally {
          if (mounted) {
            setState(() {
              isCheckingStatus = false;
            });
          }
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(initialIndex: 0, length: 4, vsync: this);

    // Check for current task when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _quizGenerator.loadCurrentTask();
      if (mounted) setState(() {});
      _startStatusRefreshTimer();
    });
  }

  PlatformFile? selectedFileInfo;
  File? selectedFile;
  bool isGenerating = false;
  double progress = 0.0;
  String progressMessage = "";
  QuizzesType selectedType = QuizzesType.multipleChoice;
  QuizzesMode selectedMode = QuizzesMode.quiz;
  QuizzesDifficulty selectedDifficulty = QuizzesDifficulty.medium;
  int quizCount = -1;

  final int maxCount = 30;

  final QuizzesGenerator _quizGenerator = QuizzesGenerator();
  final statusColors = {
    "pending": Colors.yellow,
    "processing": Colors.blue,
    "completed": Colors.green,
    "failed": Colors.red,
  };

  final fileIcons = {
    "pdf": PhosphorIconsLight.filePdf,
    "docx": PhosphorIconsLight.fileText,
    "doc": PhosphorIconsLight.fileDoc,
    "txt": PhosphorIconsLight.fileTxt,
    "md": PhosphorIconsLight.fileMd,
  };

  final taskStatusesMessage = {
    "pending": "Your quiz will be generated soon.",
    "processing": "Your quiz is being processed.",
    "completed": "Your quiz is ready to use.",
    "not_found": "Task not found.",
    "failed": "Failed to generate quiz.",
  };

  final _formKey = GlobalKey<FormState>();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'txt', 'md'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        selectedFileInfo = result.files.single;
        if (selectedFileInfo!.path != null) {
          selectedFile = File(selectedFileInfo!.path!);
        }
      });
    }
  }

  final quizCountController = TextEditingController();
  final languageController = ValueNotifier<QuizzesLanguage>(
    QuizzesLanguage.auto,
  );
  final typeController = ValueNotifier<QuizzesType>(QuizzesType.mixed);
  final modeController = ValueNotifier<QuizzesMode>(QuizzesMode.quiz);
  final difficultyController = ValueNotifier<QuizzesDifficulty>(
    QuizzesDifficulty.easy,
  );

  late final TabController tabController;
  int currentIndex = 0;

  bool isCheckingStatus = false;
  Timer? _statusRefreshTimer;

  Future<void> _generateQuizzes() async {
    if (_formKey.currentState!.validate()) {
      if (selectedFile == null && selectedFileInfo == null) return;

      setState(() {
        isGenerating = true;
        progress = 0.0;
        progressMessage = "Starting...";
      });

      try {
        final config = QuizzesGeneratorConfig(
          source: QuizzesSource.file,
          type: typeController.value,
          mode: modeController.value,
          difficulty: difficultyController.value,
          numberOfQuiz: int.parse(quizCountController.text),
          language: languageController.value,
        );

        await _quizGenerator.createQuizzesTask(
          config: config,
          file: selectedFile,
          fileInfo: selectedFileInfo,
          onProgress: (progress, message) {
            setState(() {
              this.progress = progress;
              progressMessage = message;
            });
          },
        );

        // Start the status refresh timer
        _startStatusRefreshTimer();
      } catch (e) {
        print('Error generating quizzes: $e');

        if (context.mounted) {
          String errorMessage = 'Error: ${e.toString()}';

          if (e.toString().contains('422')) {
            errorMessage =
                'Invalid request parameters. Please check your quiz settings.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Theme.of(context).colorScheme.error,
              content: Text(errorMessage),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(label: 'Dismiss', onPressed: () {}),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isGenerating = false;
          });
        }
      }
    }
  }

  Widget _buildCurrentTaskInfo() {
    final cs = Theme.of(context).colorScheme;
    final currentTask = _quizGenerator.currentTask;

    if (currentTask == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Badge(
            label:
            currentTask.status == "processing"
                ? Row(
              children: [
                SizedBox(
                  height: 12,
                  width: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: statusColors[currentTask.status]?.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currentTask.status,
                  style: TextStyle(
                    color: statusColors[currentTask.status]?.withValues(
                      alpha: 0.8,
                    ),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
                : Text(
              currentTask.status,
              style: TextStyle(
                color: statusColors[currentTask.status]?.withValues(
                  alpha: 0.8,
                ),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: statusColors[currentTask.status]?.withValues(
              alpha: 0.2,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          const SizedBox(height: 16),
          Text(
            taskStatusesMessage[currentTask.status] ?? "Unknown status",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 8),
          _buildTaskInfoRow("ID", currentTask.taskId),
          _buildTaskInfoRow("Type", currentTask.config.type.label),
          _buildTaskInfoRow("Mode", currentTask.config.mode.label),
          _buildTaskInfoRow(
            "Count",
            currentTask.config.numberOfQuiz.toString(),
          ),
          _buildTaskInfoRow("Created", currentTask.createdAtHumanized),
          const SizedBox(height: 16),
          if (['error', 'not_found'].contains(currentTask.status)) ...[
            if (currentTask.errorMessage.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.error),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.fileX,
                      color: Colors.red.shade900,
                    ),
                    Text(
                      currentTask.errorMessage,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              icon: Icon(
                PhosphorIconsRegular.arrowClockwise,
                color: cs.primary,
              ),
              label: Text(
                "Create Another",
                style: TextStyle(color: cs.primary),
              ),
              onPressed: () async {
                await _quizGenerator.clearCurrentTask();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.surface,
                foregroundColor: cs.onSurface,
                side: BorderSide(color: cs.primary, width: 2),
              ),
            ),
          ],
          if (currentTask.status == 'completed') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(PhosphorIconsRegular.plus, color: cs.primary),
                label: Text(
                  "Create Another",
                  style: TextStyle(color: cs.primary),
                ),
                onPressed: () async {
                  await _quizGenerator.clearCurrentTask();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.surface,
                  foregroundColor: cs.onSurface,
                  side: BorderSide(color: cs.primary, width: 2),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await _quizGenerator.getTaskResult(
                    currentTask.taskId,
                  );
                  if (context.mounted) {
                    _quizGenerator.clearCurrentTask();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DoQuizzesScreen(quizzes: result),
                      ),
                    );
                  }
                },
                icon: Icon(PhosphorIconsRegular.clipboardText),
                label: Text("Start Quiz"),
              ),
            ),
          ],
          if (['pending', 'processing'].contains(currentTask.status))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (isCheckingStatus) return;
                  setState(() {
                    isCheckingStatus = true;
                  });
                  try {
                    final status = await _quizGenerator.checkTaskStatus(
                      currentTask.taskId,
                    );
                    if (status == 'completed' && context.mounted) {
                      final result = await _quizGenerator.getTaskResult(
                        currentTask.taskId,
                      );
                      if (context.mounted) {
                        _quizGenerator.clearCurrentTask();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => DoQuizzesScreen(quizzes: result),
                          ),
                        );
                      }
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        isCheckingStatus = false;
                      });
                    }
                  }
                },
                icon:
                    isCheckingStatus
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                        : Icon(PhosphorIconsRegular.arrowClockwise),
                label: Text("Check Status"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final List<Map<String, dynamic>> optionTabs = [
      {
        "label": "File",
        "icon": PhosphorIconsBold.file,
        "content": Material(
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: isGenerating ? null : _pickFile,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            child: Container(
              height: 180,
              width: double.infinity,
              padding: EdgeInsets.all(10),
              child:
                  selectedFileInfo == null
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          PhosphorIcon(
                            PhosphorIconsLight.uploadSimple,
                            size: 56,
                          ),
                          Text(
                            "Choose a PDF, docx, md, or txt file!",
                            style: TextStyle(
                              color: cs.onSurface,
                              fontFamily: "BricolageGrotesque",
                            ),
                          ),
                        ],
                      )
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          PhosphorIcon(
                            fileIcons[selectedFileInfo!.name.split('.').last] ??
                                PhosphorIconsLight.file,
                            size: 36,
                          ),
                          SizedBox(height: 4),
                          Text(
                            selectedFileInfo!.name.length > 20
                                ? "${selectedFileInfo!.name.substring(0, 20)}...${selectedFileInfo!.name.split('.').last}"
                                : selectedFileInfo!.name,
                            style: TextStyle(color: cs.onSurface),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "Tap to change file",
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
        "disabled": false,
      },
      {
        "label": "Text",
        "icon": PhosphorIconsBold.cursorText,
        "content": Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: TextFormField(
            decoration: InputDecoration(
              border: InputBorder.none,
              counterStyle: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
              hint: Text(
                "Enter text here...",
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ),
            minLines: 5,
            maxLines: 5,
            maxLength: 5000,
            scrollPhysics: ScrollPhysics(
              parent: NeverScrollableScrollPhysics(),
            ),
          ),
        ),
        "disabled": false,
      },
      {
        "label": "Image",
        "icon": PhosphorIconsBold.image,
        "content": Column(
          children: [
            TextFormField(),
            SizedBox(
              height: 30,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Divider(),
                  Text("OR", style: TextStyle(color: cs.onSurface)),
                  const Divider(),
                ],
              ),
            ),
            Container(child: const Placeholder()),
          ],
        ),
        "disabled": true,
      },
      {
        "label": "Link",
        "icon": PhosphorIconsBold.link,
        "content": const Placeholder(),
        "disabled": true,
      },
    ];

    final hasActiveTask = _quizGenerator.currentTask != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Quiz"),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsBold.question),
            onPressed: () {
              // Show help dialog
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text("Help"),
                      content: const Text("This is a help dialog."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Close"),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            _buildCurrentTaskInfo(),
            if (!hasActiveTask) ...[
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: cs.onSurface.withValues(alpha: 0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: Offset(0, 8),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          controller: tabController,
                          dividerColor: cs.surfaceDim,
                          tabs:
                              optionTabs.map((tab) {
                                return Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        tab["icon"],
                                        size: 16,
                                        color:
                                            tab["disabled"]
                                                ? cs.onSurface.withValues(
                                                  alpha: 0.25,
                                                )
                                                : null,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        tab["label"],
                                        style: TextStyle(
                                          fontFamily: 'BricolageGrotesque',
                                          color:
                                              tab["disabled"]
                                                  ? cs.onSurface.withValues(
                                                    alpha: 0.25,
                                                  )
                                                  : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          onTap: (index) {
                            if (optionTabs[index]["disabled"] == true) {
                              tabController.animateTo(currentIndex);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "${optionTabs[index]["label"]} option coming soon!",
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else {
                              currentIndex = index;
                              tabController.animateTo(index);
                            }
                          },
                          labelColor: cs.primary,
                          unselectedLabelColor: cs.onSurface,
                          indicatorSize: TabBarIndicatorSize.label,
                          indicator: UnderlineTabIndicator(
                            borderSide: BorderSide(color: cs.primary, width: 2),
                          ),
                        ),
                        SizedBox(
                          height: 180,
                          child: TabBarView(
                            controller: tabController,
                            physics: const NeverScrollableScrollPhysics(),
                            children:
                                optionTabs.map((tab) {
                                  return tab["disabled"]
                                      ? SizedBox.shrink()
                                      : SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        physics: BouncingScrollPhysics(),
                                        child: tab["content"],
                                      );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Settings",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.03, 0.95, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        spacing: 10,
                        children: [
                          TextFormField(
                            controller: quizCountController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter a number";
                              }
                              final intValue = int.tryParse(value);
                              if (intValue == null || intValue <= 0) {
                                return "Please enter a valid number";
                              }
                              if (intValue > maxCount) {
                                return "Maximum count is $maxCount";
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: cs.surface,
                              hint: Text(
                                "Enter number of quizzes",
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                                textAlign: TextAlign.end,
                              ),
                              prefixIcon: Padding(
                                padding: EdgeInsets.fromLTRB(15, 0, 5, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(PhosphorIconsRegular.hash, size: 24),
                                    SizedBox(width: 12),
                                    Text("Number of Quizzes"),
                                  ],
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                // borderSide: BorderSide(color: cs.surfaceDim),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                // borderSide: BorderSide(
                                //   color: cs.onSurface.withValues(alpha: 0.2),
                                // ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: cs.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textAlign: TextAlign.end,
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  quizCount = int.parse(value);
                                });
                              }
                            },
                          ),
                          _buildSelectField(
                            cs,
                            "Language",
                            QuizzesLanguage.values.map((l) {
                              return DropdownMenuEntry(
                                value: l,
                                label: l.label,
                              );
                            }).toList(),
                            languageController,
                            PhosphorIconsRegular.translate,
                          ),
                          _buildSelectField(
                            cs,
                            "Question Type",
                            QuizzesType.values.map((t) {
                              return DropdownMenuEntry(
                                value: t,
                                label: t.label,
                              );
                            }).toList(),
                            typeController,
                            PhosphorIconsRegular.question,
                          ),
                          _buildSelectField(
                            cs,
                            "Mode",
                            QuizzesMode.values.map((t) {
                              return DropdownMenuEntry(
                                value: t,
                                label: t.label,
                              );
                            }).toList(),
                            modeController,
                            PhosphorIconsRegular.squaresFour,
                          ),
                          _buildSelectField(
                            cs,
                            "Difficulty",
                            QuizzesDifficulty.values.map((t) {
                              return DropdownMenuEntry(
                                value: t,
                                label: t.label,
                              );
                            }).toList(),
                            difficultyController,
                            PhosphorIconsRegular.chartBar,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                onPressed:
                    selectedFileInfo == null || isGenerating || quizCount <= 0
                        ? null
                        : _generateQuizzes,
                label:
                    !isGenerating
                        ? Text("Generate Quizzes")
                        : Text(
                          "Initializing... ${(progress * 100).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}%",
                        ),
                icon:
                    !isGenerating
                        ? Icon(PhosphorIconsRegular.magicWand)
                        : SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              cs.onPrimary,
                            ),
                            color: cs.onPrimary,
                          ),
                        ),
                backgroundColor:
                    selectedFileInfo == null || quizCount <= 0
                        ? cs.onSurface.withValues(alpha: 0.1)
                        : cs.primary,
                foregroundColor:
                    selectedFileInfo == null || quizCount <= 0
                        ? cs.onSurface.withValues(alpha: 0.5)
                        : cs.onPrimary,
                disabledElevation: 0,
                elevation: 0,
                highlightElevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectField(
    ColorScheme cs,
    String label,
    List<DropdownMenuEntry> entries,
    ValueNotifier valueController,
    IconData leadingIcon,
  ) {
    return DropdownMenu(
      width: double.infinity,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          // borderSide: BorderSide(color: cs.surfaceDim),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        // outlineBorder: BorderSide(color: cs.primary, width: 1.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          // borderSide: BorderSide(color: cs.surfaceDim),
        ),
      ),
      leadingIcon: Padding(
        padding: EdgeInsets.fromLTRB(15, 0, 5, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(leadingIcon, size: 24),
            SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
      textAlign: TextAlign.end,
      onSelected: (value) {
        setState(() {
          valueController.value = value!;
        });
      },
      initialSelection: valueController.value,
      dropdownMenuEntries: entries,
    );
  }

  @override
  void dispose() {
    languageController.dispose();
    modeController.dispose();
    difficultyController.dispose();
    typeController.dispose();
    quizCountController.dispose();
    tabController.dispose();
    super.dispose();
  }

  String valueToTitle<T>(T value) {
    return value.toString().split(".").last.replaceAll("}", "");
  }
}
