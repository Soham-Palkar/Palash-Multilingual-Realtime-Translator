import '../models/flashcard_model.dart';
import '../models/game_model.dart';
import '../models/worksheet_model.dart';

/// Canonical Master Educational Concept representation for PALASH.
/// All educational content (Flashcards, Games, Worksheets) is derived from this master dataset.
/// Source: Santali_Flashcards dataset.
class MasterConcept {
  final String id;
  final String category;
  final String subcategory;
  final String hindi;
  final String santali;
  final String? santaliOlChiki;
  final String? imageKey;
  final String? pronunciation;
  final String? linguistNote;

  const MasterConcept({
    required this.id,
    required this.category,
    required this.subcategory,
    required this.hindi,
    required this.santali,
    this.santaliOlChiki,
    this.imageKey,
    this.pronunciation,
    this.linguistNote,
  });

  FlashcardItem toFlashcard() {
    return FlashcardItem(
      id: 'fc_$id',
      category: category,
      subcategory: subcategory,
      hindi: hindi,
      santali: santali,
      santaliOlChiki: santaliOlChiki ?? santali,
      image: imageKey,
      pronunciation: pronunciation,
      linguistNote: linguistNote,
      isDefault: true,
      isTeacherCreated: false,
      isPublished: true,
    );
  }
}

class MasterSantaliContent {
  static const List<MasterConcept> concepts = [
    // ==========================================
    // GENERAL KNOWLEDGE: ANIMALS (13 concepts)
    // ==========================================
    MasterConcept(
      id: 'gk_anim_dog',
      category: 'General Knowledge',
      subcategory: 'Animals',
      hindi: 'कुत्ता',
      santali: 'ᱜᱩᱛᱤ ᱫᱚ ᱾',
      santaliOlChiki: 'ᱜᱩᱛᱤ ᱫᱚ ᱾',
      imageKey: 'dog',
      pronunciation: 'Kutta / Guti',
    ),
    MasterConcept(
      id: 'gk_anim_cat',
      category: 'General Knowledge',
      subcategory: 'Animals',
      hindi: 'बिल्ली',
      santali: 'ᱵᱳᱭᱥ ᱫᱚ ᱾',
      santaliOlChiki: 'ᱵᱳᱭᱥ ᱫᱚ ᱾',
      imageKey: 'cat',
      pronunciation: 'Billi / Boys',
    ),
    MasterConcept(
      id: 'gk_anim_cow',
      category: 'General Knowledge',
      subcategory: 'Animals',
      hindi: 'गाय',
      santali: 'ᱜᱚᱭ ᱾',
      santaliOlChiki: 'ᱜᱚᱭ ᱾',
      imageKey: 'cow',
      pronunciation: 'Gaay / Goy',
    ),
    MasterConcept(
      id: 'gk_anim_horse',
      category: 'General Knowledge',
      subcategory: 'Animals',
      hindi: 'घोड़ा',
      santali: 'ᱜᱳᱲᱤᱭᱟᱹ ᱠᱚ ᱾',
      santaliOlChiki: 'ᱜᱳᱲᱤᱭᱟᱹ ᱠᱚ ᱾',
      imageKey: 'horse',
      pronunciation: 'Ghoda / Goriya',
    ),
    MasterConcept(
      id: 'gk_anim_goat',
      category: 'General Knowledge',
      subcategory: 'Animals',
      hindi: 'बकरी',
      santali: 'ᱵᱳᱭᱥ ᱠᱚ ᱾',
      santaliOlChiki: 'ᱵᱳᱭᱥ ᱠᱚ ᱾',
      imageKey: 'goat',
      pronunciation: 'Bakri / Boys ko',
    ),
    MasterConcept(
      id: 'gk_anim_sheep',
      category: 'General Knowledge',
      subcategory: 'Animals',
      hindi: 'भेड़',
      santali: 'ᱜᱳᱲᱤᱭᱟᱹ ᱠᱚ ᱾',
      santaliOlChiki: 'ᱜᱳᱲᱤᱭᱟᱹ ᱠᱚ ᱾',
      imageKey: null, // Image missing
      pronunciation: 'Bhed / Goriya ko',
    ),
    MasterConcept(
      id: 'gk_anim_lion',
      category: 'General Knowledge',
      subcategory: 'Animals',
      hindi: 'शेर',
      santali: 'ᱥᱤᱝ ᱾',
      santaliOlChiki: 'ᱥᱤᱝ ᱾',
      imageKey: null, // Image missing
      pronunciation: 'Sher / Sing',
    ),
    MasterConcept(
      id: 'gk_anim_tiger',
      category: 'General Knowledge',
      subcategory: 'Animals',
      hindi: 'बाघ',
      santali: 'ᱴᱟᱭᱜᱟᱨ ᱾',
      santaliOlChiki: 'ᱴᱟᱭᱜᱟᱨ ᱾',
      imageKey: 'tiger',
      pronunciation: 'Baagh / Taigar',
    ),
    MasterConcept(
      id: 'gk_anim_elephant',
      category: 'General Knowledge',
      subcategory: 'Animals',
      hindi: 'हाथी',
      santali: 'ᱦᱟᱹᱱᱛᱤ ᱾',
      santaliOlChiki: 'ᱦᱟᱹᱱᱛᱤ ᱾',
      imageKey: 'elephant',
      pronunciation: 'Haathi / Hanti',
    ),
    MasterConcept(
      id: 'gk_anim_monkey',
      category: 'General Knowledge',
      subcategory: 'Animals',
      hindi: 'बंदर',
      santali: 'ᱢᱟᱱᱠᱨᱤ ᱾',
      santaliOlChiki: 'ᱢᱟᱱᱠᱨᱤ ᱾',
      imageKey: null, // Image missing
      pronunciation: 'Bandar / Mankri',
    ),
    MasterConcept(
      id: 'gk_anim_deer',
      category: 'General Knowledge',
      subcategory: 'Animals',
      hindi: 'हिरण',
      santali: 'ᱦᱟᱹᱱᱛᱤ ᱾',
      santaliOlChiki: 'ᱦᱟᱹᱱᱛᱤ ᱾',
      imageKey: null, // Image missing
      pronunciation: 'Hiran / Hanti',
    ),
    MasterConcept(
      id: 'gk_anim_rabbit',
      category: 'General Knowledge',
      subcategory: 'Animals',
      hindi: 'खरगोश',
      santali: 'ᱜᱷᱩᱨᱩᱢ ᱫᱚ ᱾',
      santaliOlChiki: 'ᱜᱷᱩᱨᱩᱢ ᱫᱚ ᱾',
      imageKey: 'rabbit',
      pronunciation: 'Khargosh / Ghurum',
    ),
    MasterConcept(
      id: 'gk_anim_bear',
      category: 'General Knowledge',
      subcategory: 'Animals',
      hindi: 'भालू',
      santali: 'ᱵᱷᱟᱲᱟ ᱾',
      santaliOlChiki: 'ᱵᱷᱟᱲᱟ ᱾',
      imageKey: null, // Image missing
      pronunciation: 'Bhaalu / Bhada',
    ),

    // ==========================================
    // GENERAL KNOWLEDGE: BIRDS (12 concepts)
    // ==========================================
    MasterConcept(
      id: 'gk_bird_duck',
      category: 'General Knowledge',
      subcategory: 'Birds',
      hindi: 'बतख',
      santali: 'ᱫᱟ',
      santaliOlChiki: 'ᱫᱟ',
      imageKey: null, // Missing bird image
    ),
    MasterConcept(
      id: 'gk_bird_pigeon',
      category: 'General Knowledge',
      subcategory: 'Birds',
      hindi: 'कबूतर',
      santali: 'ᱠᱟᱵᱷᱟᱨ ᱾',
      santaliOlChiki: 'ᱠᱟᱵᱷᱟᱨ ᱾',
      imageKey: null, // Missing
    ),
    MasterConcept(
      id: 'gk_bird_parrot',
      category: 'General Knowledge',
      subcategory: 'Birds',
      hindi: 'तोता',
      santali: 'ᱯᱮᱨᱟᱴᱤ ᱾',
      santaliOlChiki: 'ᱯᱮᱨᱟᱴᱤ ᱾',
      imageKey: null, // Missing
    ),
    MasterConcept(
      id: 'gk_bird_crow',
      category: 'General Knowledge',
      subcategory: 'Birds',
      hindi: 'कौआ',
      santali: 'ᱠᱟᱶᱰᱤ ᱾',
      santaliOlChiki: 'ᱠᱟᱶᱰᱤ ᱾',
      imageKey: null, // Missing
    ),
    MasterConcept(
      id: 'gk_bird_myna',
      category: 'General Knowledge',
      subcategory: 'Birds',
      hindi: 'मैना',
      santali: 'ᱢᱮᱭᱱᱟ ᱾',
      santaliOlChiki: 'ᱢᱮᱭᱱᱟ ᱾',
      imageKey: null, // Missing
    ),
    MasterConcept(
      id: 'gk_bird_peacock',
      category: 'General Knowledge',
      subcategory: 'Birds',
      hindi: 'मोर',
      santali: 'ᱢᱳᱨ ᱾',
      santaliOlChiki: 'ᱢᱳᱨ ᱾',
      imageKey: null, // Missing
    ),
    MasterConcept(
      id: 'gk_bird_cuckoo',
      category: 'General Knowledge',
      subcategory: 'Birds',
      hindi: 'कोयल',
      santali: 'ᱠᱳᱭᱤᱞ ᱾',
      santaliOlChiki: 'ᱠᱳᱭᱤᱞ ᱾',
      imageKey: null, // Missing
    ),
    MasterConcept(
      id: 'gk_bird_owl',
      category: 'General Knowledge',
      subcategory: 'Birds',
      hindi: 'उल्लू',
      santali: 'ᱞᱟᱹᱞᱤᱥᱠᱚ ᱾',
      santaliOlChiki: 'ᱞᱟᱹᱞᱤᱥᱠᱚ ᱾',
      imageKey: null, // Missing
    ),
    MasterConcept(
      id: 'gk_bird_eagle',
      category: 'General Knowledge',
      subcategory: 'Birds',
      hindi: 'गरुड़',
      santali: 'ᱜᱟᱨᱩᱰ ᱾',
      santaliOlChiki: 'ᱜᱟᱨᱩᱰ ᱾',
      imageKey: null, // Missing
    ),
    MasterConcept(
      id: 'gk_bird_hawk',
      category: 'General Knowledge',
      subcategory: 'Birds',
      hindi: 'बाज़',
      santali: 'ᱫᱟ ᱳᱣᱟᱠ ᱾',
      santaliOlChiki: 'ᱫᱟ ᱳᱣᱟᱠ ᱾',
      imageKey: null, // Missing
    ),
    MasterConcept(
      id: 'gk_bird_kite',
      category: 'General Knowledge',
      subcategory: 'Birds',
      hindi: 'चील',
      santali: 'ᱪᱤᱠᱮᱞ ᱾',
      santaliOlChiki: 'ᱪᱤᱠᱮᱞ ᱾',
      imageKey: null, // Missing
    ),
    MasterConcept(
      id: 'gk_bird_swan',
      category: 'General Knowledge',
      subcategory: 'Birds',
      hindi: 'हंस',
      santali: 'ᱦᱮᱱᱥ ᱾',
      santaliOlChiki: 'ᱦᱮᱱᱥ ᱾',
      imageKey: null, // Missing
    ),

    // ==========================================
    // GENERAL KNOWLEDGE: COLORS (10 concepts)
    // ==========================================
    MasterConcept(
      id: 'gk_color_red',
      category: 'General Knowledge',
      subcategory: 'Colors',
      hindi: 'लाल',
      santali: 'ᱨᱮᱞᱰ ᱾',
      santaliOlChiki: 'ᱨᱮᱞᱰ ᱾',
      imageKey: 'red',
    ),
    MasterConcept(
      id: 'gk_color_blue',
      category: 'General Knowledge',
      subcategory: 'Colors',
      hindi: 'नीला',
      santali: 'ᱱᱤᱞᱩ ᱾',
      santaliOlChiki: 'ᱱᱤᱞᱩ ᱾',
      imageKey: 'blue',
    ),
    MasterConcept(
      id: 'gk_color_green',
      category: 'General Knowledge',
      subcategory: 'Colors',
      hindi: 'हरा',
      santali: 'ᱜᱟᱹᱨᱰᱩ ᱾',
      santaliOlChiki: 'ᱜᱟᱹᱨᱰᱩ ᱾',
      imageKey: 'green',
    ),
    MasterConcept(
      id: 'gk_color_yellow',
      category: 'General Knowledge',
      subcategory: 'Colors',
      hindi: 'पीला',
      santali: 'ᱡᱚᱞᱟ ᱾',
      santaliOlChiki: 'ᱡᱚᱞᱟ ᱾',
      imageKey: 'yellow',
    ),
    MasterConcept(
      id: 'gk_color_orange',
      category: 'General Knowledge',
      subcategory: 'Colors',
      hindi: 'नारंगी',
      santali: 'ᱠᱚᱢᱞᱟ ᱾',
      santaliOlChiki: 'ᱠᱚᱢᱞᱟ ᱾',
      imageKey: 'orange_color',
    ),
    MasterConcept(
      id: 'gk_color_pink',
      category: 'General Knowledge',
      subcategory: 'Colors',
      hindi: 'गुलाबी',
      santali: 'ᱜᱚᱞᱚᱠ ᱾',
      santaliOlChiki: 'ᱜᱚᱞᱚᱠ ᱾',
      imageKey: 'pink',
    ),
    MasterConcept(
      id: 'gk_color_purple',
      category: 'General Knowledge',
      subcategory: 'Colors',
      hindi: 'बैंगनी',
      santali: 'ᱵᱨᱟᱢᱵᱷᱚ ᱾',
      santaliOlChiki: 'ᱵᱨᱟᱢᱵᱷᱚ ᱾',
      imageKey: null,
    ),
    MasterConcept(
      id: 'gk_color_brown',
      category: 'General Knowledge',
      subcategory: 'Colors',
      hindi: 'भूरा',
      santali: 'ᱵᱨᱟᱣᱩᱱ ᱾',
      santaliOlChiki: 'ᱵᱨᱟᱣᱩᱱ ᱾',
      imageKey: null,
    ),
    MasterConcept(
      id: 'gk_color_black',
      category: 'General Knowledge',
      subcategory: 'Colors',
      hindi: 'काला',
      santali: 'ᱠᱟᱞᱟᱹᱜ ᱾',
      santaliOlChiki: 'ᱠᱟᱞᱟᱹᱜ ᱾',
      imageKey: 'black',
    ),
    MasterConcept(
      id: 'gk_color_white',
      category: 'General Knowledge',
      subcategory: 'Colors',
      hindi: 'सफेद',
      santali: 'ᱥᱟᱭᱴ ᱾',
      santaliOlChiki: 'ᱥᱟᱭᱴ ᱾',
      imageKey: 'white',
    ),

    // ==========================================
    // MATHEMATICS: COUNTING (20 concepts)
    // ==========================================
    MasterConcept(id: 'math_cnt_1', category: 'Mathematics', subcategory: 'Counting', hindi: 'एक (1)', santali: 'ᱢᱤᱫᱴᱟᱝ ᱾', santaliOlChiki: 'ᱢᱤᱫᱴᱟᱝ ᱾'),
    MasterConcept(id: 'math_cnt_2', category: 'Mathematics', subcategory: 'Counting', hindi: 'दो (2)', santali: 'ᱟᱭᱢᱟᱜᱟᱱ', santaliOlChiki: 'ᱟᱭᱢᱟᱜᱟᱱ'),
    MasterConcept(id: 'math_cnt_3', category: 'Mathematics', subcategory: 'Counting', hindi: 'तीन (3)', santali: 'ᱯᱮᱭᱟ ᱾', santaliOlChiki: 'ᱯᱮᱭᱟ ᱾'),
    MasterConcept(id: 'math_cnt_4', category: 'Mathematics', subcategory: 'Counting', hindi: 'चार (4)', santali: '4 ᱜᱚᱴᱟᱝ ᱾', santaliOlChiki: '4 ᱜᱚᱴᱟᱝ ᱾'),
    MasterConcept(id: 'math_cnt_5', category: 'Mathematics', subcategory: 'Counting', hindi: 'पाँच (5)', santali: 'ᱢᱚᱬᱮ ᱜᱚᱴᱟᱝ ᱾', santaliOlChiki: 'ᱢᱚᱬᱮ ᱜᱚᱴᱟᱝ ᱾'),
    MasterConcept(id: 'math_cnt_6', category: 'Mathematics', subcategory: 'Counting', hindi: 'छह (6)', santali: 'ᱛᱩᱨᱩᱭ ᱜᱚᱴᱟᱝ ᱾', santaliOlChiki: 'ᱛᱩᱨᱩᱭ ᱜᱚᱴᱟᱝ ᱾'),
    MasterConcept(id: 'math_cnt_7', category: 'Mathematics', subcategory: 'Counting', hindi: 'सात (7)', santali: 'ᱮᱭᱟᱭ ᱜᱚᱴᱟᱝ ᱾', santaliOlChiki: 'ᱮᱭᱟᱭ ᱜᱚᱴᱟᱝ ᱾'),
    MasterConcept(id: 'math_cnt_8', category: 'Mathematics', subcategory: 'Counting', hindi: 'आठ (8)', santali: '8 ᱜᱚᱴᱟᱝ ᱾', santaliOlChiki: '8 ᱜᱚᱴᱟᱝ ᱾'),
    MasterConcept(id: 'math_cnt_9', category: 'Mathematics', subcategory: 'Counting', hindi: 'नौ (9)', santali: 'ᱱᱟᱶᱟ ᱾', santaliOlChiki: 'ᱱᱟᱶᱟ ᱾'),
    MasterConcept(id: 'math_cnt_10', category: 'Mathematics', subcategory: 'Counting', hindi: 'दस (10)', santali: 'ᱜᱮᱞ', santaliOlChiki: 'ᱜᱮᱞ'),
    MasterConcept(id: 'math_cnt_11', category: 'Mathematics', subcategory: 'Counting', hindi: 'ग्यारह (11)', santali: 'ᱜᱮᱞ ᱢᱤᱫ ᱾', santaliOlChiki: 'ᱜᱮᱞ ᱢᱤᱫ ᱾'),
    MasterConcept(id: 'math_cnt_12', category: 'Mathematics', subcategory: 'Counting', hindi: 'बारह (12)', santali: 'ᱵᱟᱨ ᱜᱚᱴᱟᱝ ᱾', santaliOlChiki: 'ᱵᱟᱨ ᱜᱚᱴᱟᱝ ᱾'),
    MasterConcept(id: 'math_cnt_13', category: 'Mathematics', subcategory: 'Counting', hindi: 'तेरह (13)', santali: 'ᱜᱮᱞ ᱯᱮ ᱾', santaliOlChiki: 'ᱜᱮᱞ ᱯᱮ ᱾'),
    MasterConcept(id: 'math_cnt_14', category: 'Mathematics', subcategory: 'Counting', hindi: 'चौदह (14)', santali: 'ᱜᱮᱞ ᱜᱮᱞ', santaliOlChiki: 'ᱜᱮᱞ ᱜᱮᱞ'),
    MasterConcept(id: 'math_cnt_15', category: 'Mathematics', subcategory: 'Counting', hindi: 'पंद्रह (15)', santali: 'ᱜᱮᱞ ᱢᱚᱬᱮ', santaliOlChiki: 'ᱜᱮᱞ ᱢᱚᱬᱮ'),
    MasterConcept(id: 'math_cnt_16', category: 'Mathematics', subcategory: 'Counting', hindi: 'सोलह (16)', santali: 'ᱜᱮᱞ ᱩᱱ', santaliOlChiki: 'ᱜᱮᱞ ᱩᱱ'),
    MasterConcept(id: 'math_cnt_17', category: 'Mathematics', subcategory: 'Counting', hindi: 'सत्रह (17)', santali: 'ᱜᱮᱞ ᱯᱩᱱ', santaliOlChiki: 'ᱜᱮᱞ ᱯᱩᱱ'),
    MasterConcept(id: 'math_cnt_18', category: 'Mathematics', subcategory: 'Counting', hindi: 'अठारह (18)', santali: 'ᱜᱮᱞ ᱡᱚᱺ', santaliOlChiki: 'ᱜᱮᱞ ᱡᱚᱺ'),
    MasterConcept(id: 'math_cnt_19', category: 'Mathematics', subcategory: 'Counting', hindi: 'उन्नीस (19)', santali: 'ᱜᱮᱞ ᱟᱬᱟ', santaliOlChiki: 'ᱜᱮᱞ ᱟᱬᱟ'),
    MasterConcept(id: 'math_cnt_20', category: 'Mathematics', subcategory: 'Counting', hindi: 'बीस (20)', santali: 'ᱵᱟᱨ ᱜᱮᱞ', santaliOlChiki: 'ᱵᱟᱨ ᱜᱮᱞ'),

    // ==========================================
    // GENERAL KNOWLEDGE: FRUITS (13 concepts)
    // ==========================================
    MasterConcept(
      id: 'gk_fruit_apple',
      category: 'General Knowledge',
      subcategory: 'Fruits',
      hindi: 'सेब',
      santali: 'ᱟᱢᱚᱞ ᱾',
      santaliOlChiki: 'ᱟᱢᱚᱞ ᱾',
      imageKey: 'apple',
      pronunciation: 'Seb / Amol',
    ),
    MasterConcept(
      id: 'gk_fruit_banana',
      category: 'General Knowledge',
      subcategory: 'Fruits',
      hindi: 'केला',
      santali: 'ᱠᱟᱞᱞᱟ ᱾',
      santaliOlChiki: 'ᱠᱟᱞᱞᱟ ᱾',
      imageKey: 'banana',
      pronunciation: 'Kela / Kalla',
    ),
    MasterConcept(
      id: 'gk_fruit_mango',
      category: 'General Knowledge',
      subcategory: 'Fruits',
      hindi: 'आम',
      santali: 'ᱥᱟᱫᱷᱟᱨᱚᱱ ᱾',
      santaliOlChiki: 'ᱥᱟᱫᱷᱟᱨᱚᱱ ᱾',
      imageKey: 'mango',
      pronunciation: 'Aam / Sadharan',
    ),
    MasterConcept(
      id: 'gk_fruit_orange',
      category: 'General Knowledge',
      subcategory: 'Fruits',
      hindi: 'संतरा',
      santali: 'ᱠᱚᱢᱞᱟ ᱾',
      santaliOlChiki: 'ᱠᱚᱢᱞᱟ ᱾',
      imageKey: 'orange',
      pronunciation: 'Santra / Komla',
    ),
    MasterConcept(
      id: 'gk_fruit_grapes',
      category: 'General Knowledge',
      subcategory: 'Fruits',
      hindi: 'अंगूर',
      santali: 'ᱮᱝᱠᱨᱤ ᱾',
      santaliOlChiki: 'ᱮᱝᱠᱨᱤ ᱾',
      imageKey: 'grapes',
      pronunciation: 'Angoor / Engkri',
    ),
    MasterConcept(
      id: 'gk_fruit_pomegranate',
      category: 'General Knowledge',
      subcategory: 'Fruits',
      hindi: 'अनार',
      santali: 'ᱚᱱᱩᱢᱟᱹᱱᱛᱤ ᱾',
      santaliOlChiki: 'ᱚᱱᱩᱢᱟᱹᱱᱛᱤ ᱾',
      imageKey: 'pomegranate',
      pronunciation: 'Anar / Anumanti',
    ),
    MasterConcept(
      id: 'gk_fruit_watermelon',
      category: 'General Knowledge',
      subcategory: 'Fruits',
      hindi: 'तरबूज',
      santali: 'ᱫᱟᱜᱫᱩᱱᱩᱞ ᱾',
      santaliOlChiki: 'ᱫᱟᱜᱫᱩᱱᱩᱞ ᱾',
      imageKey: 'watermelon',
      pronunciation: 'Tarbuj / Dagdunul',
    ),
    MasterConcept(
      id: 'gk_fruit_papaya',
      category: 'General Knowledge',
      subcategory: 'Fruits',
      hindi: 'पपीता',
      santali: 'ᱯᱮᱯᱟᱯᱟ ᱾',
      santaliOlChiki: 'ᱯᱮᱯᱟᱯᱟ ᱾',
      imageKey: 'papaya',
      pronunciation: 'Papita / Pepapa',
    ),
    MasterConcept(
      id: 'gk_fruit_guava',
      category: 'General Knowledge',
      subcategory: 'Fruits',
      hindi: 'अमरूद',
      santali: 'ᱟᱢᱚᱞ ᱾',
      santaliOlChiki: 'ᱟᱢᱚᱞ ᱾',
      imageKey: 'guava',
      pronunciation: 'Amrood / Amol',
    ),
    MasterConcept(
      id: 'gk_fruit_coconut',
      category: 'General Knowledge',
      subcategory: 'Fruits',
      hindi: 'नारियल',
      santali: 'ᱱᱟᱨᱠᱮᱞ ᱾',
      santaliOlChiki: 'ᱱᱟᱨᱠᱮᱞ ᱾',
      imageKey: null, // Missing image
    ),
    MasterConcept(
      id: 'gk_fruit_pineapple',
      category: 'General Knowledge',
      subcategory: 'Fruits',
      hindi: 'अनानास',
      santali: 'ᱚᱱᱤᱱᱮᱥ ᱾',
      santaliOlChiki: 'ᱚᱱᱤᱱᱮᱥ ᱾',
      imageKey: null, // Missing image
    ),
    MasterConcept(
      id: 'gk_fruit_lemon',
      category: 'General Knowledge',
      subcategory: 'Fruits',
      hindi: 'नींबू',
      santali: 'ᱞᱮᱢᱩᱱ ᱾',
      santaliOlChiki: 'ᱞᱮᱢᱩᱱ ᱾',
      imageKey: null, // Missing image
    ),
    MasterConcept(
      id: 'gk_fruit_lychee',
      category: 'General Knowledge',
      subcategory: 'Fruits',
      hindi: 'लीची',
      santali: 'ᱞᱤᱪᱤ ᱾',
      santaliOlChiki: 'ᱞᱤᱪᱤ ᱾',
      imageKey: null, // Missing image
    ),

    // ==========================================
    // MATHEMATICS: NUMBERS (20 concepts)
    // ==========================================
    MasterConcept(id: 'math_num_1', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 1', santali: 'ᱢᱤᱫᱴᱟᱝ ᱾', santaliOlChiki: 'ᱢᱤᱫᱴᱟᱝ ᱾'),
    MasterConcept(id: 'math_num_2', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 2', santali: 'ᱟᱭᱢᱟᱜᱟᱱ', santaliOlChiki: 'ᱟᱭᱢᱟᱜᱟᱱ'),
    MasterConcept(id: 'math_num_3', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 3', santali: 'ᱯᱮᱭᱟ ᱾', santaliOlChiki: 'ᱯᱮᱭᱟ ᱾'),
    MasterConcept(id: 'math_num_4', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 4', santali: '4 ᱜᱚᱴᱟᱝ ᱾', santaliOlChiki: '4 ᱜᱚᱴᱟᱝ ᱾'),
    MasterConcept(id: 'math_num_5', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 5', santali: 'ᱢᱚᱬᱮ ᱜᱚᱴᱟᱝ ᱾', santaliOlChiki: 'ᱢᱚᱬᱮ ᱜᱚᱴᱟᱝ ᱾'),
    MasterConcept(id: 'math_num_6', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 6', santali: 'ᱛᱩᱨᱩᱭ ᱜᱚᱴᱟᱝ ᱾', santaliOlChiki: 'ᱛᱩᱨᱩᱭ ᱜᱚᱴᱟᱝ ᱾'),
    MasterConcept(id: 'math_num_7', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 7', santali: 'ᱮᱭᱟᱭ ᱜᱚᱴᱟᱝ ᱾', santaliOlChiki: 'ᱮᱭᱟᱭ ᱜᱚᱴᱟᱝ ᱾'),
    MasterConcept(id: 'math_num_8', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 8', santali: '8 ᱜᱚᱴᱟᱝ ᱾', santaliOlChiki: '8 ᱜᱚᱴᱟᱝ ᱾'),
    MasterConcept(id: 'math_num_9', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 9', santali: 'ᱱᱟᱶᱟ ᱾', santaliOlChiki: 'ᱱᱟᱶᱟ ᱾'),
    MasterConcept(id: 'math_num_10', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 10', santali: 'ᱜᱮᱞ', santaliOlChiki: 'ᱜᱮᱞ'),
    MasterConcept(id: 'math_num_11', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 11', santali: 'ᱜᱮᱞ ᱢᱤᱫ ᱾', santaliOlChiki: 'ᱜᱮᱞ ᱢᱤᱫ ᱾'),
    MasterConcept(id: 'math_num_12', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 12', santali: 'ᱵᱟᱨ ᱜᱚᱴᱟᱝ ᱾', santaliOlChiki: 'ᱵᱟᱨ ᱜᱚᱴᱟᱝ ᱾'),
    MasterConcept(id: 'math_num_13', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 13', santali: 'ᱜᱮᱞ ᱯᱮ ᱾', santaliOlChiki: 'ᱜᱮᱞ ᱯᱮ ᱾'),
    MasterConcept(id: 'math_num_14', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 14', santali: 'ᱜᱮᱞ ᱜᱮᱞ', santaliOlChiki: 'ᱜᱮᱞ ᱜᱮᱞ'),
    MasterConcept(id: 'math_num_15', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 15', santali: 'ᱜᱮᱞ ᱢᱚᱬᱮ', santaliOlChiki: 'ᱜᱮᱞ ᱢᱚᱬᱮ'),
    MasterConcept(id: 'math_num_16', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 16', santali: 'ᱜᱮᱞ ᱩᱱ', santaliOlChiki: 'ᱜᱮᱞ ᱩᱱ'),
    MasterConcept(id: 'math_num_17', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 17', santali: 'ᱜᱮᱞ ᱯᱩᱱ', santaliOlChiki: 'ᱜᱮᱞ ᱯᱩᱱ'),
    MasterConcept(id: 'math_num_18', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 18', santali: 'ᱜᱮᱞ ᱡᱚᱺ', santaliOlChiki: 'ᱜᱮᱞ ᱡᱚᱺ'),
    MasterConcept(id: 'math_num_19', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 19', santali: 'ᱜᱮᱞ ᱟᱬᱟ', santaliOlChiki: 'ᱜᱮᱞ ᱟᱬᱟ'),
    MasterConcept(id: 'math_num_20', category: 'Mathematics', subcategory: 'Numbers', hindi: 'संख्या 20', santali: 'ᱵᱟᱨ ᱜᱮᱞ', santaliOlChiki: 'ᱵᱟᱨ ᱜᱮᱞ'),

    // ==========================================
    // GENERAL KNOWLEDGE: VEGETABLES (8 concepts)
    // ==========================================
    MasterConcept(
      id: 'gk_veg_potato',
      category: 'General Knowledge',
      subcategory: 'Vegetables',
      hindi: 'आलू',
      santali: 'ᱵᱟᱴᱚᱞᱳ ᱾',
      santaliOlChiki: 'ᱵᱟᱴᱚᱞᱳ ᱾',
      imageKey: 'potato',
      pronunciation: 'Aaloo / Batolo',
    ),
    MasterConcept(
      id: 'gk_veg_tomato',
      category: 'General Knowledge',
      subcategory: 'Vegetables',
      hindi: 'टमाटर',
      santali: 'ᱴᱟᱢᱚᱴᱳ ᱾',
      santaliOlChiki: 'ᱴᱟᱢᱚᱴᱳ ᱾',
      imageKey: 'tomato',
      pronunciation: 'Tamatar / Tamoto',
    ),
    MasterConcept(
      id: 'gk_veg_onion',
      category: 'General Knowledge',
      subcategory: 'Vegetables',
      hindi: 'प्याज',
      santali: 'ᱯᱮᱥᱤ ᱾',
      santaliOlChiki: 'ᱯᱮᱥᱤ ᱾',
      imageKey: 'onion',
      pronunciation: 'Pyaaz / Pesi',
    ),
    MasterConcept(
      id: 'gk_veg_carrot',
      category: 'General Knowledge',
      subcategory: 'Vegetables',
      hindi: 'गाजर',
      santali: 'ᱜᱟᱨᱮᱴ ᱾',
      santaliOlChiki: 'ᱜᱟᱨᱮᱴ ᱾',
      imageKey: 'carrot',
      pronunciation: 'Gajar / Garet',
    ),
    MasterConcept(
      id: 'gk_veg_radish',
      category: 'General Knowledge',
      subcategory: 'Vegetables',
      hindi: 'मूली',
      santali: 'ᱢᱩᱲᱩᱫ ᱫᱚ ᱦᱩᱭᱩᱜ ᱠᱟᱱᱟ ᱾',
      santaliOlChiki: 'ᱢᱩᱲᱩᱫ ᱫᱚ ᱦᱩᱭᱩᱜ ᱠᱟᱱᱟ ᱾',
      imageKey: null, // Missing image
    ),
    MasterConcept(
      id: 'gk_veg_brinjal',
      category: 'General Knowledge',
      subcategory: 'Vegetables',
      hindi: 'बैंगन',
      santali: 'ᱵᱮᱝᱜᱚᱱ ᱾',
      santaliOlChiki: 'ᱵᱮᱝᱜᱚᱱ ᱾',
      imageKey: 'brinjal',
      pronunciation: 'Baingan / Bengon',
    ),
    MasterConcept(
      id: 'gk_veg_ladyfinger',
      category: 'General Knowledge',
      subcategory: 'Vegetables',
      hindi: 'भिंडी',
      santali: 'ᱵᱷᱤᱱᱰᱤ ᱾',
      santaliOlChiki: 'ᱵᱷᱤᱱᱰᱤ ᱾',
      imageKey: null, // Missing image
    ),
    MasterConcept(
      id: 'gk_veg_cauliflower',
      category: 'General Knowledge',
      subcategory: 'Vegetables',
      hindi: 'फूलगोभी',
      santali: 'ᱯᱷᱚᱞᱳᱯᱷᱚᱞᱳ ᱾',
      santaliOlChiki: 'ᱯᱷᱚᱞᱳᱯᱷᱚᱞᱳ ᱾',
      imageKey: 'cauliflower',
      pronunciation: 'Phoolgobhi / Pholopholo',
    ),

    // ==========================================
    // LANGUAGE: ALPHABETS (30 concepts)
    // ==========================================
    MasterConcept(id: 'lang_alpha_ol', category: 'Language', subcategory: 'Alphabets', hindi: 'अ (Ol)', santali: 'ᱚ', santaliOlChiki: 'ᱚ', pronunciation: 'a / अ'),
    MasterConcept(id: 'lang_alpha_at', category: 'Language', subcategory: 'Alphabets', hindi: 'त (At)', santali: 'ᱛ', santaliOlChiki: 'ᱛ', pronunciation: 'at / त'),
    MasterConcept(id: 'lang_alpha_ag', category: 'Language', subcategory: 'Alphabets', hindi: 'ग (Ag)', santali: 'ᱜ', santaliOlChiki: 'ᱜ', pronunciation: 'ag / ग'),
    MasterConcept(id: 'lang_alpha_ang', category: 'Language', subcategory: 'Alphabets', hindi: 'ङ (Ang)', santali: 'ᱝ', santaliOlChiki: 'ᱝ', pronunciation: 'ang / ङ'),
    MasterConcept(id: 'lang_alpha_la', category: 'Language', subcategory: 'Alphabets', hindi: 'ल (La)', santali: 'ᱞ', santaliOlChiki: 'ᱞ', pronunciation: 'la / ल'),
    MasterConcept(id: 'lang_alpha_lad', category: 'Language', subcategory: 'Alphabets', hindi: 'आ (Lad)', santali: 'ᱟ', santaliOlChiki: 'ᱟ', pronunciation: 'ad / आ'),
    MasterConcept(id: 'lang_alpha_ak', category: 'Language', subcategory: 'Alphabets', hindi: 'क (Ak)', santali: 'ᱠ', santaliOlChiki: 'ᱠ', pronunciation: 'k / क'),
    MasterConcept(id: 'lang_alpha_al', category: 'Language', subcategory: 'Alphabets', hindi: 'ल (Al)', santali: 'ᱡ', santaliOlChiki: 'ᱡ', pronunciation: 'l / ल'),
    MasterConcept(id: 'lang_alpha_em', category: 'Language', subcategory: 'Alphabets', hindi: 'म (Em)', santali: 'ᱢ', santaliOlChiki: 'ᱢ', pronunciation: 'm / म'),
    MasterConcept(id: 'lang_alpha_aw', category: 'Language', subcategory: 'Alphabets', hindi: 'व (Aw)', santali: 'ᱣ', santaliOlChiki: 'ᱣ', pronunciation: 'w / व'),
    MasterConcept(id: 'lang_alpha_i', category: 'Language', subcategory: 'Alphabets', hindi: 'इ (I)', santali: 'ᱤ', santaliOlChiki: 'ᱤ', pronunciation: 'i / इ'),
    MasterConcept(id: 'lang_alpha_is', category: 'Language', subcategory: 'Alphabets', hindi: 'स (Is)', santali: 'ᱥ', santaliOlChiki: 'ᱥ', pronunciation: 's / स'),
    MasterConcept(id: 'lang_alpha_ah', category: 'Language', subcategory: 'Alphabets', hindi: 'ह (Ah)', santali: 'ᱦ', santaliOlChiki: 'ᱦ', pronunciation: 'h / ह'),
    MasterConcept(id: 'lang_alpha_en', category: 'Language', subcategory: 'Alphabets', hindi: 'न (En)', santali: 'ᱧ', santaliOlChiki: 'ᱧ', pronunciation: 'n / न'),
    MasterConcept(id: 'lang_alpha_ar', category: 'Language', subcategory: 'Alphabets', hindi: 'र (Ar)', santali: 'ᱨ', santaliOlChiki: 'ᱨ', pronunciation: 'r / र'),
    MasterConcept(id: 'lang_alpha_u', category: 'Language', subcategory: 'Alphabets', hindi: 'उ (U)', santali: 'ᱩ', santaliOlChiki: 'ᱩ', pronunciation: 'u / उ'),
    MasterConcept(id: 'lang_alpha_ac', category: 'Language', subcategory: 'Alphabets', hindi: 'च (Ac)', santali: 'ᱪ', santaliOlChiki: 'ᱪ', pronunciation: 'c / च'),
    MasterConcept(id: 'lang_alpha_ad', category: 'Language', subcategory: 'Alphabets', hindi: 'द (Ad)', santali: 'ᱫ', santaliOlChiki: 'ᱫ', pronunciation: 'd / द'),
    MasterConcept(id: 'lang_alpha_eny', category: 'Language', subcategory: 'Alphabets', hindi: 'ञ (Eny)', santali: 'ᱬ', santaliOlChiki: 'ᱬ', pronunciation: 'ny / ञ'),
    MasterConcept(id: 'lang_alpha_ay', category: 'Language', subcategory: 'Alphabets', hindi: 'य (Ay)', santali: 'ᱭ', santaliOlChiki: 'ᱭ', pronunciation: 'y / य'),
    MasterConcept(id: 'lang_alpha_e', category: 'Language', subcategory: 'Alphabets', hindi: 'ए (E)', santali: 'ᱮ', santaliOlChiki: 'ᱮ', pronunciation: 'e / ए'),
    MasterConcept(id: 'lang_alpha_op', category: 'Language', subcategory: 'Alphabets', hindi: 'प (Op)', santali: 'ᱯ', santaliOlChiki: 'ᱯ', pronunciation: 'p / प'),
    MasterConcept(id: 'lang_alpha_ord', category: 'Language', subcategory: 'Alphabets', hindi: 'ड (Ord)', santali: 'ᱰ', santaliOlChiki: 'ᱰ', pronunciation: 'd / ड'),
    MasterConcept(id: 'lang_alpha_an', category: 'Language', subcategory: 'Alphabets', hindi: 'न (An)', santali: 'ᱱ', santaliOlChiki: 'ᱱ', pronunciation: 'n / न'),
    MasterConcept(id: 'lang_alpha_rr', category: 'Language', subcategory: 'Alphabets', hindi: 'ड़ (Rr)', santali: 'ᱲ', santaliOlChiki: 'ᱲ', pronunciation: 'r / ड़'),
    MasterConcept(id: 'lang_alpha_o', category: 'Language', subcategory: 'Alphabets', hindi: 'ओ (O)', santali: 'ᱳ', santaliOlChiki: 'ᱳ', pronunciation: 'o / ओ'),
    MasterConcept(id: 'lang_alpha_ott', category: 'Language', subcategory: 'Alphabets', hindi: 'ट (Ott)', santali: 'ᱴ', santaliOlChiki: 'ᱴ', pronunciation: 't / ट'),
    MasterConcept(id: 'lang_alpha_ob', category: 'Language', subcategory: 'Alphabets', hindi: 'ब (Ob)', santali: 'ᱵ', santaliOlChiki: 'ᱵ', pronunciation: 'b / ब'),
    MasterConcept(id: 'lang_alpha_ang_sub', category: 'Language', subcategory: 'Alphabets', hindi: 'ं (Ang)', santali: 'ᱶ', santaliOlChiki: 'ᱶ', pronunciation: 'ng / ं'),
    MasterConcept(id: 'lang_alpha_ahad', category: 'Language', subcategory: 'Alphabets', hindi: 'ः / ह (Ahad)', santali: 'ᱷ', santaliOlChiki: 'ᱷ', pronunciation: 'h / ः'),
  ];

  /// Get master Flashcard list derived directly from canonical MasterConcepts
  static List<FlashcardItem> get masterFlashcards {
    return concepts.map((c) => c.toFlashcard()).toList();
  }

  /// Get master Games list derived directly from canonical MasterConcepts
  static List<GameItem> get masterGames {
    final animalConcepts = concepts.where((c) => c.subcategory == 'Animals' && c.imageKey != null).toList();
    final fruitConcepts = concepts.where((c) => c.subcategory == 'Fruits' && c.imageKey != null).toList();
    final countingConcepts = concepts.where((c) => c.subcategory == 'Counting').toList();
    final alphabetConcepts = concepts.where((c) => c.subcategory == 'Alphabets').toList();

    return [
      GameItem(
        id: 'gm_master_animals_match',
        category: 'General Knowledge',
        titleHindi: 'जानवर मिलान खेल (Animal Match)',
        titleSantali: 'ᱵᱤᱨᱤᱭᱟᱹ ᱢᱤᱞᱟᱹᱣ (Biriya Milaw)',
        descriptionHindi: 'संताली भाषा में जानवरों के नाम और चित्रों का मिलान करें',
        descriptionSantali: 'ᱱᱚᱶᱟ ᱫᱚ ᱪᱮᱫ ᱵᱤᱨᱤᱭᱟᱹ?',
        gameType: 'match_word_image',
        isAvailableOffline: true,
        isComingSoon: false,
        rawData: {
          'id': 'gm_master_animals_match',
          'items': animalConcepts.map((c) => {
            'id': c.id,
            'hindi': c.hindi,
            'santali': c.santali,
            'imageKey': c.imageKey,
          }).toList(),
        },
      ),
      GameItem(
        id: 'gm_master_fruits_match',
        category: 'General Knowledge',
        titleHindi: 'फल पहचान खेल (Fruit Match)',
        titleSantali: 'ᱯᱷᱚᱞᱮ ᱢᱤᱞᱟᱹᱣ (Phole Milaw)',
        descriptionHindi: 'संताली में फलों के नाम पहचानें',
        descriptionSantali: 'ᱱᱚᱶᱟ ᱫᱚ ᱪᱮᱫ ᱯᱷᱚᱞᱮ?',
        gameType: 'match_word_image',
        isAvailableOffline: true,
        isComingSoon: false,
        rawData: {
          'id': 'gm_master_fruits_match',
          'items': fruitConcepts.map((c) => {
            'id': c.id,
            'hindi': c.hindi,
            'santali': c.santali,
            'imageKey': c.imageKey,
          }).toList(),
        },
      ),
      GameItem(
        id: 'gm_master_counting_game',
        category: 'Mathematics',
        titleHindi: 'संताली गिनती खेल (Counting Game)',
        titleSantali: 'ᱞᱮᱠᱷᱟ ᱮᱱᱮᱡ (Lekha Enej)',
        descriptionHindi: '1 से 20 तक संताली गिनती सीखें',
        descriptionSantali: 'ᱥᱟᱱᱛᱟᱲᱤ ᱞᱮᱠᱷᱟ',
        gameType: 'count_objects',
        isAvailableOffline: true,
        isComingSoon: false,
        rawData: {
          'id': 'gm_master_counting_game',
          'items': countingConcepts.take(10).map((c) => {
            'id': c.id,
            'number': c.hindi,
            'santali': c.santali,
          }).toList(),
        },
      ),
      GameItem(
        id: 'gm_master_olchiki_game',
        category: 'Language',
        titleHindi: 'ऑल चिकी वर्णमाला खेल (Ol Chiki Letter Match)',
        titleSantali: 'ᱚᱞ ᱪᱤᱠᱤ ᱟᱠᱷᱚᱨ ᱮᱱᱮᱡ',
        descriptionHindi: 'ऑल चिकी अक्षरों की पहचान करें',
        descriptionSantali: 'ᱚᱞ ᱪᱤᱠᱤ ᱟᱠᱷᱚᱨ ᱪᱤᱱᱦᱟᱹᱣ',
        gameType: 'letter_matching',
        isAvailableOffline: true,
        isComingSoon: false,
        rawData: {
          'id': 'gm_master_olchiki_game',
          'items': alphabetConcepts.take(15).map((c) => {
            'id': c.id,
            'character': c.santali,
            'name': c.hindi,
          }).toList(),
        },
      ),
    ];
  }

  /// Get master Worksheets list derived directly from canonical MasterConcepts
  static List<WorksheetItem> get masterWorksheets {
    final animalFruitConcepts = concepts
        .where((c) => c.subcategory == 'Animals' || c.subcategory == 'Fruits')
        .take(6)
        .toList();

    final countingConcepts = concepts
        .where((c) => c.subcategory == 'Counting')
        .take(5)
        .toList();

    return [
      WorksheetItem(
        id: 'ws_master_gk',
        titleHindi: 'अभ्यास पत्र: सामान्य ज्ञान (जानवर और फल)',
        titleSantali: 'ᱚᱞ ᱪᱮᱫ: ᱵᱤᱨᱤᱭᱟᱹ ᱟᱨ ᱯᱷᱚᱞᱮ',
        gradeClass: 1,
        subject: 'General Knowledge',
        questions: animalFruitConcepts.map((c) => WorksheetQuestion(
          id: 'wq_${c.id}',
          questionHindi: 'हिंदी में "${c.hindi}" को संताली में क्या कहते हैं?',
          questionSantali: 'ᱱᱚᱶᱟ ᱫᱚ ᱪᱮᱫ?',
          image: c.imageKey,
          optionsHindi: [c.hindi, 'गलत उत्तर 1', 'गलत उत्तर 2'],
          optionsSantali: [c.santali, 'ᱮᱴᱟᱜ', 'ᱵᱟᱹᱱᱩᱜᱼᱟ'],
          correctIndex: 0,
          explanationHindi: '${c.hindi} को संताली में ${c.santali} कहते हैं।',
          explanationSantali: c.santali,
        )).toList(),
      ),
      WorksheetItem(
        id: 'ws_master_math',
        titleHindi: 'अभ्यास पत्र: गणित (गिनती 1-5)',
        titleSantali: 'ᱚᱞ ᱪᱮᱫ: ᱞᱮᱠᱷᱟ (1-5)',
        gradeClass: 1,
        subject: 'Mathematics',
        questions: countingConcepts.map((c) => WorksheetQuestion(
          id: 'wq_${c.id}',
          questionHindi: '${c.hindi} को संताली में क्या कहते हैं?',
          questionSantali: 'ᱞᱮᱠᱷᱟ ᱪᱮᱫ?',
          image: null,
          optionsHindi: [c.hindi, 'अन्य', 'कोई नहीं'],
          optionsSantali: [c.santali, 'ᱮᱴᱟᱜ', 'ᱵᱟᱹᱱᱩᱜᱼᱟ'],
          correctIndex: 0,
          explanationHindi: '${c.hindi} को संताली में ${c.santali} कहते हैं।',
          explanationSantali: c.santali,
        )).toList(),
      ),
    ];
  }
}
