import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/services/excel_export_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/utils/navigation_helper.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _selectedExportFormat = 'csv';
  String _selectedDateRange = 'all'; // 'all', 'today', 'week', 'month', 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _downloadReport(String content, String format) async {
    try {
      final filename = ExcelExportService.generateFilename(format);
      
      // Try to save file to Downloads folder
      String? filePath;
      String? saveLocation;
      
      try {
        if (Platform.isWindows) {
          // Windows: Save to Downloads folder
          final downloadsPath = Platform.environment['USERPROFILE'];
          if (downloadsPath != null) {
            final downloadsDir = Directory('$downloadsPath\\Downloads');
            if (!await downloadsDir.exists()) {
              await downloadsDir.create(recursive: true);
            }
            if (await downloadsDir.exists()) {
              final file = File('${downloadsDir.path}\\$filename');
              await file.writeAsString(content);
              filePath = file.path;
              saveLocation = 'Downloads folder';
            }
          }
        } else if (Platform.isLinux) {
          // Linux: Save to Downloads folder
          final downloadsPath = Platform.environment['HOME'];
          if (downloadsPath != null) {
            final downloadsDir = Directory('$downloadsPath/Downloads');
            if (!await downloadsDir.exists()) {
              await downloadsDir.create(recursive: true);
            }
            if (await downloadsDir.exists()) {
              final file = File('${downloadsDir.path}/$filename');
              await file.writeAsString(content);
              filePath = file.path;
              saveLocation = 'Downloads folder';
            }
          }
        } else if (Platform.isMacOS) {
          // macOS: Save to Downloads folder
          final downloadsPath = Platform.environment['HOME'];
          if (downloadsPath != null) {
            final downloadsDir = Directory('$downloadsPath/Downloads');
            if (!await downloadsDir.exists()) {
              await downloadsDir.create(recursive: true);
            }
            if (await downloadsDir.exists()) {
              final file = File('${downloadsDir.path}/$filename');
              await file.writeAsString(content);
              filePath = file.path;
              saveLocation = 'Downloads folder';
            }
          }
        } else {
          // Mobile/Other: Use path_provider
          try {
            final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
            final file = File('${directory.path}/$filename');
            await file.writeAsString(content);
            filePath = file.path;
            saveLocation = 'Downloads folder';
          } catch (e) {
            print('⚠️ Could not get downloads directory: $e');
          }
        }
      } catch (e) {
        print('⚠️ Error saving file: $e');
        // Fallback: Show in dialog
      }

      if (filePath != null && saveLocation != null) {
        // File saved successfully
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ Report saved successfully!'),
                  const SizedBox(height: 4),
                  Text(
                    'Location: $saveLocation',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'File: $filename',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Open Folder',
                textColor: Colors.white,
                onPressed: () {
                  // Try to open the folder
                  if (Platform.isWindows) {
                    Process.run('explorer', [filePath!.substring(0, filePath.lastIndexOf('\\'))]);
                  } else if (Platform.isLinux) {
                    Process.run('xdg-open', [filePath!.substring(0, filePath.lastIndexOf('/'))]);
                  } else if (Platform.isMacOS) {
                    Process.run('open', [filePath!.substring(0, filePath.lastIndexOf('/'))]);
                  }
                },
              ),
            ),
          );
        }
      } else {
        // Fallback: Show in dialog if file saving failed
        _showReportDialog(content, filename, format);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Report generated: $filename\n(Copied to clipboard - use Copy button to save)'),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  void _showReportDialog(String content, String filename, String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📥 Report: $filename'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(content),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Copy to clipboard
              await Future.microtask(() async {
                await Clipboard.setData(ClipboardData(text: content));
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Report copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text(
              '📋 Copy',
              style: TextStyle(inherit: false),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(inherit: false),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? EcoGradients.backgroundGradient
              : EcoGradients.lightBackgroundGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRealAnalytics(),
                          const SizedBox(height: 32),
                          _buildDownloadSection(),
                          const SizedBox(height: 32),
                          _buildTasksTable(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.neonPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDark ? EcoShadows.neon : EcoShadows.light,
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark
                            ? AppTheme.textGray
                            : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                ),
                Text(
                  'Real-time insights and performance metrics',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => NavigationHelper.navigateToDashboard(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildRealAnalytics() {
    final isDark = ref.watch(isDarkModeProvider);
    final statsAsync = ref.watch(analyticsStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Performance Indicators',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
        ),
        const SizedBox(height: 16),
        statsAsync.when(
          data: (stats) => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildKPICard(
                      title: 'Total Tasks',
                      value: stats['total_tasks'].toString(),
                      change: '📊',
                      icon: Icons.assignment,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKPICard(
                      title: 'Completion Rate',
                      value: '${stats['completion_rate']}%',
                      change: '✅',
                      icon: Icons.trending_up,
                      color: AppTheme.successGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildKPICard(
                      title: 'Completed',
                      value: stats['completed_tasks'].toString(),
                      change: '✓',
                      icon: Icons.check_circle,
                      color: AppTheme.successGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKPICard(
                      title: 'Pending',
                      value: stats['pending_tasks'].toString(),
                      change: '⏳',
                      icon: Icons.hourglass_empty,
                      color: AppTheme.warningOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildKPICard(
                      title: 'In Progress',
                      value: stats['in_progress_tasks'].toString(),
                      change: '▶',
                      icon: Icons.play_circle,
                      color: AppTheme.secondaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKPICard(
                      title: 'High Priority',
                      value: stats['high_priority_tasks'].toString(),
                      change: '⚠️',
                      icon: Icons.warning,
                      color: AppTheme.dangerRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Center(
            child: Text('Error loading stats: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required Color color,
  }) {
    final isDark = ref.watch(isDarkModeProvider);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: isDark
                  ? EcoGradients.glassGradient
                  : EcoGradients.lightGlassGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    Text(
                      change,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: isDark
                            ? AppTheme.textGray
                            : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadSection() {
    final isDark = ref.watch(isDarkModeProvider);

    // Get date range based on selection
    final dateRange = _getDateRange();
    final reportAsync = dateRange != null
        ? ref.watch(tasksReportByDateRangeProvider(
            (startDate: dateRange.startDate, endDate: dateRange.endDate),
          ))
        : ref.watch(allTasksReportProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📥 Download Report',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          // Date Range Selection
          Text(
            'Date Range',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _selectedDateRange,
            isExpanded: true,
            dropdownColor: isDark ? AppTheme.darkGray : Colors.white,
            items: const [
              DropdownMenuItem(
                value: 'all',
                child: Text('📅 All Time'),
              ),
              DropdownMenuItem(
                value: 'today',
                child: Text('📅 Today'),
              ),
              DropdownMenuItem(
                value: 'week',
                child: Text('📅 This Week'),
              ),
              DropdownMenuItem(
                value: 'month',
                child: Text('📅 This Month'),
              ),
              DropdownMenuItem(
                value: 'custom',
                child: Text('📅 Custom Range'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedDateRange = value);
                if (value == 'custom' && _customStartDate == null) {
                  _selectCustomDateRange();
                }
              }
            },
          ),
          
          // Custom Date Range Pickers
          if (_selectedDateRange == 'custom') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartDate(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkGray
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _customStartDate != null
                                ? '${_customStartDate!.day}/${_customStartDate!.month}/${_customStartDate!.year}'
                                : 'Select Start Date',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.textGray
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndDate(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkGray
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _customEndDate != null
                                ? '${_customEndDate!.day}/${_customEndDate!.month}/${_customEndDate!.year}'
                                : 'Select End Date',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.textGray
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Export Format Selection
          Text(
            'Export Format',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedExportFormat,
                  isExpanded: true,
                  dropdownColor: isDark ? AppTheme.darkGray : Colors.white,
                  items: const [
                    DropdownMenuItem(
                      value: 'csv',
                      child: Text('📊 CSV (Excel)'),
                    ),
                    DropdownMenuItem(
                      value: 'html',
                      child: Text('🌐 HTML (Web)'),
                    ),
                    DropdownMenuItem(
                      value: 'json',
                      child: Text('🔗 JSON (API)'),
                    ),
                    DropdownMenuItem(
                      value: 'tsv',
                      child: Text('📈 TSV (Data)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedExportFormat = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  if (_selectedDateRange == 'custom' &&
                      (_customStartDate == null || _customEndDate == null)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select both start and end dates'),
                        backgroundColor: AppTheme.warningOrange,
                      ),
                    );
                    return;
                  }

                  // Show confirmation dialog before downloading
                  _showDownloadConfirmation(reportAsync);
                },
                icon: const Icon(Icons.download),
                label: const Text(
                  'Download',
                  style: TextStyle(
                    inherit: false,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ({DateTime startDate, DateTime endDate})? _getDateRange() {
    final now = DateTime.now();
    
    switch (_selectedDateRange) {
      case 'today':
        final today = DateTime(now.year, now.month, now.day);
        return (startDate: today, endDate: now);
      
      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        return (startDate: weekStartDate, endDate: now);
      
      case 'month':
        final monthStart = DateTime(now.year, now.month, 1);
        return (startDate: monthStart, endDate: now);
      
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          final start = DateTime(
            _customStartDate!.year,
            _customStartDate!.month,
            _customStartDate!.day,
          );
          final end = DateTime(
            _customEndDate!.year,
            _customEndDate!.month,
            _customEndDate!.day,
            23,
            59,
            59,
          );
          return (startDate: start, endDate: end);
        }
        return null;
      
      case 'all':
      default:
        return null;
    }
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 365 * 2)); // 2 years ago
    final lastDate = now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 365 * 2));
    final lastDate = _customEndDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: _customStartDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked;
        if (_customEndDate != null && _customEndDate!.isBefore(picked)) {
          _customEndDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_customStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start date first'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: _customEndDate ?? _customStartDate!,
      firstDate: _customStartDate!,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        _customEndDate = picked;
      });
    }
  }

  void _showDownloadConfirmation(AsyncValue<List<TaskReport>> reportAsync) {
    final isDark = ref.read(isDarkModeProvider);
    final dateRangeText = _getDateRangeText();
    final formatText = _getFormatText(_selectedExportFormat);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkGray : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.download,
              color: AppTheme.primaryGreen,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Confirm Download'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Download Report Details:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildConfirmationRow('Date Range:', dateRangeText, isDark),
            const SizedBox(height: 8),
            _buildConfirmationRow('Format:', formatText, isDark),
            const SizedBox(height: 8),
            reportAsync.when(
              data: (reports) => _buildConfirmationRow(
                'Records:',
                '${reports.length} tasks',
                isDark,
              ),
              loading: () => _buildConfirmationRow(
                'Records:',
                'Loading...',
                isDark,
              ),
              error: (_, __) => _buildConfirmationRow(
                'Records:',
                'Error loading',
                isDark,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'File will be saved to your Downloads folder',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppTheme.textSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              // Proceed with download
              reportAsync.when(
                data: (reports) {
                  String content;
                  switch (_selectedExportFormat) {
                    case 'csv':
                      content =
                          ExcelExportService.generateTaskReportCSV(reports);
                      break;
                    case 'html':
                      content =
                          ExcelExportService.generateTaskReportHTML(reports);
                      break;
                    case 'json':
                      content =
                          ExcelExportService.generateTaskReportJSON(reports);
                      break;
                    case 'tsv':
                      content =
                          ExcelExportService.generateTaskReportTSV(reports);
                      break;
                    default:
                      content =
                          ExcelExportService.generateTaskReportCSV(reports);
                  }
                  _downloadReport(content, _selectedExportFormat);
                },
                loading: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Loading data...')),
                  );
                },
                error: (error, _) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $error')),
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: isDark
                  ? AppTheme.textSecondary
                  : AppTheme.lightTextSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _getDateRangeText() {
    switch (_selectedDateRange) {
      case 'today':
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          return '${_customStartDate!.day}/${_customStartDate!.month}/${_customStartDate!.year} - ${_customEndDate!.day}/${_customEndDate!.month}/${_customEndDate!.year}';
        }
        return 'Custom (Select Dates)';
      case 'all':
      default:
        return 'All Time';
    }
  }

  String _getFormatText(String format) {
    switch (format) {
      case 'csv':
        return 'CSV (Excel)';
      case 'html':
        return 'HTML (Web)';
      case 'json':
        return 'JSON (API)';
      case 'tsv':
        return 'TSV (Data)';
      default:
        return format.toUpperCase();
    }
  }

  Widget _buildTasksTable() {
    final isDark = ref.watch(isDarkModeProvider);
    final reportAsync = ref.watch(allTasksReportProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Reports',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          reportAsync.when(
            data: (reports) {
              if (reports.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No tasks found',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Bin')),
                    DataColumn(label: Text('Floor')),
                    DataColumn(label: Text('Priority')),
                    DataColumn(label: Text('Assigned To')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('Days')),
                    DataColumn(label: Text('Completed')),
                  ],
                  rows: reports.take(10).map((report) {
                    return DataRow(
                      cells: [
                        DataCell(Text(report.trashcanName)),
                        DataCell(Text(report.floor ?? 'N/A')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: report.priority == 'urgent'
                                  ? AppTheme.dangerRed.withOpacity(0.2)
                                  : report.priority == 'high'
                                      ? AppTheme.warningOrange.withOpacity(0.2)
                                      : AppTheme.primaryGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              report.priority,
                              style: TextStyle(
                                color: report.priority == 'urgent'
                                    ? AppTheme.dangerRed
                                    : report.priority == 'high'
                                        ? AppTheme.warningOrange
                                        : AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(report.assignedStaffName ?? 'Unassigned')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: report.status == 'completed'
                                  ? AppTheme.successGreen.withOpacity(0.2)
                                  : AppTheme.secondaryBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              report.status,
                              style: TextStyle(
                                color: report.status == 'completed'
                                    ? AppTheme.successGreen
                                    : AppTheme.secondaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            report.status == 'completed' && report.completedAt != null
                                ? report.formattedTime
                                : 'N/A',
                          ),
                        ),
                        DataCell(
                          Text(
                            report.status == 'completed' && report.daysSinceCompletion != null
                                ? '${report.daysSinceCompletion} days'
                                : 'N/A',
                          ),
                        ),
                        DataCell(
                          Text(
                            report.completedAt != null
                                ? report.completedAt!
                                    .toString()
                                    .split(' ')[0] // Just the date
                                : 'Pending',
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.dangerRed,
                  ),
                  const SizedBox(height: 16),
                  Text('Error loading reports: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(allTasksReportProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        inherit: false,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
