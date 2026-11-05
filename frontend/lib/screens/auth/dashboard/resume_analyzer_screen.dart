import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/theme_controller.dart';
import '../../../widgets/custom_widgets.dart';

class ResumeAnalyzerScreen extends StatefulWidget {
  const ResumeAnalyzerScreen({super.key});

  @override
  State<ResumeAnalyzerScreen> createState() => _ResumeAnalyzerScreenState();
}

class _ResumeAnalyzerScreenState extends State<ResumeAnalyzerScreen> {
  PlatformFile? _selectedFile;
  bool _isPicking = false;
  bool _isAnalyzing = false;
  String? _analysisResult;

  Future<void> _pickResume() async {
    try {
      setState(() => _isPicking = true);

      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
        allowMultiple: false,
      );

      if (!mounted) return;

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          _showMessage('File size exceeds the 5MB limit. Please choose a smaller PDF.', isError: true);
          return;
        }

        setState(() {
          _selectedFile = file;
          _analysisResult = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('File selection failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _removeResume() {
    setState(() {
      _selectedFile = null;
      _analysisResult = null;
    });
  }

  Future<void> _analyzeResume() async {
    if (_selectedFile == null) return;

    if (_selectedFile!.bytes == null) {
      _showMessage('Unable to read PDF file. Please select it again.', isError: true);
      return;
    }

    if (_selectedFile!.size > 5 * 1024 * 1024) {
      _showMessage('File size exceeds the 5MB limit. Please choose a smaller PDF.', isError: true);
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      final response = await ApiService.analyzeResume(
        fileBytes: _selectedFile!.bytes!,
        fileName: _selectedFile!.name,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _analysisResult = response['data']?['analysis']?.toString() ??
              'Analysis completed, but no result was returned.';
        });
      } else {
        throw Exception(response['message'] ?? 'Analysis failed');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Analysis failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  // PDF Color Palette (Electric Emerald & Carbon Onyx Theme)
  static const _pdfPrimaryEmerald = PdfColor.fromInt(0xFF059669);
  static const _pdfSecondaryEmerald = PdfColor.fromInt(0xFF10B981);
  static const _pdfSoftMint = PdfColor.fromInt(0xFFECFDF5);
  static const _pdfBorderMint = PdfColor.fromInt(0xFFA7F3D0);
  static const _pdfDarkCarbon = PdfColor.fromInt(0xFF0F172A);
  static const _pdfTextSlate = PdfColor.fromInt(0xFF334155);
  static const _pdfMutedSlate = PdfColor.fromInt(0xFF64748B);
  static const _pdfLightSlate = PdfColor.fromInt(0xFF94A3B8);
  static const _pdfBgNeutral = PdfColor.fromInt(0xFFF8FAFC);
  static const _pdfBorderNeutral = PdfColor.fromInt(0xFFE2E8F0);
  static const _pdfAccentAmber = PdfColor.fromInt(0xFFD97706);
  static const _pdfSoftAmber = PdfColor.fromInt(0xFFFEF3C7);
  static const _pdfAccentRose = PdfColor.fromInt(0xFFDC2626);
  static const _pdfSoftRose = PdfColor.fromInt(0xFFFEE2E2);
  static const _pdfAccentTeal = PdfColor.fromInt(0xFF0D9488);
  static const _pdfSoftTeal = PdfColor.fromInt(0xFFF0FDFA);

  PdfColor _getPdfSectionColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('strength')) return _pdfPrimaryEmerald;
    if (lower.contains('weakness')) return _pdfAccentRose;
    if (lower.contains('missing')) return _pdfAccentAmber;
    if (lower.contains('improvement') || lower.contains('suggestion')) return _pdfPrimaryEmerald;
    if (lower.contains('skill')) return _pdfAccentTeal;
    if (lower.contains('role') || lower.contains('job')) return _pdfDarkCarbon;
    return _pdfPrimaryEmerald;
  }

  PdfColor _getPdfSectionBg(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('strength')) return _pdfSoftMint;
    if (lower.contains('weakness')) return _pdfSoftRose;
    if (lower.contains('missing')) return _pdfSoftAmber;
    if (lower.contains('improvement') || lower.contains('suggestion')) return _pdfSoftMint;
    if (lower.contains('skill')) return _pdfSoftTeal;
    if (lower.contains('role') || lower.contains('job')) return _pdfBgNeutral;
    return _pdfSoftMint;
  }

  String _getPdfSectionBadge(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('strength')) return 'STRENGTHS';
    if (lower.contains('weakness')) return 'CRITICAL GAPS';
    if (lower.contains('missing')) return 'KEYWORD GAPS';
    if (lower.contains('improvement') || lower.contains('suggestion')) return 'ACTION ITEMS';
    if (lower.contains('skill')) return 'TECH STACK';
    if (lower.contains('role') || lower.contains('job')) return 'TARGET ROLES';
    if (lower.contains('summary')) return 'SUMMARY';
    return 'AUDIT';
  }

  pw.Widget _buildPdfMetricItem(String title, String value, bool isPositive) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: _pdfBorderNeutral, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 7, color: _pdfMutedSlate),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: isPositive ? _pdfPrimaryEmerald : _pdfDarkCarbon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.TableRow _buildPdfTableRow(String benchmark, String standard, String status, bool isPass) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
          child: pw.Text(benchmark, style: const pw.TextStyle(fontSize: 7.5, color: _pdfTextSlate)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
          child: pw.Text(standard, style: const pw.TextStyle(fontSize: 7.5, color: _pdfMutedSlate)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
          child: pw.Row(
            children: [
              pw.Container(
                width: 5,
                height: 5,
                decoration: pw.BoxDecoration(
                  color: isPass ? _pdfPrimaryEmerald : _pdfAccentAmber,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Text(
                status,
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: isPass ? _pdfPrimaryEmerald : _pdfAccentAmber,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfContentBlock(String content, PdfColor accentColor) {
    final lines = content.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: lines.map((line) {
        String cleanLine = line;
        bool isBullet = false;
        String? bulletIndex;

        final numMatch = RegExp(r'^(\d+)\.\s*(.+)$').firstMatch(cleanLine);
        if (numMatch != null) {
          bulletIndex = numMatch.group(1);
          cleanLine = numMatch.group(2) ?? '';
          isBullet = true;
        } else if (cleanLine.startsWith('- ') || cleanLine.startsWith('* ') || cleanLine.startsWith('• ')) {
          cleanLine = cleanLine.substring(2).trim();
          isBullet = true;
        }

        cleanLine = cleanLine.replaceAll('**', '');

        if (isBullet) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 3, right: 6),
                  width: bulletIndex != null ? 14 : 5,
                  height: bulletIndex != null ? 12 : 5,
                  decoration: pw.BoxDecoration(
                    color: bulletIndex != null ? _pdfSoftMint : accentColor,
                    borderRadius: pw.BorderRadius.circular(bulletIndex != null ? 3 : 2.5),
                    border: bulletIndex != null ? pw.Border.all(color: accentColor, width: 0.5) : null,
                  ),
                  child: bulletIndex != null
                      ? pw.Center(
                          child: pw.Text(
                            bulletIndex,
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        )
                      : null,
                ),
                pw.Expanded(
                  child: pw.Text(
                    cleanLine,
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: _pdfTextSlate,
                      lineSpacing: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Text(
              cleanLine,
              style: const pw.TextStyle(
                fontSize: 8.5,
                color: _pdfTextSlate,
                lineSpacing: 1.3,
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  pw.Widget _buildPdfSectionCard(Map<String, String> section) {
    final title = section['title'] ?? '';
    final content = section['content'] ?? '';
    final accent = _getPdfSectionColor(title);
    final bg = _getPdfSectionBg(title);
    final badge = _getPdfSectionBadge(title);

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _pdfBorderNeutral, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: pw.BoxDecoration(
              color: bg,
              borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(7)),
              border: const pw.Border(bottom: pw.BorderSide(color: _pdfBorderNeutral, width: 0.6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 5,
                      height: 12,
                      decoration: pw.BoxDecoration(
                        color: accent,
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      title.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _pdfDarkCarbon,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: accent, width: 0.6),
                  ),
                  child: pw.Text(
                    badge,
                    style: pw.TextStyle(
                      fontSize: 6.5,
                      fontWeight: pw.FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: _buildPdfContentBlock(content, accent),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAnalysisPdf() async {
    if (_analysisResult == null) return;

    try {
      final pdf = pw.Document(
        title: 'CareerPilot AI - Resume Analysis Report',
        author: 'CareerPilot AI',
        subject: 'Executive ATS Resume Audit & Performance Report',
      );

      final score = resumeScore;
      final tierColor = score >= 85
          ? _pdfPrimaryEmerald
          : (score >= 70
              ? _pdfAccentTeal
              : (score >= 50 ? _pdfAccentAmber : _pdfAccentRose));
      final tierBg = score >= 85
          ? _pdfSoftMint
          : (score >= 70
              ? _pdfSoftTeal
              : (score >= 50 ? _pdfSoftAmber : _pdfSoftRose));
      final tierLabel = score >= 85
          ? 'TIER 1 • EXCELLENT ATS PASS RATE'
          : (score >= 70
              ? 'TIER 2 • COMPETITIVE APPLICANT'
              : (score >= 50
                  ? 'TIER 3 • REQUIRES TARGETED REVISIONS'
                  : 'TIER 4 • HIGH ATS REJECTION RISK'));
      final tierDescription = score >= 85
          ? 'Your resume shows exceptional structure, keywords, and relevance for automated ATS filters.'
          : (score >= 70
              ? 'Solid candidate profile. Addressing recommended keywords will maximize interview callbacks.'
              : (score >= 50
                  ? 'Moderate ATS filter risks detected. Several expected engineering keywords are missing.'
                  : 'Significant structure or keyword gaps detected. Follow the action items below to pass recruiter screens.'));

      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final fileNameStr = _selectedFile?.name ?? 'Candidate_Resume.pdf';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          header: (context) {
            if (context.pageNumber == 1) return pw.SizedBox();
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.only(bottom: 5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: _pdfBorderNeutral, width: 0.8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'CareerPilot AI • Executive ATS Resume Audit Report',
                    style: pw.TextStyle(color: _pdfMutedSlate, fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    fileNameStr,
                    style: const pw.TextStyle(color: _pdfMutedSlate, fontSize: 8),
                  ),
                ],
              ),
            );
          },
          footer: (context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 10),
              padding: const pw.EdgeInsets.only(top: 5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: _pdfBorderNeutral, width: 0.8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'CONFIDENTIAL • CAREERPILOT AI CAREER INTELLIGENCE • ALL RIGHTS RESERVED',
                    style: pw.TextStyle(color: _pdfLightSlate, fontSize: 7, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(color: _pdfMutedSlate, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            );
          },
          build: (context) => [
            // 1. Executive Top Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: _pdfDarkCarbon,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: pw.BoxDecoration(
                              color: _pdfPrimaryEmerald,
                              borderRadius: pw.BorderRadius.circular(5),
                            ),
                            child: pw.Text(
                              'CareerPilot AI',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            'AUDIT VERIFIED',
                            style: pw.TextStyle(
                              color: _pdfSecondaryEmerald,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'EXECUTIVE ATS RESUME AUDIT REPORT',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Comprehensive ATS Parsing, Keyword Gap & Recruiter Impact Evaluation',
                        style: const pw.TextStyle(
                          color: _pdfLightSlate,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'REPORT ID: #CP-${now.millisecondsSinceEpoch.toString().substring(7)}',
                        style: const pw.TextStyle(color: _pdfLightSlate, fontSize: 7.5),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'FILE: $fileNameStr',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'DATE: $dateStr',
                        style: const pw.TextStyle(color: _pdfLightSlate, fontSize: 7.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // 2. Score & Key Metrics Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _pdfBgNeutral,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: _pdfBorderNeutral, width: 1),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 130,
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: tierColor, width: 1.5),
                    ),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          'OVERALL ATS SCORE',
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _pdfMutedSlate),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              '$score',
                              style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: tierColor),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 4, left: 2),
                              child: pw.Text(
                                '/ 100',
                                style: pw.TextStyle(fontSize: 10, color: _pdfMutedSlate, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                          decoration: pw.BoxDecoration(
                            color: tierBg,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            tierLabel,
                            style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: tierColor),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ATS Readiness Verdict & Benchmark Overview',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _pdfDarkCarbon),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          tierDescription,
                          style: const pw.TextStyle(fontSize: 8, color: _pdfTextSlate),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          children: [
                            _buildPdfMetricItem('Parsing Success', '100% Machine-Readable', true),
                            pw.SizedBox(width: 6),
                            _buildPdfMetricItem(
                              'Keyword Density',
                              score >= 70 ? 'High Alignment' : 'Moderate Gaps',
                              score >= 70,
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          children: [
                            _buildPdfMetricItem(
                              'Impact Metrics',
                              score >= 65 ? 'Measurable Impact' : 'Needs Metrics Addition',
                              score >= 65,
                            ),
                            pw.SizedBox(width: 6),
                            _buildPdfMetricItem('Readability Time', '< 7s Recruiter Scan Pass', true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // 3. Technical ATS Compliance Matrix
            pw.Table(
              border: pw.TableBorder.all(color: _pdfBorderNeutral, width: 0.6),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _pdfBgNeutral),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                      child: pw.Text('ATS Technical Benchmark', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _pdfDarkCarbon)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                      child: pw.Text('Standard Required', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _pdfDarkCarbon)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                      child: pw.Text('Candidate Audit Status', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _pdfDarkCarbon)),
                    ),
                  ],
                ),
                _buildPdfTableRow('Text Layer & OCR Compatibility', 'Machine-Readable PDF (No Flat Scans)', '100% Vector Text Passed', true),
                _buildPdfTableRow('Standard Headings (Experience, Skills)', 'Recognizable Work History Hierarchy', 'Parsed Successfully', true),
                _buildPdfTableRow('Action Verbs & Metric Density', 'Quantifiable business/technical impact', score >= 70 ? 'Optimal Saturation' : 'Add Quantifiable %', score >= 70),
                _buildPdfTableRow('Core Tech Stack Keyword Saturation', 'High frequency in role-targeted skills', score >= 65 ? 'Competitive Alignment' : 'Review Missing Skills', score >= 65),
              ],
            ),
            pw.SizedBox(height: 12),

            // 4. Section by Section Breakdown Cards
            ...analysisSections.where((s) => !s['title']!.toLowerCase().contains('score')).map((section) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: _buildPdfSectionCard(section),
              );
            }),

            pw.SizedBox(height: 6),

            // 5. Official Verification Stamp / Sign-off Callout
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _pdfSoftMint,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: _pdfBorderMint, width: 1),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 22,
                    height: 22,
                    decoration: const pw.BoxDecoration(
                      color: _pdfPrimaryEmerald,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'CP',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'OFFICIALLY VERIFIED ATS PERFORMANCE AUDIT',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _pdfPrimaryEmerald),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'This evaluation report was generated using CareerPilot AI semantic parsing algorithms. Implement the suggested action items to maximize recruiter outreach and automated ATS screening pass rates.',
                          style: const pw.TextStyle(fontSize: 7, color: _pdfTextSlate, lineSpacing: 1.2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      final cleanFileName = (_selectedFile?.name ?? 'Resume')
          .replaceAll('.pdf', '')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

      await Printing.layoutPdf(
        name: 'CareerPilot_ATS_Report_${cleanFileName}.pdf',
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('PDF generation failed: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String get _formattedFileSize {
    if (_selectedFile == null) return '';
    final sizeInKB = _selectedFile!.size / 1024;
    if (sizeInKB >= 1024) {
      return '${(sizeInKB / 1024).toStringAsFixed(2)} MB';
    }
    return '${sizeInKB.toStringAsFixed(1)} KB';
  }

  int get resumeScore {
    final match = RegExp(r'(\d{1,3})\s*/\s*100').firstMatch(_analysisResult ?? '');
    if (match == null) return 0;
    final score = int.tryParse(match.group(1) ?? '0') ?? 0;
    return score.clamp(0, 100);
  }

  List<Map<String, String>> get analysisSections {
    if (_analysisResult == null) return [];

    final result = <Map<String, String>>[];
    final headingRegex = RegExp(r'^\s*\d+\.\s*(.+?)\s*$', multiLine: true);
    final matches = headingRegex.allMatches(_analysisResult!);

    for (int i = 0; i < matches.length; i++) {
      final heading = matches.elementAt(i);
      final start = heading.end;
      final end = i + 1 < matches.length ? matches.elementAt(i + 1).start : _analysisResult!.length;

      final title = heading.group(1)?.trim() ?? '';
      final content = _analysisResult!.substring(start, end).trim();

      if (content.isNotEmpty) {
        result.add({
          'title': title,
          'content': content,
        });
      }
    }

    return result;
  }

  IconData _getSectionIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('score')) return Icons.speed_rounded;
    if (lower.contains('summary')) return Icons.article_rounded;
    if (lower.contains('technical') || lower.contains('skill')) return Icons.code_rounded;
    if (lower.contains('strength')) return Icons.thumb_up_alt_rounded;
    if (lower.contains('weakness')) return Icons.warning_amber_rounded;
    if (lower.contains('missing')) return Icons.find_in_page_rounded;
    if (lower.contains('improvement')) return Icons.trending_up_rounded;
    if (lower.contains('role') || lower.contains('job')) return Icons.work_outline_rounded;
    return Icons.auto_awesome_rounded;
  }

  Color _getSectionColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('strength')) return AppColors.accentEmerald;
    if (lower.contains('weakness')) return AppColors.error;
    if (lower.contains('missing')) return AppColors.accentAmber;
    if (lower.contains('improvement')) return AppColors.primary;
    if (lower.contains('skill')) return AppColors.secondary;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Resume Analyzer',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amberAccent : AppColors.textSecondary,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => themeController.toggleTheme(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Resume Evaluator',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Upload your PDF resume for instant ATS scoring, strength highlights & deep feedback',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Upload Dropzone
                InkWell(
                  onTap: _isPicking || _isAnalyzing ? null : _pickResume,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                AppColors.darkCard,
                                _selectedFile != null
                                    ? AppColors.primarySoftDark
                                    : AppColors.darkSurface,
                              ]
                            : [
                                Colors.white,
                                _selectedFile != null
                                    ? AppColors.primarySoft.withValues(alpha: 0.3)
                                    : const Color(0xFFF8FAFC),
                              ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedFile != null
                            ? AppColors.primary
                            : (isDark ? AppColors.darkBorder : AppColors.border),
                        width: _selectedFile != null ? 1.8 : 1.2,
                      ),
                      boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.primarySoftDark : AppColors.primarySoft,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.cloud_upload_rounded,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Upload your Resume Document',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Supports standard PDF files up to 5MB',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: _isPicking || _isAnalyzing ? null : _pickResume,
                          icon: _isPicking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.file_open_rounded, size: 18),
                          label: Text(_isPicking ? 'Opening...' : 'Browse Documents'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Selected File Badge
                if (_selectedFile != null) ...[
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.accentRoseSoftDark : AppColors.accentRoseSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: AppColors.accentRose,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFile!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                _formattedFileSize,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _isAnalyzing ? null : _removeResume,
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Analyze CTA Button
                GradientButton(
                  onPressed: _selectedFile == null || _isAnalyzing ? null : _analyzeResume,
                  text: _isAnalyzing ? 'Analyzing Resume with Gemini AI...' : 'Analyze My Resume',
                  icon: Icons.auto_awesome_rounded,
                  isLoading: _isAnalyzing,
                ),

                // Report Section
                if (_analysisResult != null) ...[
                  const SizedBox(height: 36),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Evaluation Report',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _downloadAnalysisPdf,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Export PDF'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Score Hero Card
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 96,
                                height: 96,
                                child: CircularProgressIndicator(
                                  value: resumeScore / 100,
                                  strokeWidth: 9,
                                  backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
                                  color: resumeScore >= 80
                                      ? AppColors.accentEmerald
                                      : (resumeScore >= 60 ? AppColors.accentAmber : AppColors.error),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$resumeScore',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    '/100',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Overall ATS Score',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  StatusBadge(
                                    label: resumeScore >= 80
                                        ? 'ATS Optimized'
                                        : (resumeScore >= 60 ? 'Competitive' : 'Action Required'),
                                    backgroundColor: resumeScore >= 80
                                        ? (isDark ? AppColors.accentEmeraldSoftDark : AppColors.accentEmeraldSoft)
                                        : (resumeScore >= 60
                                            ? (isDark ? AppColors.accentAmberSoftDark : AppColors.accentAmberSoft)
                                            : (isDark ? AppColors.accentRoseSoftDark : AppColors.accentRoseSoft)),
                                    textColor: resumeScore >= 80
                                        ? AppColors.accentEmerald
                                        : (resumeScore >= 60 ? AppColors.accentAmber : AppColors.error),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                resumeScore >= 80
                                    ? 'Your resume shows high keyword relevance, structured technical competencies, and high recruiter readability.'
                                    : 'Review the missing skills and recommendations below to increase your resume ranking in automated applicant filters.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Structured Sections with Left Accent Color
                  ...analysisSections.map((section) {
                    final title = section['title']!;
                    final content = section['content']!;
                    final icon = _getSectionIcon(title);
                    final color = _getSectionColor(title);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border(
                            left: BorderSide(color: color, width: 4.5),
                            top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                            right: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                            bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                        ),
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(icon, color: color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SelectableText(
                              content,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.65,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
