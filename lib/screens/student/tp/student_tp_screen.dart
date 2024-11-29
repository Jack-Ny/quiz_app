import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/colors.dart';

class StudentTPScreen extends StatefulWidget {
  final String moduleTitle;
  final String courseTitle;

  const StudentTPScreen({
    super.key,
    required this.moduleTitle,
    required this.courseTitle,
  });

  @override
  State<StudentTPScreen> createState() => _StudentTPScreenState();
}

class _StudentTPScreenState extends State<StudentTPScreen> {
  final List<String> _teacherFiles = ['exercice-1.png', 'exercice-1.png'];
  final List<String> _studentFiles = [];
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  void _openTeacherFile(String fileName) {
    // Implémentez l'ouverture du fichier ici
    print('Ouverture du fichier: $fileName');
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _studentFiles.addAll(
            result.files.map((file) => file.name).toList(),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la sélection du fichier'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          _studentFiles.add(photo.name);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la prise de photo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitTP() {
    if (_studentFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un fichier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Implémentez la soumission du TP ici
    print('Soumission du TP');
    print('Fichiers: $_studentFiles');
    print('Commentaire: ${_commentController.text}');

    // Afficher un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('TP soumis avec succès'),
        backgroundColor: Colors.green,
      ),
    );

    // Retourner à la page précédente
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nom du TP',
          style: TextStyle(
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
            const Text(
              'TPs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Fichiers du professeur
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Liste des fichiers
                  ...ListTile.divideTiles(
                    context: context,
                    color: Colors.grey[300],
                    tiles: _teacherFiles.map((file) => ListTile(
                          leading: const Icon(Icons.file_present),
                          title: Text(file),
                          onTap: () => _openTeacherFile(file),
                        )),
                  ),
                  // Bouton de téléchargement
                  ListTile(
                    title: const Text(
                      'Télécharger un fichier',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () {
                      // Implémenter le téléchargement
                    },
                  ),
                ],
              ),
            ),
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
                    onPressed: _pickFile,
                    child: const Text('Choisir un fichier'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Liste des fichiers uploadés
            if (_studentFiles.isNotEmpty) ...[
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
                tiles: _studentFiles.map((file) => ListTile(
                      leading: const Icon(Icons.file_present),
                      title: Text(file),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _studentFiles.remove(file);
                          });
                        },
                      ),
                    )),
              ),
            ],
            const SizedBox(height: 20),

            // Section photo
            const Text(
              'Prendre une photo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Prendre une photo'),
            ),
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
