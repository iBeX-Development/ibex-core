import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../src/generated/i18n/app_localizations.dart';
import '../../utils/widgets/back_arrow.dart';
import '../widgets/html_widget.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const String aboutUsContentEn = '''
<style>
  h4 { margin-bottom: 8px; margin-top: 16px; }
  ul { margin-top: 8px; }
  .content-box { border: 1px solid #e0e0e0; padding: 16px; border-radius: 8px; margin-bottom: 16px; }
</style>
<h2>IBEX</h2>
<p>IBEX is a technology company dedicated to developing smart digital solutions that enhance operational efficiency and productivity for organizations. We empower businesses with modern tools for maintenance management, asset tracking, workflow automation, and data-driven decision-making.</p>

<h3>Our Mission</h3>
<p>Our mission is to simplify daily operations, reduce costs, and improve overall performance by delivering intelligent and scalable platforms.</p>

<h3>What We Offer</h3>
<ul>
  <li>CMMS (Computerized Maintenance Management System)</li>
  <li>IoT-based monitoring and diagnostics</li>
  <li>Predictive maintenance solutions</li>
  <li>Reporting and analytics systems</li>
  <li>Service and work order management</li>
</ul>

<h3>Why IBEX?</h3>
<ul>
  <li>User-friendly and flexible system</li>
  <li>Solutions tailored for the local market</li>
  <li>Data-driven insights for better decisions</li>
  <li>Reliable support and continuous development</li>
</ul>

<h3>Our Values</h3>
<ul>
  <li>Innovation</li>
  <li>Reliability</li>
  <li>Customer-centric approach</li>
  <li>Continuous improvement</li>
</ul>

<p>IBEX strives to be a trusted technology partner that supports your organization's growth and long-term success.</p>

<h3>Contact Us</h3>
<ul>
  <li>Email: admin@ibex.mn</li>
  <li>Website: demo.ibex.mn</li>
  <li>Phone: +976 88087719</li>
</ul>
''';

  static const String aboutUsContentMn = '''
<style>
  h4 { margin-bottom: 8px; margin-top: 16px; }
  ul { margin-top: 8px; }
  .content-box { border: 1px solid #e0e0e0; padding: 16px; border-radius: 8px; margin-bottom: 16px; }
</style>
<h2>IBEX</h2>
<p>IBEX нь байгууллагуудын үйл ажиллагааны үр ашиг, бүтээмжийг дээшлүүлэх ухаалаг дижитал шийдлүүдийг хөгжүүлэхэд зориулагдсан технологийн компани юм. Бид бизнесүүдийг засвар үйлчилгээний удирдлага, хөрөнгийн хяналт, ажлын урсгалын автоматжуулалт болон өгөгдөлд суурилсан шийдвэр гаргалтын орчин үеийн хэрэгслүүдээр хангадаг.</p>

<h3>Манай Эрхэм Зорилго</h3>
<p>Манай зорилго бол ухаалаг, өргөжих боломжтой платформуудыг нийлүүлж, өдөр тутмын үйл ажиллагааг хялбарчлах, зардлыг бууруулах, ерөнхий гүйцэтгэлийг сайжруулах явдал юм.</p>

<h3>Бидний Санал Болгож Буй Зүйлс</h3>
<ul>
  <li>CMMS (Засвар Үйлчилгээний Удирдлагын Систем)</li>
  <li>IoT дээр суурилсан хяналт, оношлогоо</li>
  <li>Урьдчилан таамаглах засварын шийдлүүд</li>
  <li>Тайлагналт болон шинжилгээний системүүд</li>
  <li>Үйлчилгээ болон ажлын захиалгын удирдлага</li>
</ul>

<h3>Яагаад IBEX вэ?</h3>
<ul>
  <li>Хэрэглэгчдэд ээлтэй, уян хатан систем</li>
  <li>Орон нутгийн зах зээлд тохирсон шийдлүүд</li>
  <li>Өгөгдөлд суурилсан илүү сайн шийдвэр</li>
  <li>Найдвартай дэмжлэг, тасралтгүй хөгжил</li>
</ul>

<h3>Бидний Үнэт Зүйлс</h3>
<ul>
  <li>Инноваци</li>
  <li>Найдвартай байдал</li>
  <li>Хэрэглэгчид төвлөрсөн хандлага</li>
  <li>Тасралтгүй сайжруулалт</li>
</ul>

<p>IBEX нь танай байгууллагын өсөлт, урт хугацааны амжилтыг дэмжих итгэмжлэгдсэн технологийн түнш байхыг эрмэлздэг.</p>

<h3>Холбоо Барих</h3>
<ul>
  <li>Имэйл: admin@ibex.mn</li>
  <li>Вэбсайт: demo.ibex.mn</li>
  <li>Утас: +976 88087719</li>
</ul>
''';

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final content =
        locale.languageCode == 'mn' ? aboutUsContentMn : aboutUsContentEn;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        child: SingleChildScrollView(
          child: Column(
            children: [
              BackArrow(
                isPen: false,
                iSBackArrow: true,
                fromDash: false,
                title: AppLocalizations.of(context)!.aboutus,
              ),
              SizedBox(height: 20.h),
              htmlWidget(content, context),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
