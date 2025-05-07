import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_transcript_app/features/meeting_records/domain/entities/meeting_record.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/providers/meeting_records_provider.dart';

class EditMeetingScreen extends StatefulWidget {
  final String meetingId;

  const EditMeetingScreen({super.key, required this.meetingId});

  @override
  State<EditMeetingScreen> createState() => _EditMeetingScreenState();
}

class _EditMeetingScreenState extends State<EditMeetingScreen> {
  late MeetingRecord _initialRecord;
  late TextEditingController _titleController;
  late TextEditingController _participantsController;
  late TextEditingController _descriptionController;
  late TextEditingController _transcriptController; // For editing transcript

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _participantsController = TextEditingController();
    _descriptionController = TextEditingController();
    _transcriptController = TextEditingController();
    _loadMeetingData();
  }

  Future<void> _loadMeetingData() async {
    final provider = Provider.of<MeetingRecordsProvider>(
      context,
      listen: false,
    );
    final record = provider.getMeetingRecordById(widget.meetingId);

    if (record != null) {
      _initialRecord = record;
      _titleController.text = record.title;
      _participantsController.text = record.participantIds.join(', ');
      _descriptionController.text = record.description ?? '';
      _transcriptController.text = record.transcript;
      setState(() {
        _isLoading = false;
      });
    } else {
      // Handle case where record is not found (should ideally not happen if navigated correctly)
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.genericError),
          ), // Or a more specific error
        );
        context.pop(); // Go back if record not found
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _participantsController.dispose();
    _descriptionController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final provider = Provider.of<MeetingRecordsProvider>(
        context,
        listen: false,
      );
      final List<String> participantList =
          _participantsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      final updatedRecord = _initialRecord.copyWith(
        title: _titleController.text,
        participantIds: participantList,
        description: _descriptionController.text,
        transcript: _transcriptController.text,
        // Note: startTime, endTime, audioFilePath are not typically edited here
      );

      try {
        await provider.updateMeetingRecord(updatedRecord);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.saveSuccessMessage),
            ),
          );
          // Navigate back to details screen, potentially with a result to refresh
          context.pop(true); // Pass true to indicate save was successful
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.saveErrorMessage(e.toString()),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editMeetingTitle)), // Localize
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editMeetingTitle), // Localize
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isSaving ? null : () => context.pop(),
          tooltip: l10n.dialogButtonCancel,
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(
                      l10n.saveButtonLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ), // Localize
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: <Widget>[
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: l10n.meetingTitleLabel, // From record_screen
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          // return l10n.titleRequiredError; // Add this localization
                          return 'Title cannot be empty';
                        }
                        return null;
                      },
                      enabled: !_isSaving,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _participantsController,
                      decoration: InputDecoration(
                        labelText: l10n.participantsLabel, // From record_screen
                        hintText: l10n.participantsHint, // From record_screen
                        border: const OutlineInputBorder(),
                      ),
                      enabled: !_isSaving,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.descriptionLabel, // From record_screen
                        hintText: l10n.descriptionHint, // From record_screen
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      enabled: !_isSaving,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _transcriptController,
                      decoration: InputDecoration(
                        labelText:
                            l10n.transcriptTitle, // From meeting_details_screen
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 10, // Adjust as needed
                      keyboardType: TextInputType.multiline,
                      enabled: !_isSaving,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_alt_outlined),
                      label: Text(l10n.saveMeetingButton), // From record_screen
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: _isSaving ? null : _saveChanges,
                    ),
                  ],
                ),
              ),
    );
  }
}
