import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/supabase_config.dart';
import '../../../constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class StudentTPScreen extends StatefulWidget {
  final String tpId;
  final String moduleTitle;
  final String courseTitle;

  const StudentTPScreen({
    super.key,
    required this.tpId,
    required this.moduleTitle,
    required this.courseTitle,
  });

  @override
  State<StudentTPScreen> createState() => _StudentTPScreenState();
}

class _StudentTPScreenState extends State<StudentTPScreen> {
  final _supabase = SupabaseConfig.client;
  bool _isLoading = true;
  Map<String, dynamic>? _tpData;
  Map<String, dynamic>? _existingSubmission;
  final List<PlatformFile> _selectedFiles = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTPData();
  }

  Future<void> _submitTP() async {
  try {
    if (_selectedFiles.isEmpty) {
      throw Exception('Veuillez ajouter au moins un fichier');
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('connected_user_id');
    if (userId == null) throw Exception('Utilisateur non connecté');

    final studentData = await _supabase
        .from('students')
        .select('id')
        .eq('user_id', userId)
        .single();

    // Liste pour stocker les URLs des fichiers uploadés
    final uploadedFiles = [];

    // Upload chaque fichier
    for (var file in _selectedFiles) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = 'submissions/${widget.tpId}/$fileName';
      
      // Upload le fichier
      await _supabase.storage
          .from('tp-submissions') // Assurez-vous que ce bucket existe dans Supabase
          .uploadBinary(filePath, file.bytes!);

      // Obtenir l'URL publique
      final fileUrl = _supabase.storage
          .from('tp-submissions')
          .getPublicUrl(filePath);

      uploadedFiles.add({
        'name': file.name,
        'size': file.size,
        'url': fileUrl
      });
    }

    // Créer la soumission
    await _supabase.from('tp_submissions').upsert({
      'tp_id': widget.tpId,
      'student_id': studentData['id'],
      'submitted_files': uploadedFiles,
      'comment': _commentController.text,
      'submission_date': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('TP soumis avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}

  // Pour le launchUrl, ajouter cette méthode
Future<void> _launchUrl(String url) async {
  if (await canLaunchUrlString(url)) {
    await launchUrlString(url);
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le fichier')),
      );
    }
  }
}

Future<void> _pickFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx'],
      withData: true, // Important pour récupérer les bytes
    );

    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la sélection: $e')),
    );
  }
}

  Future<void> _loadTPData() async {
    try {
      // Get student ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('connected_user_id');
      if (userId == null) throw Exception('Utilisateur non connecté');

      final studentData = await _supabase
          .from('students')
          .select('id')
          .eq('user_id', userId)
          .single();
      
      final studentId = studentData['id'];

      // Load TP data
      final tpData = await _supabase
          .from('tps')
          .select()
          .eq('id', widget.tpId)
          .single();

      // Check for existing submission
      final submissions = await _supabase
          .from('tp_submissions')
          .select()
          .eq('tp_id', widget.tpId)
          .eq('student_id', studentId);

      setState(() {
        _tpData = tpData;
        _existingSubmission = submissions.isNotEmpty ? submissions.first : null;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        for (var file in result.files) {
          await _uploadFile(file);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection: $e')),
      );
    }
  }


  Future<void> _uploadFile(PlatformFile file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = 'tp_submissions/${widget.tpId}/$fileName';
      
      await _supabase.storage
          .from('tp-files')
          .uploadBinary(filePath, file.bytes!);

      setState(() {
        _selectedFiles.add(file);
      });
    } catch (e) {
      throw Exception('Erreur upload: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final teacherFiles = List<String>.from(_tpData?['file_urls'] ?? []);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _tpData?['title'] ?? 'TP',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description du TP
            Text(
              _tpData?['description'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Fichiers du professeur
            if (teacherFiles.isNotEmpty) ...[
              const Text(
                'Fichiers fournis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: teacherFiles.map((file) => ListTile(
                    leading: const Icon(Icons.file_present),
                    title: Text(file),
                    onTap: () => _launchUrl(_supabase.storage
    .from('tp-files')
    .getPublicUrl(file)),
                  )).toList(),
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Section d'upload
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.upload_file, size: 40, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text(
                    'Déposer vos fichiers ici',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: _pickAndUploadFile,
                    child: const Text('Choisir un fichier'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Liste des fichiers uploadés
            if (_selectedFiles.isNotEmpty) ...[
              const Text(
                'Fichiers sélectionnés',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...ListTile.divideTiles(
                context: context,
                color: Colors.grey[300],
                tiles: _selectedFiles.map((file) => ListTile(
                      leading: const Icon(Icons.file_present),
                      title: Text(file.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedFiles.remove(file);
                          });
                        },
                      ),
                    )),
              ),
            ],
            const SizedBox(height: 20),

            // Section commentaire
            const Text(
              'Commentaire (facultatif)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tapez ici pour écrire le commentaire...',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Bouton d'envoi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Envoyer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
