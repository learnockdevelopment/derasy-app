import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class AppTranslations extends Translations {
  static Map<String, String> _enUs = {};
  static Map<String, String> _arSa = {};

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': _enUs,
        'ar_SA': _arSa,
      };

  static Future<void> loadTranslations() async {
    try {
      // Load English translations
      String enJson =
          await rootBundle.loadString('assets/translations/en-US.json');
      Map<String, dynamic> enData = json.decode(enJson) as Map<String, dynamic>;
      _enUs = enData.cast<String, String>();
      
      // Inject custom teacher application keys
      _enUs['recent_jobs'] = 'Recent Jobs';
      _enUs['other_jobs'] = 'Other Jobs';
      _enUs['cv_profile_builder'] = 'CV Profile Builder';
      _enUs['cv_profile_desc'] = 'Build and update your digital CV to showcase to elite educational institutes.';
      _enUs['careers'] = 'Careers';
      _enUs['store'] = 'Store';
      _enUs['edit_cv'] = 'Edit CV Profile';
      _enUs['add_cv'] = 'Create CV Profile';
      _enUs['edit_cv_desc'] = 'Update your professional CV, experience, and certifications.';
      _enUs['already_applied'] = 'You have already submitted an application for this job.';
      _enUs['derasy_store'] = 'Derasy Store';
      _enUs['store_desc'] = 'Upgrade your classroom with premium tools, stationery, and hardware synced with your official school account.';
      _enUs['explore_store'] = 'Explore Store';
      _enUs['search_store'] = 'Search store items...';
      _enUs['no_products_found'] = 'No products found';
      _enUs['in_stock'] = 'In Stock';
      _enUs['select_option'] = 'Select Format / Option';
      _enUs['quantity'] = 'Quantity';
      _enUs['add_to_cart'] = 'Add to Cart';
      _enUs['added_to_cart'] = 'Added to Cart!';
      _enUs['added_cart_success_desc'] = 'The item has been successfully added to your cart.';
      _enUs['continue_shopping'] = 'Continue';
      _enUs['view_cart'] = 'View Cart';
      _enUs['checkout'] = 'Secure Checkout';
      _enUs['delivery_details'] = 'Delivery Details';
      _enUs['shipping_address'] = 'Shipping Address';
      _enUs['city'] = 'City';
      _enUs['phone'] = 'Phone Number';
      _enUs['delivery_notes_hint'] = 'Special delivery notes (optional)...';
      _enUs['payment_method'] = 'Payment Method';
      _enUs['wallet'] = 'Wallet Balance';
      _enUs['cod'] = 'Cash on Delivery';
      _enUs['total_amount'] = 'Total Amount';
      _enUs['place_order'] = 'Place Order';
      _enUs['order_success'] = 'Order Placed!';
      _enUs['order_success_desc'] = 'Your order was successfully placed and wallet balance deducted.';
      _enUs['my_cart'] = 'My Cart';
      _enUs['in_person'] = 'In-Person Pickup';
      _enUs['delivery_method'] = 'Delivery Method';
      _enUs['home_delivery'] = 'Home Delivery';
      _enUs['delivery_fee'] = 'Delivery Fee';
      _enUs['cart_is_empty'] = 'Your Cart is Empty';
      _enUs['subtotal'] = 'Subtotal';
      _enUs['total'] = 'Total Amount';
      _enUs['proceed_to_checkout'] = 'Proceed to Checkout';
      _enUs['order_history'] = 'My Orders';
      _enUs['no_orders_found'] = 'No orders found';
      _enUs['interview_details'] = 'Interview Details';
      _enUs['notes'] = 'Notes';
      _enUs['career_dashboard'] = 'Career Progress';
      _enUs['applied_jobs'] = 'Applied';
      _enUs['interviews'] = 'Interviews';
      _enUs['shortlisted'] = 'Shortlisted';
      _enUs['hired'] = 'Hired';
      _enUs['headline'] = 'Professional Headline';
      _enUs['bio'] = 'Bio / Overview';
      _enUs['skills'] = 'Professional Skills';
      _enUs['add_skill'] = 'Add Skill Tag';
      _enUs['no_skills_added'] = 'No skills added yet.';
      _enUs['applied_applications'] = 'Applied Applications';
      _enUs['rejected_applications'] = 'Rejected Applications';
      _enUs['applied_on'] = 'Applied on';
      _enUs['rejected'] = 'Rejected';
      _enUs['applied'] = 'Applied';
      _enUs['headline_hint'] = 'e.g. Math Teacher';
      _enUs['bio_hint'] = 'e.g. Passionate mathematics teacher with over 5 years of experience...';
      _enUs['jobs_you_can_apply'] = 'Jobs You Can Apply For';
      _enUs['explore_latest_teacher_jobs'] = 'Explore and apply to elite educational vacancies';
      _enUs['my_classes_and_subjects'] = 'My Classes & Subjects';

      // Load Arabic translations
      String arJson =
          await rootBundle.loadString('assets/translations/ar-SA.json');
      Map<String, dynamic> arData = json.decode(arJson) as Map<String, dynamic>;
      _arSa = arData.cast<String, String>();

      _arSa['recent_jobs'] = 'الوظائف الحديثة';
      _arSa['other_jobs'] = 'وظائف أخرى';
      _arSa['cv_profile_builder'] = 'منشئ السيرة الذاتية';
      _arSa['cv_profile_desc'] = 'قم ببناء وتحديث سيرتك الذاتية الرقمية لعرضها على المؤسسات التعليمية المتميزة.';
      _arSa['careers'] = 'المسيرة المهنية';
      _arSa['store'] = 'المتجر';
      _arSa['edit_cv'] = 'تعديل السيرة الذاتية';
      _arSa['add_cv'] = 'إنشاء السيرة الذاتية';
      _arSa['edit_cv_desc'] = 'قم بتحديث خبراتك، مهاراتك، وشهاداتك المهنية.';
      _arSa['already_applied'] = 'لقد قمت بالفعل بتقديم طلب لهذه الوظيفة.';
      _arSa['derasy_store'] = 'دراسي ستور';
      _arSa['store_desc'] = 'قم بترقية فصلك الدراسي باستخدام الأدوات المتميزة والقرطاسية والأجهزة المتزامنة مع حسابك المدرسي الرسمي.';
      _arSa['explore_store'] = 'تصفح المتجر';
      _arSa['search_store'] = 'ابحث في منتجات المتجر...';
      _arSa['no_products_found'] = 'لم يتم العثور على منتجات';
      _arSa['in_stock'] = 'متوفر في المخزون';
      _arSa['select_option'] = 'اختر الخيار / الفئة';
      _arSa['quantity'] = 'الكمية';
      _arSa['add_to_cart'] = 'إضافة إلى السلة';
      _arSa['added_to_cart'] = 'تمت الإضافة إلى السلة!';
      _arSa['added_cart_success_desc'] = 'تمت إضافة المنتج بنجاح إلى سلتك.';
      _arSa['continue_shopping'] = 'مواصلة التسوق';
      _arSa['view_cart'] = 'عرض السلة';
      _arSa['checkout'] = 'الدفع الآمن';
      _arSa['delivery_details'] = 'تفاصيل التوصيل';
      _arSa['shipping_address'] = 'عنوان الشحن';
      _arSa['city'] = 'المدينة';
      _arSa['phone'] = 'رقم الهاتف';
      _arSa['delivery_notes_hint'] = 'ملاحظات التوصيل الخاصة (اختياري)...';
      _arSa['payment_method'] = 'طريقة الدفع';
      _arSa['wallet'] = 'رصيد المحفظة';
      _arSa['cod'] = 'الدفع عند الاستلام';
      _arSa['total_amount'] = 'المبلغ الإجمالي';
      _arSa['place_order'] = 'تأكيد الطلب';
      _arSa['order_success'] = 'تم إرسال الطلب!';
      _arSa['order_success_desc'] = 'تم تقديم طلبك بنجاح وخصم المبلغ من المحفظة.';
      _arSa['my_cart'] = 'سلة المشتريات';
      _arSa['in_person'] = 'استلام شخصي';
      _arSa['delivery_method'] = 'طريقة التوصيل';
      _arSa['home_delivery'] = 'شحن للمنزل';
      _arSa['delivery_fee'] = 'رسوم التوصيل';
      _arSa['cart_is_empty'] = 'سلة المشتريات فارغة';
      _arSa['subtotal'] = 'المجموع الفرعي';
      _arSa['total'] = 'المجموع الإجمالي';
      _arSa['proceed_to_checkout'] = 'المتابعة لإتمام الطلب';
      _arSa['order_history'] = 'طلباتي';
      _arSa['no_orders_found'] = 'لا توجد طلبات سابقة';
      _arSa['interview_details'] = 'تفاصيل المقابلة';
      _arSa['notes'] = 'ملاحظات';
      _arSa['career_dashboard'] = 'لوحة التطور المهني';
      _arSa['applied_jobs'] = 'الوظائف المقدمة';
      _arSa['shortlisted'] = 'المترشحة';
      _arSa['hired'] = 'تم التوظيف';
      _arSa['interviews'] = 'المقابلات';
      _arSa['headline'] = 'العنوان المهني';
      _arSa['bio'] = 'النبذة التعريفية';
      _arSa['skills'] = 'المهارات المهنية';
      _arSa['add_skill'] = 'إضافة مهارة';
      _arSa['no_skills_added'] = 'لم يتم إضافة أي مهارات بعد.';
      _arSa['applied_applications'] = 'الطلبات المقدمة';
      _arSa['rejected_applications'] = 'الطلبات المرفوضة';
      _arSa['applied_on'] = 'تم التقديم في';
      _arSa['rejected'] = 'مرفوض';
      _arSa['applied'] = 'مقدم';
      _arSa['headline_hint'] = 'مثال: معلم رياضيات أول';
      _arSa['bio_hint'] = 'مثال: معلم رياضيات شغوف بخبرة تزيد عن 5 سنوات...';
      _arSa['jobs_you_can_apply'] = 'الوظائف المتاحة للتقديم';
      _arSa['explore_latest_teacher_jobs'] = 'تصفح وقدم على أفضل الشواغر والفرص التعليمية';
      _arSa['my_classes_and_subjects'] = 'فصولي وموادي الدراسية';

      print('✅ Translations loaded successfully');
      print('English keys: ${_enUs.length}');
      print('Arabic keys: ${_arSa.length}');
    } catch (e) {
      print('❌ Error loading translations: $e');
    }
  }
}

