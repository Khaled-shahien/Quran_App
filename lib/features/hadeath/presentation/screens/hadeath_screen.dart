import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pulse_loader.dart';
import '../providers/hadeath_provider.dart';
import '../widgets/hadeath_card.dart';

class HadeathScreen extends StatefulWidget {
  const HadeathScreen({super.key});

  @override
  State<HadeathScreen> createState() => _HadeathScreenState();
}

class _HadeathScreenState extends State<HadeathScreen> {
  @override
  void initState() {
    super.initState();
    // Load Ahadeth when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HadeathProvider>().loadAhadeth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'الأحاديث النبوية',
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
          child: Consumer<HadeathProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: PulseLoader(lines: 6));
              }

              if (provider.errorMessage != null) {
                return Center(
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (provider.ahadethList.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد أحاديث لعرضها',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.secondaryText,
                      fontSize: 18,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: provider.ahadethList.length,
                itemBuilder: (context, index) {
                  final hadeath = provider.ahadethList[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: HadeathCard(
                      title: hadeath.title.isEmpty
                          ? 'الحديث ${index + 1}'
                          : hadeath.title,
                      onTap: () {
                        context.push('/hadeath/details/$index', extra: hadeath);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
