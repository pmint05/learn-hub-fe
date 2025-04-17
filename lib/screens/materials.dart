import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:learn_hub/screens/ask.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

enum SortOption { nameAsc, nameDesc, dateAsc, dateDesc, sizeAsc, sizeDesc }

enum FilterFileType { pdf, doc, docx, md, txt, all, custom }

class MaterialDocument {
  final String id;
  final String name;
  final String path;
  final String extension;
  final int size; // in bytes
  final DateTime dateAdded;
  final DateTime? lastModified;

  MaterialDocument({
    required this.id,
    required this.name,
    required this.path,
    required this.extension,
    required this.size,
    required this.dateAdded,
    this.lastModified,
  });
}

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  bool _isLoading = true;
  bool _isMultiSelectMode = false;
  final Set<String> _selectedDocuments = {};
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _renameController = TextEditingController();

  SortOption _currentSortOption = SortOption.dateDesc;
  FilterFileType _currentFilterFileType = FilterFileType.all;
  String _searchQuery = '';

  List<MaterialDocument> _documents = [];
  List<MaterialDocument> _filteredDocuments = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadDocuments();
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
        _applyFilters();
      });
    });
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    // Simulating loading documents
    await Future.delayed(const Duration(seconds: 1));

    // Replace this with your actual document loading logic
    _documents = List.generate(
      20,
      (index) => MaterialDocument(
        id: 'doc-$index',
        name: 'Document ${index + 1}',
        path: '/path/to/document${index + 1}',
        extension: _getRandomExtension(),
        size: 1000000 + (index * 500000),
        dateAdded: DateTime.now().subtract(Duration(days: index)),
        lastModified:
            index % 2 == 0
                ? DateTime.now().subtract(Duration(hours: index * 5))
                : null,
      ),
    );

    _applyFilters();
    setState(() {
      _isLoading = false;
    });
  }

  String _getRandomExtension() {
    final extensions = ['pdf', 'doc', 'docx', 'md', 'txt'];
    return extensions[_documents.length % extensions.length];
  }

  void _applyFilters() {
    // Filter by search query
    var filtered =
        _documents
            .where(
              (doc) =>
                  doc.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

    // Filter by file type
    if (_currentFilterFileType != FilterFileType.all) {
      filtered =
          filtered
              .where(
                (doc) =>
                    doc.extension.toLowerCase() ==
                    _currentFilterFileType.name.toLowerCase(),
              )
              .toList();
    }

    // Sort documents
    switch (_currentSortOption) {
      case SortOption.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
      case SortOption.nameDesc:
        filtered.sort((a, b) => b.name.compareTo(a.name));
      case SortOption.dateAsc:
        filtered.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
      case SortOption.dateDesc:
        filtered.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      case SortOption.sizeAsc:
        filtered.sort((a, b) => a.size.compareTo(b.size));
      case SortOption.sizeDesc:
        filtered.sort((a, b) => b.size.compareTo(a.size));
    }

    setState(() {
      _filteredDocuments = filtered;
    });
  }

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'md', 'txt'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      // Simulate upload process
      await Future.delayed(const Duration(seconds: 2));

      // Add new documents
      final newDocs =
          result.files
              .map(
                (file) => MaterialDocument(
                  id: 'doc-${_documents.length + 1}',
                  name: file.name,
                  path: file.path ?? '',
                  extension: file.extension ?? '',
                  size: file.size,
                  dateAdded: DateTime.now(),
                ),
              )
              .toList();

      setState(() {
        _documents.addAll(newDocs);
        _applyFilters();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.files.length} file(s) uploaded successfully'),
        ),
      );
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
                        _buildFilterFileTypeChip(
                          FilterFileType.all,
                          'All',
                          setModalState,
                        ),
                        _buildFilterFileTypeChip(
                          FilterFileType.pdf,
                          'PDF',
                          setModalState,
                        ),
                        _buildFilterFileTypeChip(
                          FilterFileType.doc,
                          'DOC',
                          setModalState,
                        ),
                        _buildFilterFileTypeChip(
                          FilterFileType.docx,
                          'DOCX',
                          setModalState,
                        ),
                        _buildFilterFileTypeChip(
                          FilterFileType.md,
                          'MD',
                          setModalState,
                        ),
                        _buildFilterFileTypeChip(
                          FilterFileType.txt,
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
    );
  }

  Widget _buildFilterFileTypeChip(
    FilterFileType type,
    String label,
    StateSetter setModalState,
  ) {
    final isSelected = _currentFilterFileType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          _currentFilterFileType = type;
        });
      },
    );
  }

  void _showDocumentOptions(MaterialDocument doc) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(PhosphorIconsRegular.chatDots, color: cs.primary),
                title: Text('Send to Chat'),
                onTap: () {
                  Navigator.pop(context);
                  if (context.mounted) {
                    context.go("/chat?materialIds=${doc.id}");
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

  void _deleteDocuments(List<String> docIds) {
    setState(() {
      _documents.removeWhere((doc) => docIds.contains(doc.id));
      _selectedDocuments.removeAll(docIds);
      _applyFilters();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          docIds.length > 1
              ? '${docIds.length} documents deleted'
              : 'Document deleted',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Implement undo functionality
          },
        ),
      ),
    );
  }

  Widget _buildDocumentCard(MaterialDocument doc) {
    final cs = Theme.of(context).colorScheme;
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
        borderRadius: BorderRadius.circular(8),
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
                  borderRadius: BorderRadius.circular(8),
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
    final cs = Theme.of(context).colorScheme;

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
                                  icon: Icon(PhosphorIconsRegular.chatDots),
                                  onPressed: () {
                                    // Send to chat
                                  },
                                ),
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
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_filteredDocuments.isEmpty)
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
              child: AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: _filteredDocuments.length,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildDocumentCard(_filteredDocuments[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      bottomSheet: null,
    );
  }
}
