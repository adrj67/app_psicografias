import 'package:app_psicografias/widges/error_widget.dart';
import 'package:app_psicografias/widges/loading_widget.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/psicografia.dart';
import '../utils/constants.dart';

class DetalleScreen extends StatefulWidget {
  final int psicografiaId;
  
  const DetalleScreen({
    super.key,
    required this.psicografiaId,
  });

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Psicografia? _psicografia;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetalle();
  }

  Future<void> _loadDetalle() async {
    try {
      final data = await _dbHelper.getPsicografiaById(widget.psicografiaId);
      if (data != null) {
        setState(() {
          _psicografia = Psicografia.fromMap(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No se encontró la psicografía';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppConstants.errorLoadingMessage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.detalleTitle),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget();
    }
    
    if (_errorMessage != null) {
      return ErrorMessageWidget(message: _errorMessage!);
    }
    
    if (_psicografia == null) {
      return const Center(child: Text('No se encontró la psicografía'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIdBadge(),
          const SizedBox(height: 20),
          _buildSection('Mensaje', _psicografia!.mensaje, Colors.grey),
          if (_psicografia!.urlReferencia?.isNotEmpty ?? false) ...[
            const SizedBox(height: 20),
            _buildSection('Referencia', _psicografia!.urlReferencia!, Colors.blue, isLink: true),
          ],
          if (_psicografia!.notas?.isNotEmpty ?? false) ...[
            const SizedBox(height: 20),
            _buildSection('Notas', _psicografia!.notas!, Colors.amber),
          ],
        ],
      ),
    );
  }

  Widget _buildIdBadge() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'ID: ${_psicografia!.id}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, Color color, {bool isLink = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: isLink
              ? Row(
                  children: [
                    Icon(Icons.link, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        content,
                        style: TextStyle(color: color),
                      ),
                    ),
                  ],
                )
              : Text(
                  content,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
        ),
      ],
    );
  }
}