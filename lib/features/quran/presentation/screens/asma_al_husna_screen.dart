import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';

import 'package:sakina_app/features/quran/presentation/widgets/'
    'asma_item_card.dart';

class AsmaAlHusnaScreen extends StatefulWidget {
  const AsmaAlHusnaScreen({super.key});

  @override
  State<AsmaAlHusnaScreen> createState() => _AsmaAlHusnaScreenState();
}

class _AsmaAlHusnaScreenState extends State<AsmaAlHusnaScreen> {
  final List<Map<String, String>> _names = [
    {'number': '1', 'name': 'الرَّحْمٰنُ', 'meaning': 'The Most Gracious'},
    {'number': '2', 'name': 'الرَّحِيمُ', 'meaning': 'The Most Merciful'},
    {'number': '3', 'name': 'الْمَلِكُ', 'meaning': 'The King, The Sovereign'},
    {
      'number': '4',
      'name': 'الْقُدُّوسُ',
      'meaning': 'The Holy One, The Pure One',
    },
    {'number': '5', 'name': 'السَّلَامُ', 'meaning': 'The Source of Peace'},
    {'number': '6', 'name': 'الْمُؤْمِنُ', 'meaning': 'The Guarantor'},
    {
      'number': '7',
      'name': 'الْمُهَيْمِنُ',
      'meaning': 'The Guardian, The Preserver',
    },
    {
      'number': '8',
      'name': 'الْعَزِيزُ',
      'meaning': 'The Almighty, The Self-Sufficient',
    },
    {
      'number': '9',
      'name': 'الْجَبَّارُ',
      'meaning': 'The Compeller, The Restorer',
    },
    {'number': '10', 'name': 'الْمُتَكَبِّرُ', 'meaning': 'The Supreme'},
    {'number': '11', 'name': 'الْخَالِقُ', 'meaning': 'The Creator'},
    {'number': '12', 'name': 'الْبَارِئُ', 'meaning': 'The Maker'},
    {
      'number': '13',
      'name': 'الْمُصَوِّرُ',
      'meaning': 'The Fashioner of Forms',
    },
    {
      'number': '14',
      'name': 'الْغَفَّارُ',
      'meaning': 'The Forgiving, The Ever-Forgiving',
    },
    {
      'number': '15',
      'name': 'الْقَهَّارُ',
      'meaning': 'The Subduer, The Ever-Powerful',
    },
    {'number': '16', 'name': 'الْوَهَّابُ', 'meaning': 'The Bestower'},
    {'number': '17', 'name': 'الرَّزَّاقُ', 'meaning': 'The Provider'},
    {
      'number': '18',
      'name': 'الْفَتَّاحُ',
      'meaning': 'The Opener, The Victory Giver',
    },
    {
      'number': '19',
      'name': 'اَلْعَلِيْمُ',
      'meaning': 'The All-Knowing, The Omniscient',
    },
    {
      'number': '20',
      'name': 'الْقَابِضُ',
      'meaning': 'The Restrainer, The Straightener',
    },
    {
      'number': '21',
      'name': 'الْبَاسِطُ',
      'meaning': 'The Expander, The Munificent',
    },
    {'number': '22', 'name': 'الْخَافِضُ', 'meaning': 'The Abaser'},
    {'number': '23', 'name': 'الرَّافِعُ', 'meaning': 'The Exalter'},
    {'number': '24', 'name': 'الْمُعِزُّ', 'meaning': 'The Giver of Honor'},
    {'number': '25', 'name': 'الذَّلِيلُ', 'meaning': 'The Giver of Dishonor'},
    {'number': '26', 'name': 'السَّمِيعُ', 'meaning': 'The All-Hearing'},
    {'number': '27', 'name': 'الْبَصِيرُ', 'meaning': 'The All-Seeing'},
    {
      'number': '28',
      'name': 'الْحَكَمُ',
      'meaning': 'The Judge, The Arbitrator',
    },
    {'number': '29', 'name': 'الْعَدْلُ', 'meaning': 'The Utterly Just'},
    {'number': '30', 'name': 'اللَّطِيفُ', 'meaning': 'The Subtly Kind'},
    {'number': '31', 'name': 'الْخَبِيرُ', 'meaning': 'The All-Aware'},
    {'number': '32', 'name': 'الْحَلِيمُ', 'meaning': 'The Most Forbearing'},
    {
      'number': '33',
      'name': 'الْعَظِيمُ',
      'meaning': 'The Magnificent, The Infinite',
    },
    {'number': '34', 'name': 'الْغَفُورُ', 'meaning': 'The All-Forgiving'},
    {'number': '35', 'name': 'الشَّكُورُ', 'meaning': 'The Grateful'},
    {'number': '36', 'name': 'الْعَلِيُّ', 'meaning': 'The Most High'},
    {'number': '37', 'name': 'الْكَبِيرُ', 'meaning': 'The Greatest'},
    {'number': '38', 'name': 'الْحَفِيظُ', 'meaning': 'The Preserver'},
    {'number': '39', 'name': 'الْمُقِيتُ', 'meaning': 'The Nourisher'},
    {'number': '40', 'name': 'الْحَسِيبُ', 'meaning': 'The Reckoner'},
    {'number': '41', 'name': 'الْجَلِيلُ', 'meaning': 'The Majestic'},
    {
      'number': '42',
      'name': 'الْكَرِيمُ',
      'meaning': 'The Generous, The Noble',
    },
    {'number': '43', 'name': 'الرَّقِيبُ', 'meaning': 'The Watchful'},
    {
      'number': '44',
      'name': 'الْمُجِيبُ',
      'meaning': 'The Responsive, The Answerer',
    },
    {
      'number': '45',
      'name': 'الْوَاسِعُ',
      'meaning': 'The Vast, The All-Encompassing',
    },
    {'number': '46', 'name': 'الْحَكِيمُ', 'meaning': 'The Wise'},
    {'number': '47', 'name': 'الْوَدُودُ', 'meaning': 'The Loving'},
    {'number': '48', 'name': 'الْمَجِيدُ', 'meaning': 'The Glorious'},
    {'number': '49', 'name': 'الْبَاعِثُ', 'meaning': 'The Raiser'},
    {'number': '50', 'name': 'الشَّهِيدُ', 'meaning': 'The Witness'},
    {'number': '51', 'name': 'الْحَقُّ', 'meaning': 'The Truth, The Real'},
    {
      'number': '52',
      'name': 'الْوَكِيلُ',
      'meaning': 'The Trustee, The Dependable',
    },
    {'number': '53', 'name': 'الْقَوِيُّ', 'meaning': 'The Strong'},
    {
      'number': '54',
      'name': 'الْمَتِينُ',
      'meaning': 'The Firm, The Steadfast',
    },
    {
      'number': '55',
      'name': 'الْوَلِيُّ',
      'meaning': 'The Protecting Friend, Patron',
    },
    {'number': '56', 'name': 'الْحَمِيدُ', 'meaning': 'The All-Praiseworthy'},
    {
      'number': '57',
      'name': 'الْمُحْصِي',
      'meaning': 'The Accounter, The Numberer of All',
    },
    {
      'number': '58',
      'name': 'الْمُبْدِئُ',
      'meaning': 'The Producer, Originator',
    },
    {
      'number': '59',
      'name': 'الْمُعِيدُ',
      'meaning': 'The Reinstater Who Brings Back All',
    },
    {'number': '60', 'name': 'الْمُحْيِي', 'meaning': 'The Giver of Life'},
    {
      'number': '61',
      'name': 'الْمُمِيتُ',
      'meaning': 'The Bringer of Death, The Destroyer',
    },
    {'number': '62', 'name': 'الْحَيُّ', 'meaning': 'The Ever-Living'},
    {
      'number': '63',
      'name': 'الْقَيُّومُ',
      'meaning': 'The Self-Subsisting Sustainer of All',
    },
    {
      'number': '64',
      'name': 'الْوَاجِدُ',
      'meaning': 'The Perceiver, The Finder',
    },
    {
      'number': '65',
      'name': 'الْمَاجِدُ',
      'meaning': 'The Illustrious, The Magnificent',
    },
    {'number': '66', 'name': 'الْواحِدُ', 'meaning': 'The One'},
    {
      'number': '67',
      'name': 'الْأَحَدُ',
      'meaning': 'The Unique, The Only One',
    },
    {
      'number': '68',
      'name': 'الصَّمَدُ',
      'meaning': 'The Eternal, The Absolute',
    },
    {'number': '69', 'name': 'الْقَادِرُ', 'meaning': 'The Powerful'},
    {'number': '70', 'name': 'الْمُقْتَدِرُ', 'meaning': 'The Almighty'},
    {
      'number': '71',
      'name': 'الْمُقَدِّمُ',
      'meaning': 'The Expediter, He Who Brings Forward',
    },
    {
      'number': '72',
      'name': 'الْمُؤَخِّرُ',
      'meaning': 'The Delayer, He Who Puts Farther Off',
    },
    {'number': '73', 'name': 'الْأَوَّلُ', 'meaning': 'The First'},
    {'number': '74', 'name': 'الْآخِرُ', 'meaning': 'The Last'},
    {'number': '75', 'name': 'الظَّاهِرُ', 'meaning': 'The Manifest'},
    {'number': '76', 'name': 'الْبَاطِنُ', 'meaning': 'The Hidden'},
    {
      'number': '77',
      'name': 'الْوَالِي',
      'meaning': 'The Governor, The Patron',
    },
    {'number': '78', 'name': 'الْمُتَعَالِي', 'meaning': 'The Self-Exalted'},
    {
      'number': '79',
      'name': 'الْبَرُّ',
      'meaning': 'The Most Kind and Righteous',
    },
    {
      'number': '80',
      'name': 'التَّوَابُ',
      'meaning': 'The Ever-Returning, Accepter of Repentance',
    },
    {'number': '81', 'name': 'الْمُنْتَقِمُ', 'meaning': 'The Avenger'},
    {
      'number': '82',
      'name': 'العَفُوُّ',
      'meaning': 'The Pardoner, The Effacer of Sins',
    },
    {'number': '83', 'name': 'الرَّءُوفُ', 'meaning': 'The Compassionate'},
    {
      'number': '84',
      'name': 'مالكُ الْمُلْكِ',
      'meaning': 'The Owner of All Sovereignty',
    },
    {
      'number': '85',
      'name': 'ذُو الْجَلالِ وَالإِكْرَامِ',
      'meaning': 'The Lord of Majesty and Generosity',
    },
    {
      'number': '86',
      'name': 'الْمُقْسِطُ',
      'meaning': 'The Equitable, The Requiter',
    },
    {
      'number': '87',
      'name': 'الْجَامِعُ',
      'meaning': 'The Gatherer, The Unifier',
    },
    {
      'number': '88',
      'name': 'الْغَنِيُّ',
      'meaning': 'The Rich, The Independent',
    },
    {'number': '89', 'name': 'الْمُغْنِي', 'meaning': 'The Enricher'},
    {'number': '90', 'name': 'الْمَانِعُ', 'meaning': 'The Preventer of Harm'},
    {
      'number': '91',
      'name': 'الضَّارُّ',
      'meaning': 'The Creator of Benefit and Harm',
    },
    {'number': '92', 'name': 'النَّافِعُ', 'meaning': 'The Beneficent'},
    {'number': '93', 'name': 'النُّورُ', 'meaning': 'The Light'},
    {'number': '94', 'name': 'الْهَادِي', 'meaning': 'The Guide'},
    {
      'number': '95',
      'name': 'الْبَدِيعُ',
      'meaning': 'The Incomparable, The Originator',
    },
    {
      'number': '96',
      'name': 'الْبَاقِي',
      'meaning': 'The Ever-During, The Immutable',
    },
    {
      'number': '97',
      'name': 'الْوَارِثُ',
      'meaning': 'The Inheritor, The Heir',
    },
    {
      'number': '98',
      'name': 'الرَّشِيدُ',
      'meaning': 'The Guide, Infallible Teacher',
    },
    {'number': '99', 'name': 'الصَّبُورُ', 'meaning': 'The Patient'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10nOf(context).asmaAlHusnaScreenMessage1,
          style: TextStyle(
            fontFamily: 'Cairo',
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: l10nOf(context).appStringsMessage13,
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.8,
              ),
              itemCount: _names.length,
              itemBuilder: (context, index) {
                return AsmaItemCard(
                  number: _names[index]['number']!,
                  arabicName: _names[index]['name']!,
                  meaning: _names[index]['meaning']!,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
