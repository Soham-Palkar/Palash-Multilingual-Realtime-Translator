import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../models/flashcard_model.dart';
import '../../../repositories/teacher_repository.dart';
import '../../../widgets/bilingual_text.dart';
import '../../../widgets/palash_asset_image.dart';

class ManualFlashcardCreator extends StatefulWidget {
  final FlashcardItem? initialCard;

  const ManualFlashcardCreator({super.key, this.initialCard});

  @override
  State<ManualFlashcardCreator> createState() => _ManualFlashcardCreatorState();
}

class _ManualFlashcardCreatorState extends State<ManualFlashcardCreator> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hindiController;
  late TextEditingController _santaliController;
  late TextEditingController _olChikiController;
  late TextEditingController _subcategoryController;

  String _selectedCategory = 'Language';
  String _selectedImage = 'assets/default_content/images/animals/elephant.png';
  bool _isEditing = false;

  final List<String> _categories = [
    'Language',
    'Mathematics',
    'General Knowledge',
  ];

  final List<Map<String, String>> _availableImages = [
    {'name': 'हाथी (Elephant)', 'path': 'assets/default_content/images/animals/elephant.png'},
    {'name': 'आम (Mango)', 'path': 'assets/default_content/images/fruits/mango.png'},
    {'name': 'सूरज (Sun)', 'path': 'assets/default_content/images/common/sun.png'},
    {'name': 'पेड़ (Tree)', 'path': 'assets/default_content/images/common/tree.png'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCard != null) {
      _isEditing = true;
      final c = widget.initialCard!;
      _selectedCategory = c.category;
      _selectedImage = c.image ?? 'assets/default_content/images/animals/elephant.png';
      _hindiController = TextEditingController(text: c.hindi);
      _santaliController = TextEditingController(text: c.santali);
      _olChikiController = TextEditingController(text: c.santaliOlChiki ?? '');
      _subcategoryController = TextEditingController(text: c.subcategory);
    } else {
      _hindiController = TextEditingController(text: 'मोर (Peacock)');
      _santaliController = TextEditingController(text: 'ᱢᱟᱨᱟᱜ (Marag)');
      _olChikiController = TextEditingController(text: 'ᱢᱟᱨᱟᱜ');
      _subcategoryController = TextEditingController(text: 'Animals');
    }
  }

  @override
  void dispose() {
    _hindiController.dispose();
    _santaliController.dispose();
    _olChikiController.dispose();
    _subcategoryController.dispose();
    super.dispose();
  }

  Future<void> _handleSave({required bool isPublished}) async {
    if (!_formKey.currentState!.validate()) return;

    final repo = Provider.of<TeacherRepository>(context, listen: false);
    final card = FlashcardItem(
      id: widget.initialCard?.id ?? 'fc_teacher_${const Uuid().v4().substring(0, 8)}',
      category: _selectedCategory,
      subcategory: _subcategoryController.text.trim().isNotEmpty
          ? _subcategoryController.text.trim()
          : 'Teacher Created',
      hindi: _hindiController.text.trim(),
      santali: _santaliController.text.trim(),
      santaliOlChiki: _olChikiController.text.trim().isNotEmpty
          ? _olChikiController.text.trim()
          : null,
      image: _selectedImage,
      isDefault: false,
      isTeacherCreated: true,
      isPublished: isPublished,
    );

    await repo.createManualFlashcard(card);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text(
            isPublished
                ? '✓ फ्लैशकार्ड प्रकाशित और ऑफ़लाइन सुरक्षित हुआ'
                : '✓ फ्लैशकार्ड ड्राफ्ट के रूप में सुरक्षित हुआ',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'फ्लैशकार्ड संपादित करें' : 'मैनुअल फ्लैशकार्ड टेम्पलेट',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Preview Card
              const Text(
                'लाइव कार्ड पूर्वावलोकन (Live Card Preview):',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              AnimatedBuilder(
                animation: Listenable.merge([
                  _hindiController,
                  _santaliController,
                  _olChikiController,
                ]),
                builder: (context, _) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, AppColors.primaryContainer.withOpacity(0.3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        PalashAssetImage(
                          imagePath: _selectedImage,
                          width: 100,
                          height: 100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        const SizedBox(height: 14),
                        BilingualText(
                          hindi: _hindiController.text.isNotEmpty
                              ? _hindiController.text
                              : 'हिन्दी शब्द',
                          santali: _santaliController.text.isNotEmpty
                              ? _santaliController.text
                              : 'ᱥᱟᱱᱛᱟᱲᱤ ᱥᱟᱵᱟᱫ',
                          santaliOlChiki: _olChikiController.text,
                          hindiFontSize: 20,
                          santaliFontSize: 16,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Image Selection
              const Text(
                '१. चित्र चुनें (Select Image):',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _availableImages.map((img) {
                    final isSelected = _selectedImage == img['path'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () => setState(() => _selectedImage = img['path']!),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryContainer
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              PalashAssetImage(
                                imagePath: img['path'],
                                width: 50,
                                height: 50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                img['name']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Category Selector
              const Text(
                '२. श्रेणी (Category):',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategory,
                    items: _categories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Subcategory input
              const Text(
                'उप-श्रेणी (Subcategory):',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _subcategoryController,
                decoration: const InputDecoration(
                  hintText: 'उदा. Animals, Fruits, Numbers...',
                ),
              ),

              const SizedBox(height: 18),

              // Hindi Text Input
              const Text(
                '३. हिन्दी शब्द / वाक्य (Hindi Text):',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _hindiController,
                decoration: const InputDecoration(hintText: 'उदा. हाथी'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'हिन्दी शब्द आवश्यक है';
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Santali Text Input
              const Text(
                '४. ᱥᱟᱱᱛᱟᱲᱤ ᱥᱟᱵᱟᱫ (Santali Text):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _santaliController,
                decoration: const InputDecoration(hintText: 'उदा. ᱦᱟᱹᱛᱤ (Hati)'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'संताली शब्द आवश्यक है';
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Ol Chiki Input (Optional)
              const Text(
                '५. ᱚᱞ ᱪᱤᱠᱤ (Ol Chiki - Optional):',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _olChikiController,
                decoration: const InputDecoration(hintText: 'उदा. ᱦᱟᱹᱛᱤ'),
              ),

              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleSave(isPublished: false),
                      child: const Text('ड्राफ्ट सेव करें'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleSave(isPublished: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                      ),
                      child: const Text('प्रकाशित करें (Publish)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
