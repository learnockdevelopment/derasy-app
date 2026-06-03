const fs = require('fs');

const file = 'c:\\Users\\dell\\apps\\apps\\derasy-app\\files\\lib\\views\\admission\\new_admission_flow_page.dart';
let content = fs.readFileSync(file, 'utf8');

// Replace national id to support passport or hide
const oldNat = "child.nationalId.isNotEmpty ? `${child.nationalId.substring(0, 4)}... (موثق)` : 'no_national_id'.tr,";
const newNat = "child.nationalId.isNotEmpty ? `${child.nationalId.substring(0, 4)}... (موثق)` : (child.passport != null && child.passport!.isNotEmpty ? `${child.passport!.substring(0, Math.min(4, child.passport!.length))}... (موثق)` : 'no_national_id'.tr),";
content = content.replace(oldNat, newNat);

const oldContainer = `Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(`;
const newContainer = `if (child.nationalId.isNotEmpty || (child.passport != null && child.passport!.isNotEmpty))
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(`;
content = content.replace(oldContainer, newContainer);

// Change banner image
const oldBanner = "imageUrl: school.bannerImage,";
const newBanner = "imageUrl: school.bannerImage ?? school.visibilitySettings?.officialLogo?.url,";
content = content.replace(oldBanner, newBanner);

// Also replace Math.min with math.min since Dart needs dart:math
// Wait, dart string interpolation format:
const oldNatFix = "`\\$\\{child.nationalId.substring(0, 4)\\}... (موثق)`";
// Let's do exact match instead.

content = content.replace(/child\.nationalId\.isNotEmpty \? '\$\{child\.nationalId\.substring\(0, 4\)\}\.\.\. \(موثق\)' : 'no_national_id'\.tr,/, 
  "child.nationalId.isNotEmpty ? '${child.nationalId.substring(0, 4)}... (موثق)' : (child.passport != null && child.passport!.isNotEmpty ? '${child.passport!.substring(0, child.passport!.length < 4 ? child.passport!.length : 4)}... (موثق)' : 'no_national_id'.tr),");

fs.writeFileSync(file, content);
console.log('done');
