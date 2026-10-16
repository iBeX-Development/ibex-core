import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/widgets/back_arrow.dart';
import '../widgets/html_widget.dart';
import '../../../src/generated/i18n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final String title;
  final String from;

  const PrivacyPolicyScreen({
    super.key,
    required this.title,
    required this.from,
  });

  static const String privacyPolicyContentEn = '''
<style>
  h4 { margin-bottom: 8px; margin-top: 16px; }
  p { margin-top: -8px; }
  ul { margin-top: 8px; }
</style>
<p><strong>Last updated:</strong> April 5, 2026</p>

<p>Welcome to IBEX (demo.ibex.mn). Your privacy is important to us. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our website.</p>

<h4>1. INFORMATION WE COLLECT</h4>
<p>We may collect information about you in a variety of ways, including:</p>
<ul>
  <li><strong>Personal Data:</strong> Name, email address, phone number, company name, and other information you voluntarily provide.</li>
  <li><strong>Usage Data:</strong> Information automatically collected when you access the website, such as IP address, browser type, pages visited, and time spent.</li>
  <li><strong>Cookies and Tracking Technologies:</strong> We use cookies to enhance user experience.</li>
</ul>

<h4>2. HOW WE USE YOUR INFORMATION</h4>
<p>We use the information we collect to:</p>
<ul>
  <li>Provide, operate, and maintain our services</li>
  <li>Improve user experience</li>
  <li>Communicate with you</li>
  <li>Send updates, marketing, and promotional materials</li>
  <li>Ensure security and prevent fraud</li>
</ul>

<h4>3. SHARING YOUR INFORMATION</h4>
<p>We do not sell your personal data. We may share information with:</p>
<ul>
  <li>Service providers and partners</li>
  <li>Legal authorities if required by law</li>
  <li>Business transfers in case of merger or acquisition</li>
</ul>

<h4>4. DATA SECURITY</h4>
<p>We use administrative, technical, and physical security measures to protect your information. However, no system is completely secure.</p>

<h4>5. YOUR RIGHTS</h4>
<p>Depending on your location, you may have the right to:</p>
<ul>
  <li>Access your data</li>
  <li>Request correction or deletion</li>
  <li>Withdraw consent</li>
</ul>

<h4>6. THIRD-PARTY LINKS</h4>
<p>Our website may contain links to third-party websites. We are not responsible for their privacy practices.</p>

<h4>7. CHANGES TO THIS POLICY</h4>
<p>We may update this Privacy Policy from time to time. Updates will be posted on this page.</p>

<h4>8. CONTACT US</h4>
<ul>
  <li><strong>Email:</strong> admin@ibex.mn</li>
  <li><strong>Website:</strong> demo.ibex.mn</li>
</ul>
''';

  static const String privacyPolicyContentMn = '''
<style>
  h4 { margin-bottom: 8px; margin-top: 16px; }
  p { margin-top: -8px; }
  ul { margin-top: 8px; }
</style>
<p><strong>Шинэчилсэн огноо:</strong> 2026 оны 4-р сарын 5</p>

<p>IBEX (demo.ibex.mn) сайтад тавтай морилно уу. Таны нууцлал бидэнд чухал. Энэхүү Нууцлалын Бодлого нь манай вэбсайтад зочлоход таны мэдээллийг хэрхэн цуглуулах, ашиглах, задруулах, хамгаалах талаар тайлбарлана.</p>

<h4>1. БИДНИЙ ЦУГЛУУЛДАГ МЭДЭЭЛЭЛ</h4>
<p>Бид таны талаар олон янзаар мэдээлэл цуглуулж болно:</p>
<ul>
  <li><strong>Хувийн мэдээлэл:</strong> Нэр, имэйл хаяг, утасны дугаар, компанийн нэр болон бусад өөрөө өгсөн мэдээлэл.</li>
  <li><strong>Ашиглалтын мэдээлэл:</strong> Вэбсайтад нэвтрэх үед автоматаар цуглуулагдах мэдээлэл, тухайлбал IP хаяг, хөтөч төрөл, зочилсон хуудас, зарцуулсан цаг.</li>
  <li><strong>Күүки болон хяналтын технологи:</strong> Бид хэрэглэгчийн туршлагыг сайжруулахын тулд күүки ашигладаг.</li>
</ul>

<h4>2. ТАНЫ МЭДЭЭЛЛИЙГ ХЭРХЭН АШИГЛАДАГ ВЭ</h4>
<p>Бид цуглуулсан мэдээллээ дараах зорилгоор ашигладаг:</p>
<ul>
  <li>Үйлчилгээгээ нийлүүлэх, ажиллуулах, засвар үйлчилгээ хийх</li>
  <li>Хэрэглэгчийн туршлагыг сайжруулах</li>
  <li>Тантай харилцах</li>
  <li>Шинэчлэлт, маркетинг, сурталчилгааны материал илгээх</li>
  <li>Аюулгүй байдлыг хангах, залилан луйвруулалтаас урьдчилан сэргийлэх</li>
</ul>

<h4>3. ТАНЫ МЭДЭЭЛЛИЙГ ХУВААЛЦАХ</h4>
<p>Бид таны хувийн мэдээллийг зарахгүй. Бид мэдээллийг дараах талуудтай хуваалцаж болно:</p>
<ul>
  <li>Үйлчилгээ үзүүлэгчид болон түншүүд</li>
  <li>Хууль ёсны байгууллагууд (хуулиар шаардсан тохиолдолд)</li>
  <li>Нэгдэх, худалдан авалтын тохиолдолд бизнесийн шилжүүлэг</li>
</ul>

<h4>4. ӨГӨГДЛИЙН АЮУЛГҮЙ БАЙДАЛ</h4>
<p>Бид таны мэдээллийг хамгаалахын тулд захиргааны, техникийн, физик хамгаалалтын арга хэмжээ авдаг. Гэсэн хэдий ч ямар ч систем бүрэн найдвартай байж чадахгүй.</p>

<h4>5. ТАНЫ ЭРХ</h4>
<p>Таны байршлаас хамааран та дараах эрхтэй байж болно:</p>
<ul>
  <li>Өөрийн өгөгдөлдөө хандах</li>
  <li>Засварлах эсвэл устгахыг хүсэх</li>
  <li>Зөвшөөрлөө буцаан тат</li>
</ul>

<h4>6. ГУРАВДАГЧ ТАЛЫН ХОЛБООСУУД</h4>
<p>Манай вэбсайтад гуравдагч талын вэбсайт руу холбоос байж болно. Бид тэдний нууцлалын практикт хариуцлага хүлээхгүй.</p>

<h4>7. БОДЛОГЫН ӨӨРЧЛӨЛТ</h4>
<p>Бид энэхүү Нууцлалын Бодлогыг үе үе шинэчилж болно. Шинэчлэлтийг энэ хуудсанд нийтлэнэ.</p>

<h4>8. ХОЛБОО БАРИХ</h4>
<ul>
  <li><strong>Имэйл:</strong> admin@ibex.mn</li>
  <li><strong>Вэбсайт:</strong> demo.ibex.mn</li>
</ul>
''';

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final content = locale.languageCode == 'mn'
        ? privacyPolicyContentMn
        : privacyPolicyContentEn;

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
                title: AppLocalizations.of(context)!.privacypolicy,
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
