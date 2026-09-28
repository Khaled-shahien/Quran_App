import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class DataSourcesScreen extends StatelessWidget {
  const DataSourcesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الخصوصية ومصادر المحتوى')),
    body: const SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الموقع والمواقيت',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'تُحفظ إحداثيات موقع الصلاة وطريقة الحساب على الجهاز، وتُرسل إلى خدمة Aladhan لجلب المواقيت. يمكنك تعديلها من شاشة الصلاة. تستخدم القبلة إذن الموقع لحساب الاتجاه. يمكن إلغاء الإذن من إعدادات الجهاز.',
              ),
              SizedBox(height: 24),
              Text(
                'البيانات والتذكيرات',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'تُحفظ المفضلة والعلامات والختمة والإعدادات محلياً. مسح بيانات التطبيق من إعدادات النظام يزيل البيانات المحلية. التذكيرات محلية ولا تحتاج خدمة رسائل عن بُعد. عند إتاحة تقارير الأعطال والاستخدام يمكنك اختيار تفعيلها أو إيقافها من الإعدادات؛ لا نضيف الموقع أو البحث أو سجل القراءة إلى هذه التقارير. قد تتلقى الخدمات الخارجية بيانات الاتصال. حذف البيانات المحلية لا يعني حذف سجلات الخدمات الخارجية أو النسخ الاحتياطية.',
              ),
              SizedBox(height: 24),
              Text(
                'مصادر المحتوى',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'القرآن والأحاديث والأدعية متاحة ضمن ملفات التطبيق للعمل دون اتصال. توثيق الطبعة والمصدر والترخيص واعتماد المراجعة لكل مجموعة لم يكتمل بعد. بصمات سلامة الملفات تكشف التغييرات ولا تُعد توثيقاً شرعياً للمحتوى.',
              ),
              SizedBox(height: 24),
              Text('صوت تنبيه الصلاة الحالي هو صوت النظام الافتراضي.'),
              SizedBox(height: 24),
              Text(
                'إحداثيات المدن: GeoNames عبر Open-Meteo، بترخيص CC BY 4.0. الإحداثيات لمراكز المدن ويمكن تعديلها يدوياً.',
              ),
              SizedBox(height: 24),
              ContentProvenanceView(),
            ],
          ),
        ),
      ),
    ),
  );
}

class ContentProvenanceView extends StatefulWidget {
  const ContentProvenanceView({super.key});
  @override
  State<ContentProvenanceView> createState() => _ContentProvenanceViewState();
}

class _ContentProvenanceViewState extends State<ContentProvenanceView> {
  late final Future<String> manifest = rootBundle.loadString(
    'content_manifest.json',
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: manifest,
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Text('تعذر تحميل سجل مصادر المحتوى.');
      if (!snapshot.hasData) return const LinearProgressIndicator();
      final collections =
          (jsonDecode(snapshot.data!) as Map<String, dynamic>)['collections']
              as List;
      return ExpansionTile(
        title: const Text('سجل توثيق المحتوى'),
        children: [
          for (final collection in collections)
            ListTile(
              title: Text(
                collection['path'] as String,
                textDirection: TextDirection.ltr,
              ),
              subtitle: Text(
                collection['source'] == 'pending_owner_review'
                    ? 'المصدر والطبعة والترخيص: بانتظار المراجعة'
                    : collection['source'] as String,
              ),
            ),
        ],
      );
    },
  );
}
