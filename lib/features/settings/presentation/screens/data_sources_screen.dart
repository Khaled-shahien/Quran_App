import 'package:flutter/material.dart';

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
                'تُحفظ المفضلة والعلامات والختمة والإعدادات محلياً. مسح بيانات التطبيق من إعدادات النظام يزيل البيانات المحلية. خدمات Firebase والإشعارات والمحتوى الخارجي قد تتلقى بيانات الاتصال. حذف البيانات المحلية لا يعني حذف سجلات الخدمات الخارجية أو النسخ الاحتياطية.',
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
            ],
          ),
        ),
      ),
    ),
  );
}
