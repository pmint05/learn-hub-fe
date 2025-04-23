import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:learn_hub/const/constants.dart';
import 'package:learn_hub/const/material_service_config.dart';
import 'package:learn_hub/screens/ask.dart';
import 'package:learn_hub/services/material_manager.dart';
import 'package:learn_hub/utils/api_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum TaskState {
  uploading("Uploading..."),
  deleting("Deleting..."),
  downloading("Downloading..."),
  renaming("Renaming..."),
  searching("Searching...");

  final String message;

  const TaskState(this.message);
}

class MaterialDocument {
  final String id;
  final String name;
  final String extension;
  final int size;
  final DateTime dateAdded;
  final bool isPublic;
  final String url;
  final String userId;

  MaterialDocument({
    required this.id,
    required this.name,
    required this.extension,
    required this.size,
    required this.dateAdded,
    required this.isPublic,
    required this.url,
    required this.userId,
  });
}

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _totalResults = 0;
  final int _pageSize = 8;
  int _currentPage = 0;
  bool _hasMoreData = true;

  late ScrollController _scrollController;

  bool _isProcessingTask = false;
  TaskState _currentTaskState = TaskState.searching;

  bool _isMultiSelectMode = false;
  final Set<String> _selectedDocuments = {};
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _renameController = TextEditingController();

  SortOption _currentSortOption = SortOption.dateDesc;
  FileExtension _currentFileExtension = FileExtension.all;
  String _searchQuery = '';

  List<MaterialDocument> _documents = [];
  List<MaterialDocument> _filteredDocuments = [];

  Timer? _debounce;

  late ColorScheme cs = Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchChanged);
    _loadDocuments();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _renameController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = _searchController.text;
        _currentPage = 0;
        _hasMoreData = true;
        _applyFilters();
      });
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData && !_isProcessingTask) {
        _loadMoreDocuments();
      }
    }
  }

  Future<void> _loadDocuments() async {
    try {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _hasMoreData = true;
      });

      final response = await MaterialManager.instance.searchMaterial(
        SearchMaterialConfig(
          searchText: _searchQuery,
          isPublic: false,
          size: _pageSize,
          start: _currentPage * _pageSize,
        ),
      );
      if (response.isNotEmpty) {
        if (response['status'] == 'success') {
          _totalResults = response['total'] ?? 0;
          _documents =
              (response['data'] as List)
                  .map(
                    (doc) => MaterialDocument(
                      id: doc['_id'],
                      name: doc['filename'],
                      extension: doc['file_extension'] ?? "",
                      size: doc['file_size'] ?? 0,
                      dateAdded: DateTime.parse(doc['date']),
                      isPublic: doc['is_public'],
                      url: doc['file_url'],
                      userId: doc['user_id'],
                    ),
                  )
                  .toList();
          setState(() {
            _filteredDocuments = _documents;
          });
        } else {
          print('Error loading documents: ${response['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading documents: ${response['message']}'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading documents: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading documents: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreDocuments() async {
    if (!_hasMoreData || _isLoadingMore) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final nextPage = _currentPage + 1;
      final response = await MaterialManager.instance.searchMaterial(
        SearchMaterialConfig(
          searchText: _searchQuery,
          fileExtension:
              _currentFileExtension == FileExtension.all
                  ? null
                  : _currentFileExtension,
          isPublic: false,
          size: _pageSize,
          start: nextPage * _pageSize,
        ),
      );
      _handleSearchResponse(response, true);

      if (_hasMoreData) {
        _currentPage = nextPage;
      }
    } catch (e) {
      print('Error loading more documents: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading more documents: $e')),
      );
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _handleSearchResponse(
    Map<String, dynamic> response,
    bool isLoadingMore,
  ) {
    if (response.isNotEmpty) {
      if (response['status'] == 'success') {
        _totalResults = response['total'] ?? 0;
        final List<MaterialDocument> newDocuments =
            (response['data'] as List)
                .map(
                  (doc) => MaterialDocument(
                    id: doc['_id'],
                    name: doc['filename'],
                    extension: doc['file_extension'] ?? "",
                    size: doc['file_size'] ?? 0,
                    dateAdded: DateTime.parse(doc['date']),
                    isPublic: doc['is_public'],
                    url: doc['file_url'],
                    userId: doc['user_id'],
                  ),
                )
                .toList();

        setState(() {
          if (isLoadingMore) {
            _filteredDocuments.addAll(newDocuments);
            _documents.addAll(newDocuments);
          } else {
            _filteredDocuments = newDocuments;
            _documents = newDocuments;
          }

          _hasMoreData = response['total'] == _pageSize;
        });


        print('Loaded ${newDocuments.length} more documents');
      }
    } else {
      setState(() {
        _hasMoreData = false;
      });
      print('Error loading more documents: ${response['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading more documents: ${response['message']}'),
        ),
      );
    }
  }

  void _applyFilters() async {
    try {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _hasMoreData = true;
      });
      final SearchMaterialConfig config = SearchMaterialConfig(
        searchText: _searchQuery,
        fileExtension:
            _currentFileExtension == FileExtension.all
                ? null
                : _currentFileExtension,
        isPublic: false,
        size: _pageSize,
        start: 0,
      );

      final response = await MaterialManager.instance.searchMaterial(config);
      if (response.isNotEmpty) {
        if (response['status'] == 'success') {
          _filteredDocuments =
              (response['data'] as List)
                  .map(
                    (doc) => MaterialDocument(
                      id: doc['_id'],
                      name: doc['filename'],
                      extension: doc['file_extension'] ?? "",
                      size: doc['file_size'] ?? 0,
                      dateAdded: DateTime.parse(doc['date']),
                      isPublic: doc['is_public'],
                      url: doc['file_url'],
                      userId: doc['user_id'],
                    ),
                  )
                  .toList();
          setState(() {});
        } else {
          print('Error applying filters: ${response['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error applying filters: ${response['message']}'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error applying filters: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error applying filters: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    // var filtered =
    //     _documents
    //         .where(
    //           (doc) =>
    //               doc.name.toLowerCase().contains(_searchQuery.toLowerCase()),
    //         )
    //         .toList();
    //
    // // Filter by file type
    // if (_currentFileExtension != FileExtension.all) {
    //   filtered =
    //       filtered
    //           .where(
    //             (doc) =>
    //                 doc.extension.toLowerCase() ==
    //                 _currentFileExtension.name.toLowerCase(),
    //           )
    //           .toList();
    // }
    //
    // // Sort documents
    // switch (_currentSortOption) {
    //   case SortOption.nameAsc:
    //     filtered.sort((a, b) => a.name.compareTo(b.name));
    //   case SortOption.nameDesc:
    //     filtered.sort((a, b) => b.name.compareTo(a.name));
    //   case SortOption.dateAsc:
    //     filtered.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
    //   case SortOption.dateDesc:
    //     filtered.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    //   case SortOption.sizeAsc:
    //     filtered.sort((a, b) => a.size.compareTo(b.size));
    //   case SortOption.sizeDesc:
    //     filtered.sort((a, b) => b.size.compareTo(a.size));
    // }
    //
    // setState(() {
    //   _filteredDocuments = filtered;
    // });
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'md', 'txt'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _isProcessingTask = true;
          _currentTaskState = TaskState.uploading;
        });

        if (result.files.isEmpty) {
          setState(() {
            _isProcessingTask = false;
            _currentTaskState = TaskState.searching;
          });
          return;
        }

        final file = result.files.first;

        final response = await MaterialManager.instance.uploadMaterial(
          FileUploadConfig(
            file: File(file.path!),
            isPublic: false,
            fileInfo: file,
          ),
        );

        if (response['status'] == 'error') {
          setState(() {
            _isProcessingTask = false;
            _currentTaskState = TaskState.searching;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading file: ${response['message']}'),
            ),
          );
          return;
        }

        print(response);

        final newDoc = MaterialDocument(
          id: response['data']['_id'],
          name: file.name,
          extension: file.extension ?? '',
          size: response['data']['file_size'] ?? 0,
          dateAdded: DateTime.parse(response['data']['date']),
          isPublic: response['data']['is_public'],
          url: response['data']['file_url'],
          userId: response['data']['user_id'],
        );

        setState(() {
          _documents.add(newDoc);
          _applyFilters();
          _isProcessingTask = false;
          _currentTaskState = TaskState.searching;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.files.length} file(s) uploaded successfully',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error uploading file: $e');
      setState(() {
        _isProcessingTask = false;
        _currentTaskState = TaskState.searching;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
    }
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedDocuments.clear();
      }
    });
  }

  void _toggleDocumentSelection(String docId) {
    setState(() {
      if (_selectedDocuments.contains(docId)) {
        _selectedDocuments.remove(docId);
      } else {
        _selectedDocuments.add(docId);
      }
    });
  }

  void _showSortFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sort & Filter',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(PhosphorIconsRegular.x),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sort by',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildSortChip(
                          SortOption.nameAsc,
                          'Name (A-Z)',
                          setModalState,
                        ),
                        _buildSortChip(
                          SortOption.nameDesc,
                          'Name (Z-A)',
                          setModalState,
                        ),
                        _buildSortChip(
                          SortOption.dateDesc,
                          'Newest first',
                          setModalState,
                        ),
                        _buildSortChip(
                          SortOption.dateAsc,
                          'Oldest first',
                          setModalState,
                        ),
                        _buildSortChip(
                          SortOption.sizeDesc,
                          'Largest first',
                          setModalState,
                        ),
                        _buildSortChip(
                          SortOption.sizeAsc,
                          'Smallest first',
                          setModalState,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Filter by type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFileExtensionChip(
                          FileExtension.all,
                          'All',
                          setModalState,
                        ),
                        _buildFileExtensionChip(
                          FileExtension.pdf,
                          'PDF',
                          setModalState,
                        ),
                        _buildFileExtensionChip(
                          FileExtension.doc,
                          'DOC',
                          setModalState,
                        ),
                        _buildFileExtensionChip(
                          FileExtension.docx,
                          'DOCX',
                          setModalState,
                        ),
                        _buildFileExtensionChip(
                          FileExtension.md,
                          'MD',
                          setModalState,
                        ),
                        _buildFileExtensionChip(
                          FileExtension.txt,
                          'TXT',
                          setModalState,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        child: Text('Apply'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildSortChip(
    SortOption option,
    String label,
    StateSetter setModalState,
  ) {
    final isSelected = _currentSortOption == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          _currentSortOption = option;
        });
      },
      backgroundColor: cs.surface,
      labelStyle: TextStyle(
        color: isSelected ? cs.primary : cs.onSurfaceVariant,
      ),
      selectedColor: cs.primary.withValues(alpha: 0.2),
      checkmarkColor: cs.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? cs.primary : cs.surfaceDim),
      ),
    );
  }

  Widget _buildFileExtensionChip(
    FileExtension type,
    String label,
    StateSetter setModalState,
  ) {
    final isSelected = _currentFileExtension == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          _currentFileExtension = type;
        });
      },
      backgroundColor: cs.surface,
      labelStyle: TextStyle(
        color: isSelected ? cs.primary : cs.onSurfaceVariant,
      ),
      selectedColor: cs.primary.withValues(alpha: 0.2),
      checkmarkColor: cs.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? cs.primary : cs.surfaceDim),
      ),
    );
  }

  void _showDocumentOptions(MaterialDocument doc) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                leading: Icon(PhosphorIconsRegular.chatDots, color: cs.primary),
                title: Text('Send to Chat'),
                onTap: () {
                  Navigator.pop(context);
                  if (context.mounted) {
                    context.go(
                      "/chat",
                      extra: [
                        ContextFileInfo(
                          id: doc.id,
                          filename: doc.name,
                          extension: doc.extension,
                          size: doc.size,
                        ),
                      ],
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  PhosphorIconsRegular.pencilSimple,
                  color: cs.primary,
                ),
                title: Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(doc);
                },
              ),
              ListTile(
                leading: Icon(
                  PhosphorIconsRegular.downloadSimple,
                  color: cs.primary,
                ),
                title: Text('Download'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadDocument(doc);
                },
              ),
              ListTile(
                leading: Icon(PhosphorIconsRegular.trash, color: cs.error),
                title: Text('Delete', style: TextStyle(color: cs.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation([doc.id]);
                },
              ),
            ],
          ),
    );
  }

  void _showRenameDialog(MaterialDocument doc) {
    _renameController.text = doc.name;
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder:
          (context) => AlertDialog(
            title: Text('Rename Document'),
            content: TextField(
              controller: _renameController,
              autofocus: true,
              decoration: InputDecoration(hintText: 'Enter new name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final newName = _renameController.text;
                  Navigator.pop(context);
                  // Implement rename functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Document renamed to $newName')),
                  );
                },
                child: Text('Rename'),
              ),
            ],
          ),
    );
  }

  Future<void> _downloadDocument(MaterialDocument doc) async {
    final status = await Permission.storage.request();

    if (status.isGranted) {
      // Simulate download
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Downloading ${doc.name}...')));

      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${doc.name} downloaded successfully')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Storage permission denied')));
    }
  }

  void _showDeleteConfirmation(List<String> docIds) {
    final int count = docIds.length;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Delete ${count > 1 ? "$count Documents" : "Document"}',
            ),
            content: Text(
              'Are you sure you want to delete ${count > 1 ? "these $count documents" : "this document"}? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  _deleteDocuments(docIds);
                },
                child: Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _deleteDocuments(List<String> docIds) async {
    try {
      setState(() {
        _isProcessingTask = true;
        _currentTaskState = TaskState.deleting;
      });

      final List<String> failedIds = [];

      for (final docId in docIds) {
        final response = await MaterialManager.instance.deleteMaterialById(
          docId,
        );
        if (response['status'] != 'success') {
          failedIds.add(docId);
        }
      }

      setState(() {
        _documents.removeWhere(
          (doc) => docIds.contains(doc.id) && !failedIds.contains(doc.id),
        );
        _selectedDocuments.removeAll(docIds);
        // _applyFilters();
      });

      final String message =
          failedIds.isNotEmpty
              ? 'Some documents could not be deleted: ${failedIds.join(', ')}'
              : 'Documents deleted successfully';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          // action: SnackBarAction(
          //   label: 'Undo',
          //   onPressed: () {
          //     // Implement undo functionality
          //   },
          // ),
        ),
      );
    } catch (e) {
      print('Error deleting documents: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting documents: $e')));
    } finally {
      setState(() {
        _isProcessingTask = false;
        _currentTaskState = TaskState.searching;
      });
    }
  }

  Widget _buildDocumentCard(MaterialDocument doc) {
    final isSelected = _selectedDocuments.contains(doc.id);

    IconData getFileIcon() {
      switch (doc.extension.toLowerCase()) {
        case 'pdf':
          return PhosphorIconsRegular.filePdf;
        case 'doc':
        case 'docx':
          return PhosphorIconsRegular.fileDoc;
        case 'md':
          return PhosphorIconsRegular.fileText;
        case 'txt':
          return PhosphorIconsRegular.fileText;
        default:
          return PhosphorIconsRegular.file;
      }
    }

    Color getFileColor() {
      switch (doc.extension.toLowerCase()) {
        case 'pdf':
          return Colors.orange;
        case 'doc':
        case 'docx':
          return Colors.blue;
        case 'md':
          return Colors.cyan;
        case 'txt':
          return Colors.grey;
        default:
          return Colors.blueGrey;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color:
          isSelected ? cs.primaryContainer.withValues(alpha: 0.7) : cs.surface,
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (_isMultiSelectMode) {
            _toggleDocumentSelection(doc.id);
          } else {
            // View document
          }
        },
        onLongPress: () {
          if (_isMultiSelectMode) {
            _toggleDocumentSelection(doc.id);
          } else {
            _showDocumentOptions(doc);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: getFileColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(getFileIcon(), color: getFileColor(), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${_formatFileSize(doc.size)} • ',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, yyyy').format(doc.dateAdded),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isMultiSelectMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    _toggleDocumentSelection(doc.id);
                  },
                )
              else
                IconButton(
                  icon: Icon(PhosphorIconsRegular.dotsThreeVertical),
                  onPressed: () {
                    _showDocumentOptions(doc);
                  },
                  color: cs.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton(
          onPressed: _pickAndUploadFile,
          child: Icon(PhosphorIconsRegular.plus),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintStyle: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                          hintText: 'Search materials...',
                          prefixIcon: Icon(
                            PhosphorIconsRegular.magnifyingGlass,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: cs.surface.withValues(alpha: 0.5),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(PhosphorIconsRegular.funnelSimple),
                      onPressed: _showSortFilterBottomSheet,
                    ),
                    IconButton(
                      icon: Icon(
                        _isMultiSelectMode
                            ? PhosphorIconsRegular.checkSquare
                            : PhosphorIconsRegular.square,
                      ),
                      onPressed: _toggleMultiSelectMode,
                    ),
                  ],
                ),
                if (_selectedDocuments.isNotEmpty)
                  AnimationConfiguration.staggeredList(
                    position: 0,
                    duration: const Duration(milliseconds: 375),
                    child: FadeInAnimation(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedDocuments.length} selected',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    PhosphorIconsRegular.downloadSimple,
                                  ),
                                  onPressed: () {
                                    // Download selected
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    PhosphorIconsRegular.trash,
                                    color: cs.error,
                                  ),
                                  onPressed: () {
                                    _showDeleteConfirmation(
                                      _selectedDocuments.toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isProcessingTask)
            Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Column(
                spacing: 8,
                children: [
                  Text(
                    _currentTaskState.message,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  LinearProgressIndicator(
                    value: null,
                    backgroundColor: cs.surface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          if (_isLoading && _currentPage == 0) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ] else if (_filteredDocuments.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIconsRegular.fileX,
                      size: 64,
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No documents found',
                      style: TextStyle(
                        fontSize: 16,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: Icon(PhosphorIconsRegular.plus),
                      label: Text('Upload Document'),
                      onPressed: _pickAndUploadFile,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ShaderMask(
                shaderCallback:
                    (bounds) => LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.white,
                        Colors.white,
                        cs.surface.withValues(alpha: 0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.0, 0.9, 1.0],
                    ).createShader(bounds),
                child: AnimationLimiter(
                  child: RefreshIndicator(
                    onRefresh: _loadDocuments,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      controller: _scrollController,
                      itemCount: _filteredDocuments.length + 1,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemBuilder: (context, index) {
                        if (index == _filteredDocuments.length) {
                          return _isLoadingMore
                              ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                  ),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                              : SizedBox(
                                height:
                                    _filteredDocuments.isEmpty
                                        ? MediaQuery.of(context).size.height *
                                            0.6
                                        : 40,
                              );
                        }

                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildDocumentCard(
                                _filteredDocuments[index],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomSheet: null,
    );
  }
}
