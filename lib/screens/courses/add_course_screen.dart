import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../models/module.dart';
import '../../models/question.dart';
import '../../models/quiz.dart';
import '../../models/tp.dart';
import '../../services/course_service.dart';
import '../../services/user_service.dart';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final CourseService _courseService = CourseService();
  final UserService _userService = UserService();

  String _courseName = '';
  String _courseDescription = '';
  final List<Module> _modules = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ajouter un cours'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCourse,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nom du cours',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
                onChanged: (value) => _courseName = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description du cours',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
                onChanged: (value) => _courseDescription = value,
              ),
              const SizedBox(height: 24),
              Text('Modules', style: Theme.of(context).textTheme.titleLarge),
              ..._buildModulesList(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addModule,
                child: const Text('Ajouter un module'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addModule() {
    setState(() {
      _modules.add(Module(
        id: const Uuid().v4(),
        name: '',
        description: '',
        orderIndex: _modules.length + 1,
        isActive: true,
        quizzes: [],
        tps: [],
      ));
    });
  }

  List<Widget> _buildModulesList() {
    return _modules.asMap().entries.map((entry) {
      final module = entry.value;
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ExpansionTile(
          title: TextFormField(
            initialValue: module.name,
            decoration: const InputDecoration(
              labelText: 'Nom du module',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              setState(() {
                module.name = value;
              });
            },
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: module.description,
                    decoration: const InputDecoration(
                      labelText: 'Description du module',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      setState(() {
                        module.description = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildQuizSection(module),
                  const SizedBox(height: 16),
                  _buildTPSection(module),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildQuizSection(Module module) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quiz',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...module.quizzes.map((quiz) => QuizCard(
              quiz: quiz,
              onDelete: () {
                setState(() {
                  module.quizzes.remove(quiz);
                });
              },
            )),
        TextButton(
          onPressed: () {
            setState(() {
              module.quizzes.add(Quiz(
                title: '',
                timeLimit: 30,
                timeUnit: 'minutes',
                passingScore: 60,
                isActive: true,
                questions: [],
              ));
            });
          },
          child: const Text('Ajouter un quiz'),
        ),
      ],
    );
  }

  Widget _buildTPSection(Module module) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TPs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...module.tps.map((tp) => TPCard(
              tp: tp,
              onDelete: () {
                setState(() {
                  module.tps.remove(tp);
                });
              },
            )),
        TextButton(
          onPressed: () {
            setState(() {
              module.tps.add(TP(
                title: '',
                description: '',
                isActive: true,
              ));
            });
          },
          child: const Text('Ajouter un TP'),
        ),
      ],
    );
  }

  Future<void> _saveCourse() async {
    try {
      // 1. Validation initiale
      if (!_formKey.currentState!.validate()) {
        print('Validation du formulaire échouée');
        return;
      }

      if (_courseName.trim().isEmpty || _courseDescription.trim().isEmpty) {
        throw Exception('Le nom et la description du cours sont requis');
      }

      if (_modules.isEmpty) {
        throw Exception('Veuillez ajouter au moins un module');
      }

      // 2. Activer l'indicateur de chargement
      setState(() => _isLoading = true);

      // 3. Préparation et validation des données
      final userId = await _userService.getCurrentUserId();
      final courseId = const Uuid().v4();
      print('Préparation du cours avec ID: $courseId');

      for (final module in _modules) {
        if (module.name.trim().isEmpty) {
          throw Exception('Le nom du module est requis');
        }

        // Assigner les IDs
        module.id = const Uuid().v4();
        module.courseId = courseId;
        print('Traitement du module: ${module.name}');

        // Traitement des quiz
        for (final quiz in module.quizzes) {
          if (quiz.title.trim().isEmpty) {
            throw Exception('Le titre du quiz est requis');
          }

          quiz.id = const Uuid().v4();
          quiz.moduleId = module.id;
          print('Traitement du quiz: ${quiz.title}');

          // Validation des questions
          for (final question in quiz.questions) {
            if (question.questionText.trim().isEmpty) {
              throw Exception('Le texte de la question est requis');
            }

            question.id = const Uuid().v4();
            question.quizId = quiz.id;
          }
        }

        // Traitement des TPs
        for (final tp in module.tps) {
          if (tp.title.trim().isEmpty) {
            throw Exception('Le titre du TP est requis');
          }

          tp.id = const Uuid().v4();
          tp.moduleId = module.id;
          print('Traitement du TP: ${tp.title}');
        }
      }

      // 4. Sauvegarde des données
      print('Début de la sauvegarde du cours');
      await _courseService.createCourseWithModules(
        name: _courseName,
        description: _courseDescription,
        createdBy: userId,
        modules: _modules,
      );
      print('Cours sauvegardé avec succès');

      // 5. Vérification du montage du widget
      if (!mounted) {
        print('Widget non monté, arrêt de la procédure');
        return;
      }

      // 6. Affichage du message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cours créé avec succès'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 7. Navigation sécurisée
      if (mounted) {
        Navigator.pushReplacementNamed(
            context, '/admin/courses'); // Simplifié pour plus de robustesse
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');

      // Gestion des erreurs uniquement si le widget est toujours monté
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // Désactiver l'indicateur de chargement si le widget est toujours monté
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class QuizCard extends StatefulWidget {
  final Quiz quiz;
  final VoidCallback onDelete;

  const QuizCard({
    super.key,
    required this.quiz,
    required this.onDelete,
  });

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(
            widget.quiz.title.isEmpty ? 'Nouveau Quiz' : widget.quiz.title),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: widget.quiz.title,
                  decoration: const InputDecoration(
                    labelText: 'Titre du quiz',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      setState(() => widget.quiz.title = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: widget.quiz.timeLimit.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Temps limite',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => setState(
                            () => widget.quiz.timeLimit = int.tryParse(value)!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: widget.quiz.passingScore.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Score minimum (%)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => setState(() =>
                            widget.quiz.passingScore = int.tryParse(value)!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildQuestionsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Questions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            FilledButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.quiz.questions.map((question) => QuestionCard(
              question: question,
              onDelete: () => setState(() {
                widget.quiz.questions.remove(question);
              }),
            )),
      ],
    );
  }

  void _addQuestion() {
    try {
      setState(() {
        widget.quiz.questions.add(Question(
          id: const Uuid().v4(),
          quizId: widget.quiz.id,
          questionText: '',
          questionType: 'singleAnswer',
          answer: '',
          points: 1,
          choices: [],
        ));
        print('Question ajoutée');
      });
    } catch (e) {
      print('Erreur: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}

class QuestionCard extends StatefulWidget {
  final Question question;
  final VoidCallback onDelete;

  const QuestionCard({
    super.key,
    required this.question,
    required this.onDelete,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  final List<String> questionTypes = Question.validTypes;

  @override
  void initState() {
    super.initState();
    // Initialiser les choix si vides pour le type selection
    if (widget.question.questionType == 'selection' &&
        (widget.question.choices.isEmpty ?? true)) {
      widget.question.choices = [''];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionHeader(),
            const SizedBox(height: 16),
            _buildQuestionTypeAndPoints(),
            const SizedBox(height: 24),
            _buildAnswerSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionHeader() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: widget.question.questionText,
            decoration: InputDecoration(
              labelText: 'Question',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 2,
            onChanged: (value) => setState(() {
              widget.question.questionText = value;
            }),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: widget.onDelete,
        ),
      ],
    );
  }

  Widget _buildQuestionTypeAndPoints() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: widget.question.questionType,
            decoration: InputDecoration(
              labelText: 'Type de question',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: questionTypes
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(_getQuestionTypeLabel(type)),
                    ))
                .toList(),
            onChanged: _handleQuestionTypeChange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            initialValue: widget.question.points.toString(),
            decoration: InputDecoration(
              labelText: 'Points',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => setState(() {
              widget.question.points = int.tryParse(value) ?? 1;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerSection() {
    switch (widget.question.questionType) {
      case 'trueFalse':
        return _buildTrueFalseSection();
      case 'selection':
        return _buildSelectionSection();
      default:
        return _buildSingleAnswerSection();
    }
  }

  Widget _buildTrueFalseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Réponse:', style: Theme.of(context).textTheme.titleMedium),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Vrai'),
                value: 'true',
                groupValue: widget.question.answer,
                onChanged: (value) => setState(() {
                  widget.question.answer = value!;
                }),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Faux'),
                value: 'false',
                groupValue: widget.question.answer,
                onChanged: (value) => setState(() {
                  widget.question.answer = value!;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Réponses:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...widget.question.choices.asMap().entries.map(_buildChoiceItem),
        const SizedBox(height: 8),
        Center(
          child: FilledButton.icon(
            onPressed: _addChoice,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une réponse'),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceItem(MapEntry<int, String> entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: _isChoiceSelected(entry.value),
            onChanged: (checked) =>
                _handleChoiceSelection(entry.value, checked),
          ),
          Expanded(
            child: TextFormField(
              initialValue: entry.value,
              decoration: InputDecoration(
                labelText: 'Réponse ${entry.key + 1}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => _updateChoice(entry.key, value),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _removeChoice(entry.key),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleAnswerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Réponse:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: widget.question.answer,
          decoration: InputDecoration(
            labelText: 'Réponse attendue',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) => setState(() {
            widget.question.answer = value;
          }),
        ),
      ],
    );
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'trueFalse':
        return 'Vrai/Faux';
      case 'singleAnswer':
        return 'Réponse unique';
      case 'selection':
        return 'Sélection multiple';
      default:
        return type;
    }
  }

  void _handleQuestionTypeChange(String? value) {
    if (value != null) {
      setState(() {
        widget.question.questionType = value;
        widget.question.choices = value == 'selection' ? [''] : [];
        widget.question.answer = '';
      });
    }
  }

  bool _isChoiceSelected(String choice) {
    return widget.question.answer.split(',').contains(choice);
  }

  void _handleChoiceSelection(String choice, bool? checked) {
    setState(() {
      var answers = widget.question.answer.isEmpty
          ? []
          : widget.question.answer.split(',');
      if (checked ?? false) {
        answers.add(choice);
      } else {
        answers.remove(choice);
      }
      widget.question.answer = answers.join(',');
    });
  }

  void _updateChoice(int index, String value) {
    setState(() {
      List<String> choices = List.from(widget.question.choices ?? []);
      choices[index] = value;
      widget.question.choices = choices;
    });
  }

  void _removeChoice(int index) {
    setState(() {
      List<String> choices = List.from(widget.question.choices ?? []);
      choices.removeAt(index);
      widget.question.choices = choices;
    });
  }

  void _addChoice() {
    setState(() {
      List<String> choices = List.from(widget.question.choices ?? []);
      choices.add('');
      widget.question.choices = choices;
    });
  }
}

class TPCard extends StatefulWidget {
  final TP tp;
  final VoidCallback onDelete;

  const TPCard({
    super.key,
    required this.tp,
    required this.onDelete,
  });

  @override
  State<TPCard> createState() => _TPCardState();
}

class _TPCardState extends State<TPCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(widget.tp.title.isEmpty ? 'Nouveau TP' : widget.tp.title),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: widget.tp.title,
                  decoration: InputDecoration(
                    labelText: 'Titre du TP',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() => widget.tp.title = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: widget.tp.description,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                  onChanged: (value) =>
                      setState(() => widget.tp.description = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: widget.tp.maxPoints?.toString(),
                        decoration: InputDecoration(
                          labelText: 'Points maximum',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => setState(
                            () => widget.tp.maxPoints = int.tryParse(value)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue:
                            widget.tp.dueDate?.toString().split(' ')[0],
                        decoration: InputDecoration(
                          labelText: 'Date limite',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate:
                                    widget.tp.dueDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => widget.tp.dueDate = date);
                              }
                            },
                          ),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fichiers attachés',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (widget.tp.files != null &&
                            widget.tp.files!.isNotEmpty)
                          ...widget.tp.files!.map((file) => ListTile(
                                leading: const Icon(Icons.insert_drive_file),
                                title: Text(file.path.split('/').last),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      widget.tp.files!.remove(file);
                                    });
                                  },
                                ),
                              )),
                        const SizedBox(height: 8),
                        Center(
                          child: FilledButton.icon(
                            onPressed: () async {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                allowMultiple: true,
                                type: FileType.any,
                              );
                              if (result != null && result.files.isNotEmpty) {
                                setState(() {
                                  widget.tp.files ??= [];
                                  widget.tp.files!.addAll(
                                    result.files
                                        .map((file) => File(file.path!)),
                                  );
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Aucun fichier sélectionné'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Ajouter des fichiers'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
