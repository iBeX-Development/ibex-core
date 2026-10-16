import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../src/generated/i18n/app_localizations.dart';
import '../../utils/widgets/back_arrow.dart';
import '../widgets/html_widget.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  static const String termsAndConditionsContentEn = '''
<style>
  h4 { margin-bottom: 8px; margin-top: 16px; }
  p { margin-top: -8px; }
  ul { margin-top: 8px; }
</style>
<p><strong>Last Updated:</strong> April 5, 2026</p>

<p>Welcome to demo.ibex.mn ("we", "our", "us"). These Terms and Conditions ("Terms") govern your access to and use of our website, software platform, and related services (collectively, the "Services").</p>

<p>By accessing or using our Services, you agree to be bound by these Terms. If you do not agree, please do not use our Services.</p>

<h4>1. Use of Services</h4>
<p>You agree to use the Services only for lawful purposes and in accordance with these Terms. You must not:</p>
<ul>
  <li>Violate any applicable laws or regulations</li>
  <li>Interfere with system security or functionality</li>
  <li>Attempt unauthorized access to the platform</li>
</ul>

<h4>2. Account Registration</h4>
<p>To access certain features, you may be required to create an account.</p>
<p>You agree to:</p>
<ul>
  <li>Provide accurate and complete information</li>
  <li>Maintain the confidentiality of your credentials</li>
  <li>Be responsible for all activities under your account</li>
</ul>
<p>We reserve the right to suspend or terminate accounts that provide false information or violate these Terms.</p>

<h4>3. Services Description</h4>
<p>demo.ibex.mn provides digital solutions including (but not limited to):</p>
<ul>
  <li>Asset management systems</li>
  <li>Maintenance tracking (CMMS)</li>
  <li>IoT integration and analytics</li>
</ul>
<p>We may update, modify, or discontinue any part of the Services at any time without prior notice.</p>

<h4>4. Subscription, Pricing, and Payments</h4>
<ul>
  <li>Some Services may require payment or subscription</li>
  <li>Pricing may change at any time with reasonable notice</li>
  <li>Payments are non-refundable unless otherwise stated</li>
  <li>Failure to pay may result in suspension or termination of Services</li>
</ul>

<h4>5. Intellectual Property</h4>
<p>All content, software, and materials on the platform are owned by IBEX or its licensors and are protected by intellectual property laws.</p>
<p>You may not:</p>
<ul>
  <li>Copy, distribute, or modify content without permission</li>
  <li>Reverse engineer or attempt to extract source code</li>
</ul>

<h4>6. Data and Privacy</h4>
<p>Your use of the Services is also governed by our Privacy Policy.</p>
<p>You retain ownership of your data, but you grant us the right to:</p>
<ul>
  <li>Process and store data to provide Services</li>
  <li>Improve system performance and features</li>
</ul>

<h4>7. Service Availability</h4>
<p>We strive to ensure uptime and reliability but do not guarantee uninterrupted access.</p>
<p>We are not responsible for:</p>
<ul>
  <li>Downtime due to maintenance</li>
  <li>System failures or external disruptions</li>
</ul>

<h4>8. Limitation of Liability</h4>
<p>To the fullest extent permitted by law:</p>
<p>We shall not be liable for:</p>
<ul>
  <li>Indirect or consequential damages</li>
  <li>Loss of data, revenue, or business</li>
</ul>
<p>Our total liability shall not exceed the amount paid by you for the Services.</p>

<h4>9. Termination</h4>
<p>We may suspend or terminate your access:</p>
<ul>
  <li>If you violate these Terms</li>
  <li>For security or operational reasons</li>
</ul>
<p>You may stop using the Services at any time.</p>

<h4>10. Third-Party Services</h4>
<p>Our platform may integrate with third-party systems (e.g., IoT devices, APIs). We are not responsible for their performance or policies.</p>

<h4>11. Changes to Terms</h4>
<p>We reserve the right to update these Terms at any time. Updates will be posted on this page.</p>
<p>Continued use of the Services means you accept the updated Terms.</p>

<h4>12. Governing Law</h4>
<p>These Terms shall be governed by and interpreted in accordance with the laws of Mongolia.</p>

<h4>13. Contact Information</h4>
<p>If you have any questions regarding these Terms, please contact us:</p>
<ul>
  <li>Email: admin@ibex.mn</li>
  <li>Website: demo.ibex.mn</li>
</ul>
''';

  static const String termsAndConditionsContentMn = '''
<style>
  h4 { margin-bottom: 8px; margin-top: 16px; }
  p { margin-top: -8px; }
  ul { margin-top: 8px; }
</style>
<p><strong>Шинэчилсэн огноо:</strong> 2026 оны 4-р сарын 5</p>

<p>demo.ibex.mn ("бид", "манай", "биднийх") сайтад тавтай морилно уу. Энэхүү Үйлчилгээний Нөхцөл ("Нөхцөл") нь манай вэбсайт, программ хангамж болон холбогдох үйлчилгээнүүдэд ("Үйлчилгээ") хандах, ашиглахтай холбоотой журмыг тогтооно.</p>

<p>Та манай Үйлчилгээг ашигласнаар эдгээр Нөхцлийг хүлээн зөвшөөрч байна. Хэрэв та зөвшөөрөхгүй бол Үйлчилгээг ашиглахгүй байна уу.</p>

<h4>1. Үйлчилгээний Ашиглалт</h4>
<p>Та Үйлчилгээг зөвхөн хууль ёсны зориулалтаар, эдгээр Нөхцлийн дагуу ашиглахыг зөвшөөрч байна. Та дараах зүйлийг хийж болохгүй:</p>
<ul>
  <li>Хууль тогтоомжийг зөрчих</li>
  <li>Системийн аюулгүй байдал, үйл ажиллагаанд саад учруулах</li>
  <li>Зөвшөөрөлгүй нэвтрэх оролдлого хийх</li>
</ul>

<h4>2. Бүртгэл</h4>
<p>Зарим функцийг ашиглахын тулд бүртгэл үүсгэх шаардлагатай.</p>
<p>Та дараах зүйлийг хүлээн зөвшөөрч байна:</p>
<ul>
  <li>Үнэн зөв мэдээлэл өгөх</li>
  <li>Нууц үгээ нууцлах</li>
  <li>Өөрийн бүртгэлээр хийгдсэн бүх үйлдлийг хариуцах</li>
</ul>
<p>Бид худал мэдээлэл өгсөн эсвэл Нөхцлийг зөрчсөн бүртгэлийг түдгэлзүүлэх эсвэл цуцлах эрхтэй.</p>

<h4>3. Үйлчилгээний Тодорхойлолт</h4>
<p>demo.ibex.mn дараах дижитал шийдлүүдийг санал болгоно:</p>
<ul>
  <li>Хөрөнгийн удирдлагын систем</li>
  <li>Засвар үйлчилгээний хяналт (CMMS)</li>
  <li>IoT интеграц болон аналитик</li>
</ul>
<p>Бид Үйлчилгээний аль ч хэсгийг урьдчилан мэдэгдэлгүйгээр шинэчлэх, өөрчлөх эсвэл зогсоох эрхтэй.</p>

<h4>4. Захиалга, Үнэ, Төлбөр</h4>
<ul>
  <li>Зарим үйлчилгээ төлбөртэй эсвэл захиалгатай байж болно</li>
  <li>Үнэ нь хэдийд ч өөрчлөгдөж болно</li>
  <li>Төлбөр буцаагдахгүй (тусгайлан заагаагүй бол)</li>
  <li>Төлбөр төлөөгүй тохиолдолд үйлчилгээ түдгэлзэж эсвэл цуцлагдана</li>
</ul>

<h4>5. Оюуны Өмч</h4>
<p>Бүх контент, програм, материал нь IBEX эсвэл лицензийн эзэмшигчдийн өмч бөгөөд оюуны өмчийн хуулиар хамгаалагдсан.</p>
<p>Та дараах зүйлийг хийж болохгүй:</p>
<ul>
  <li>Зөвшөөрөлгүй контент хуулах, түгээх, өөрчлөх</li>
  <li>Програмыг задлах эсвэл эх кодыг гаргаж авах оролдлого хийх</li>
</ul>

<h4>6. Өгөгдөл болон Нууцлал</h4>
<p>Таны үйлчилгээний ашиглалт нь манай Нууцлалын Бодлогоор зохицуулагдана.</p>
<p>Та өөрийн өгөгдлийн эзэмшигчээр үлдэх боловч бидэнд дараах эрхийг олгоно:</p>
<ul>
  <li>Үйлчилгээ үзүүлэхийн тулд өгөгдлийг боловсруулах, хадгалах</li>
  <li>Системийн гүйцэтгэл, функцийг сайжруулах</li>
</ul>

<h4>7. Үйлчилгээний Хүртээмж</h4>
<p>Бид тасралтгүй үйлчилгээ үзүүлэхийг эрмэлзэх боловч баталгаажуулж чадахгүй.</p>
<p>Бид дараах зүйлд хариуцлага хүлээхгүй:</p>
<ul>
  <li>Засвар үйлчилгээний улмаас үүссэн тасалдал</li>
  <li>Системийн доголдол эсвэл гадны саад</li>
</ul>

<h4>8. Хариуцлагын Хязгаарлалт</h4>
<p>Хуулиар зөвшөөрөгдсөн хамгийн дээд хэмжээгээр:</p>
<p>Бид дараах зүйлд хариуцлага хүлээхгүй:</p>
<ul>
  <li>Шууд бус эсвэл дагалдан үүссэн хохирол</li>
  <li>Өгөгдөл, орлого, бизнесийн алдагдал</li>
</ul>
<p>Манай нийт хариуцлага таны төлсөн дүнгээс хэтрэхгүй.</p>

<h4>9. Цуцлалт</h4>
<p>Бид таны хандалтыг түдгэлзүүлэх эсвэл цуцлах эрхтэй:</p>
<ul>
  <li>Хэрэв та эдгээр Нөхцлийг зөрчвөл</li>
  <li>Аюулгүй байдал эсвэл үйл ажиллагааны шалтгаанаар</li>
</ul>
<p>Та хүссэн үедээ Үйлчилгээг ашиглахаа зогсоож болно.</p>

<h4>10. Гуравдагч Талын Үйлчилгээ</h4>
<p>Манай платформ нь гуравдагч талын системүүдтэй (жнь IoT төхөөрөмж, API) холбогдож болно. Бид тэдгээрийн гүйцэтгэл, бодлогод хариуцлага хүлээхгүй.</p>

<h4>11. Нөхцлийн Өөрчлөлт</h4>
<p>Бид эдгээр Нөхцлийг хэдийд ч шинэчлэх эрхтэй. Шинэчлэлтийг энэ хуудсанд нийтлэнэ.</p>
<p>Үйлчилгээг үргэлжлүүлэн ашиглах нь та шинэчилсэн Нөхцлийг хүлээн зөвшөөрч байгааг илэрхийлнэ.</p>

<h4>12. Хууль Эрх Зүй</h4>
<p>Эдгээр Нөхцөл нь Монгол Улсын хуулиар зохицуулагдана.</p>

<h4>13. Холбоо Барих</h4>
<p>Эдгээр Нөхцөлтэй холбоотой асуулт байвал бидэнтэй холбогдоно уу:</p>
<ul>
  <li>Имэйл: admin@ibex.mn</li>
  <li>Вэбсайт: demo.ibex.mn</li>
</ul>
''';

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final content = locale.languageCode == 'mn'
        ? termsAndConditionsContentMn
        : termsAndConditionsContentEn;

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
                title: AppLocalizations.of(context)!.termsandconditions,
              ),
              SizedBox(height: 20.h),
              htmlWidget(content, context),
            ],
          ),
        ),
      ),
    );
  }
}
