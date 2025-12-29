import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learn_hub/configs/router_config.dart';
import 'package:learn_hub/const/quizzes_generator_config.dart';
import 'package:learn_hub/screens/ask.dart';
import 'package:learn_hub/services/quizzes_generator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

final statusColors = {
  "pending": Colors.yellow,
  "processing": Colors.blue,
  "completed": Colors.green,
  "failed": Colors.red,
  "error": Colors.red,
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
  "error": "Something went wrong!",
};

class GenerateQuizzesScreen extends StatefulWidget {
  final ContextFileInfo? materialDocument;

  const GenerateQuizzesScreen({super.key, this.materialDocument});

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
          await _quizGenerator.checkCurrentTaskStatus();
          final status = _quizGenerator.currentTask?.status ?? 'not_found';
          if (status == 'completed' ||
              status == 'failed' ||
              status == 'error') {
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
    tabController = TabController(initialIndex: 0, length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _quizGenerator.loadCurrentTask();
      if (mounted) setState(() {});
      _startStatusRefreshTimer();
    });
    if (widget.materialDocument != null) {
      print("Received material document: ${widget.materialDocument}");
      if (_quizGenerator.currentTask != null) {
        _quizGenerator.clearCurrentTask();
      }
      setState(() {
        _materialInfo = widget.materialDocument;
        tabController.animateTo(4);
        currentIndex = 4;
      });
    }
  }

  PlatformFile? _selectedFileInfo;
  File? _selectedFile;
  File? _selectedImageFile;
  PlatformFile? _selectedImageInfo;
  String? _previewImagePath;
  ContextFileInfo? _materialInfo;

  TextEditingController textContentController = TextEditingController();
  TextEditingController linkController = TextEditingController();

  bool isGenerating = false;
  double progress = 0.0;
  String progressMessage = "";
  QuizzesType selectedType = QuizzesType.multipleChoice;
  QuizzesMode selectedMode = QuizzesMode.quiz;
  QuizzesDifficulty selectedDifficulty = QuizzesDifficulty.medium;
  int quizCount = -1;
  bool isPublic = false;

  final int maxCount = 30;

  final QuizzesGenerator _quizGenerator = QuizzesGenerator();

  final _formKey = GlobalKey<FormState>();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt', 'md'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedFileInfo = result.files.single;
        if (_selectedFileInfo!.path != null) {
          _selectedFile = File(_selectedFileInfo!.path!);
        }
      });
    }
  }

  Future<void> _pickImage() async {
    if (await Permission.mediaLibrary.request().isDenied) {
      if (mounted) {
        showGeneralDialog(
          context: context,
          pageBuilder: (_, __, ___) {
            return AlertDialog(
              title: const Text("Permission Denied"),
              content: const Text("Please allow access to your media library."),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    final imageSize = await pickedFile?.length() ?? 0;

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _previewImagePath = pickedFile.path;
        _selectedImageInfo = PlatformFile(
          name: pickedFile.name,
          size: imageSize,
          path: _previewImagePath,
        );
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
      if (currentIndex == 0 &&
          _selectedFile == null &&
          _selectedFileInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a document file')),
        );
        return;
      } else if (currentIndex == 1 &&
          (textContentController.text.isEmpty ||
              textContentController.text.length < 10)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter sufficient text content (at least 10 characters)',
            ),
          ),
        );
        return;
      } else if (currentIndex == 2 &&
          _selectedImageFile == null &&
          _selectedImageInfo == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please select an image file')));
        return;
      } else if (currentIndex == 3 &&
          (linkController.text.isEmpty ||
              !Uri.parse(linkController.text).isAbsolute)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please enter a valid URL')));
        return;
      } else if (currentIndex == 4 && _materialInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a document in Material tab')),
        );
        return;
      }

      setState(() {
        isGenerating = true;
        progress = 0.0;
        progressMessage = "Starting...";
      });

      try {
        File? file;
        PlatformFile? info;
        QuizzesSource sourceType;
        switch (currentIndex) {
          case 0:
            sourceType = QuizzesSource.file;
            file = _selectedFile;
            info = _selectedFileInfo;
          case 1:
            sourceType = QuizzesSource.text;
          case 2:
            sourceType = QuizzesSource.image;
            file = _selectedImageFile;
            info = _selectedImageInfo;
          case 3:
            sourceType = QuizzesSource.link;
          case 4:
            sourceType = QuizzesSource.material;
          default:
            sourceType = QuizzesSource.file;
        }

        final config = QuizzesGeneratorConfig(
          source: sourceType,
          type: typeController.value,
          mode: modeController.value,
          difficulty: difficultyController.value,
          numberOfQuiz: int.parse(quizCountController.text),
          language: languageController.value,
          isPublic: isPublic,
        );

        await _quizGenerator.createQuizzesTask(
          config: config,
          file: file,
          fileInfo: info,
          text: textContentController.text,
          url: linkController.text,
          materialId: _materialInfo?.id,
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
      child: SingleChildScrollView(
        padding: EdgeInsets.all(10),
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
                              color: statusColors[currentTask.status]
                                  ?.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentTask.status,
                            style: TextStyle(
                              color: statusColors[currentTask.status]
                                  ?.withValues(alpha: 0.8),
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
              textAlign: TextAlign.center,
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
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 100),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.error),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        Icon(PhosphorIconsRegular.fileX, color: cs.error),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Text(
                              currentTask.errorMessage,
                              style: TextStyle(color: cs.error),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                    final response = await _quizGenerator.getTaskResult(
                      currentTask.taskId,
                    );
                    if (mounted) {
                      _quizGenerator.clearCurrentTask();
                      setState(() {
                        isGenerating = false;
                        progress = 0.0;
                        progressMessage = "";
                      });
                      context.pushNamed(
                        AppRoute.doQuizzes.name,
                        extra: {
                          'prevRoute': null,
                          'quiz_id': response['result']['_id'],
                        },
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
                      await _quizGenerator.checkCurrentTaskStatus();
                      final status =
                          _quizGenerator.currentTask?.status ?? 'not_found';
                      if (status == 'completed' && context.mounted) {
                        final response = await _quizGenerator.getTaskResult(
                          currentTask.taskId,
                        );
                        if (mounted) {
                          _quizGenerator.clearCurrentTask();
                          context.pushNamed(
                            AppRoute.doQuizzes.name,
                            extra: {
                              'quiz_id': response['result']['_id'],
                              'prevRoute': null,
                            },
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

  bool _isButtonEnabled() {
    if (quizCount <= 0 || isGenerating) return false;

    switch (currentIndex) {
      case 0: // File tab
        return _selectedFileInfo != null;
      case 1: // Text tab
        return textContentController.text.isNotEmpty &&
            textContentController.text.length >= 10;
      case 2: // Image tab
        return _selectedImageInfo != null;
      case 3: // Link tab
        return linkController.text.isNotEmpty &&
            Uri.parse(linkController.text).isAbsolute;
      case 4: // Material tab
        return _materialInfo != null;
      default:
        return false;
    }
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
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: isGenerating ? null : _pickFile,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            child: Container(
              height: 180,
              width: double.infinity,
              padding: EdgeInsets.all(10),
              child:
                  _selectedFileInfo == null
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
                            fileIcons[_selectedFileInfo!.name
                                    .split('.')
                                    .last] ??
                                PhosphorIconsLight.file,
                            size: 36,
                          ),
                          SizedBox(height: 4),
                          Text(
                            _selectedFileInfo!.name.length > 20
                                ? "${_selectedFileInfo!.name.substring(0, 20)}...${_selectedFileInfo!.name.split('.').last}"
                                : _selectedFileInfo!.name,
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
            controller: textContentController,
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
        "content": Material(
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: isGenerating ? null : _pickImage,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child:
                  _selectedImageFile == null
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          PhosphorIcon(
                            PhosphorIconsLight.uploadSimple,
                            size: 56,
                          ),
                          Text(
                            "Choose an image (png, jpg or jpeg file)!",
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
                        spacing: 8,
                        children: [
                          if (_selectedImageFile != null &&
                              _previewImagePath != null)
                            Image.file(
                              File(_previewImagePath!),
                              height: 135,
                              width: 500,
                              frameBuilder: (
                                context,
                                child,
                                frame,
                                wasSynchronouslyLoaded,
                              ) {
                                if (wasSynchronouslyLoaded) {
                                  return child;
                                }
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeIn,
                                  child: child,
                                );
                              },
                              fit: BoxFit.contain,
                            )
                          else
                            PhosphorIcon(PhosphorIconsLight.image, size: 36),
                          Text(
                            "Tap to change image",
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
        "label": "Link",
        "icon": PhosphorIconsBold.link,
        "content": Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: TextFormField(
            controller: linkController,
            decoration: InputDecoration(
              border: InputBorder.none,
              counterStyle: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
              hint: Text(
                "Enter URL here...",
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ),
            minLines: 1,
            maxLines: 5,
            scrollPhysics: ScrollPhysics(
              parent: NeverScrollableScrollPhysics(),
            ),
          ),
        ),
        "disabled": false,
      },
      {
        "label": "Material",
        "icon": PhosphorIconsBold.book,
        "content": SizedBox(
          height: 180,
          child:
              _materialInfo == null
                  ? Text(
                    "Please come to Material tab to choose a file and click 'Generate Quizzes From This'",
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        fileIcons[_materialInfo!.extension] ??
                            PhosphorIconsLight.file,
                        size: 36,
                      ),
                      SizedBox(height: 4),
                      Text(
                        _materialInfo!.filename != null &&
                                _materialInfo!.filename!.length > 20
                            ? "${_materialInfo!.filename!.substring(0, 20)}...${_materialInfo!.extension}"
                            : "${_materialInfo!.filename}.${_materialInfo!.extension}" ??
                                "",
                        style: TextStyle(color: cs.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        _materialInfo!.size! > 0
                            ? "${(_materialInfo!.size! / 1024).toStringAsFixed(2)} KB"
                            : "0 KB",
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        "ID: ${_materialInfo!.id}",
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
        ),
        "disabled": false,
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
                      borderRadius: BorderRadius.circular(12),
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
                          isScrollable: true,
                          tabAlignment: TabAlignment.center,
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
                        cs.surface.withValues(alpha: 0),
                        Colors.white,
                        Colors.white,
                        cs.surface.withValues(alpha: 0),
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
                                "eg. 20",
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
                                    Text("Number of Questions"),
                                  ],
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                // borderSide: BorderSide(color: cs.surfaceDim),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                // borderSide: BorderSide(
                                //   color: cs.onSurface.withValues(alpha: 0.2),
                                // ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
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
                          _buildPrivacySwitcher(cs),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ButtonStyle(
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                ),
                onPressed:
                    isGenerating || !_isButtonEnabled()
                        ? null
                        : _generateQuizzes,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isGenerating) ...[
                      SizedBox(
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
                      const SizedBox(width: 8),
                    ],
                    Text(
                      isGenerating
                          ? "Initializing... ${(progress * 100).toStringAsFixed(2).replaceAll(".00", "")}%"
                          : "Generate Quizzes",
                      style: TextStyle(
                        color:
                            _isButtonEnabled()
                                ? cs.onPrimary
                                : cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
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
          borderRadius: BorderRadius.circular(12),
          // borderSide: BorderSide(color: cs.surfaceDim),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        // outlineBorder: BorderSide(color: cs.primary, width: 1.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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

  Widget _buildPrivacySwitcher(ColorScheme cs) {
    WidgetStateProperty<Color?> trackColor =
        WidgetStateProperty<Color?>.fromMap(<WidgetStatesConstraint, Color>{
          WidgetState.selected: Theme.of(context).colorScheme.primary,
          WidgetState.disabled: Colors.grey.shade400,
          WidgetState.scrolledUnder: Colors.grey.shade400,
        });
    final WidgetStateProperty<Color?> overlayColor =
        WidgetStateProperty<Color?>.fromMap(<WidgetState, Color>{
          WidgetState.selected: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.54),
          WidgetState.disabled: Colors.grey.shade400,
        });
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.globe, size: 24),
          const SizedBox(width: 12),
          Text(
            "Publish this quiz?",
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          const Spacer(),
          Switch(
            overlayColor: overlayColor,
            trackColor: trackColor,
            thumbColor: WidgetStatePropertyAll<Color>(cs.onSurface),
            value: isPublic,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              setState(() {
                isPublic = value;
              });
            },
          ),
        ],
      ),
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
    textContentController.dispose();
    linkController.dispose();
    _statusRefreshTimer?.cancel();
    super.dispose();
  }

  String valueToTitle<T>(T value) {
    return value.toString().split(".").last.replaceAll("}", "");
  }
}
