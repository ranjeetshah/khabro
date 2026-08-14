import 'package:flutter/material.dart';

import '../../advertisements/data/advertisement_model.dart';
import '../../advertisements/data/advertisement_service.dart';
import '../../auth/data/auth_exception.dart';

class ModeratorAdvertisementFormScreen extends StatefulWidget {
  const ModeratorAdvertisementFormScreen({
    super.key,
    required this.advertisementService,
    this.advertisementId,
  });

  final AdvertisementService advertisementService;
  final String? advertisementId;

  @override
  State<ModeratorAdvertisementFormScreen> createState() => _ModeratorAdvertisementFormScreenState();
}

class _ModeratorAdvertisementFormScreenState extends State<ModeratorAdvertisementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _advertiserController = TextEditingController();
  final _creativeController = TextEditingController();
  final _destinationController = TextEditingController();
  final _ctaController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  AdvertisementPlacement _placement = AdvertisementPlacement.feed;
  bool _isLoading = false;
  bool _isEdit = false;
  String? _errorMessage;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.advertisementId != null;
    if (_isEdit) {
      _loadExisting();
    } else {
      _ready = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _advertiserController.dispose();
    _creativeController.dispose();
    _destinationController.dispose();
    _ctaController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final ad = await widget.advertisementService.getModeratorAdvertisementDetail(
        widget.advertisementId!,
      );
      if (!mounted) return;
      _titleController.text = ad.title;
      _descriptionController.text = ad.description ?? '';
      _advertiserController.text = ad.advertiserName;
      _creativeController.text = ad.creativeUrl;
      _destinationController.text = ad.destinationUrl;
      _ctaController.text = ad.ctaLabel ?? '';
      _startController.text = _formatDateTime(ad.startAt);
      _endController.text = _formatDateTime(ad.endAt);
      _placement = ad.placement == AdvertisementPlacement.unknown
          ? AdvertisementPlacement.feed
          : ad.placement;
      setState(() {
        _isLoading = false;
        _ready = true;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
        _ready = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
        _ready = true;
      });
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}T${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _pickStart() async {
    final picked = await _pickDateTime(_startController.text);
    if (picked != null) {
      setState(() {
        _startController.text = picked;
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await _pickDateTime(_endController.text);
    if (picked != null) {
      setState(() {
        _endController.text = picked;
      });
    }
  }

  Future<String?> _pickDateTime(String current) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(current);
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return null;
    if (!mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? now),
    );
    if (time == null) return null;
    if (!mounted) return null;
    final local = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}T${two(local.hour)}:${two(local.minute)}';
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'advertiserName': _advertiserController.text.trim(),
      'creativeUrl': _creativeController.text.trim(),
      'destinationUrl': _destinationController.text.trim(),
      'ctaLabel': _ctaController.text.trim().isEmpty
          ? null
          : _ctaController.text.trim(),
      'placement': _placement.wire,
      'startAt': _startController.text.trim().isEmpty
          ? null
          : _startController.text.trim(),
      'endAt': _endController.text.trim().isEmpty
          ? null
          : _endController.text.trim(),
    };
  }

  Future<void> _saveAsDraft() async {
    await _submit(activate: false);
  }

  Future<void> _saveAndActivate() async {
    await _submit(activate: true);
  }

  Future<void> _submit({required bool activate}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      AdvertisementModel created;
      if (_isEdit) {
        created = await widget.advertisementService.updateAdvertisement(
          widget.advertisementId!,
          _buildPayload(),
        );
      } else {
        created = await widget.advertisementService.createAdvertisement(
          _buildPayload(),
        );
      }
      if (activate) {
        created = await widget.advertisementService.activateAdvertisement(created.id);
      }
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Advertisement' : 'New Advertisement'),
      ),
      body: _isLoading && !_ready
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && !_ready
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('BACK'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildTextField(
                        controller: _titleController,
                        label: 'Title *',
                        hint: 'Headline of the advertisement',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Short supporting text',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _advertiserController,
                        label: 'Advertiser name *',
                        hint: 'Displayed next to "Sponsored"',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Advertiser name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _creativeController,
                        label: 'Creative image URL *',
                        hint: 'https://...',
                        keyboardType: TextInputType.url,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Creative image URL is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _destinationController,
                        label: 'Destination URL *',
                        hint: 'https://...',
                        keyboardType: TextInputType.url,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Destination URL is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _ctaController,
                        label: 'Call to action',
                        hint: 'Defaults to "Learn more"',
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AdvertisementPlacement>(
                        initialValue: _placement,
                        decoration: const InputDecoration(
                          labelText: 'Placement',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: AdvertisementPlacement.values
                            .where(
                              (p) => p != AdvertisementPlacement.unknown,
                            )
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _placement = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _startController,
                              label: 'Start (optional)',
                              readOnly: true,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.event_outlined),
                                onPressed: _pickStart,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextField(
                              controller: _endController,
                              label: 'End (optional)',
                              readOnly: true,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.event_outlined),
                                onPressed: _pickEnd,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'An advertisement is always created as a draft and must be activated to appear.',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveAsDraft,
                          icon: const Icon(Icons.save_outlined),
                          label: _isEdit
                              ? const Text('SAVE CHANGES')
                              : const Text('SAVE DRAFT'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!_isEdit) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _saveAndActivate,
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('SAVE DRAFT & ACTIVATE'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool readOnly = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: suffixIcon,
      ),
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}