const fs = require('fs');

const file = 'c:\\Users\\dell\\apps\\apps\\derasy-app\\files\\lib\\views\\admission\\new_admission_flow_page.dart';
let content = fs.readFileSync(file, 'utf8');

// Translate school type and gender
content = content.replace(
  "_miniBadge(school.type!, isIndigo: true)",
  "_miniBadge(school.type!.toLowerCase().tr, isIndigo: true)"
);
content = content.replace(
  "_miniBadge(school.gender ?? 'mixed'.tr, isGender: true)",
  "_miniBadge((school.gender ?? 'mixed').toLowerCase().tr, isGender: true)"
);

// Translate detail items (educationSystem, religionType, etc.)
content = content.replace(
  "_detailItem(Icons.book_outlined, school.educationSystem!),",
  "_detailItem(Icons.book_outlined, school.educationSystem!.toLowerCase().tr),"
);
content = content.replace(
  "_detailItem(Icons.mosque_outlined, school.religionType!),",
  "_detailItem(Icons.mosque_outlined, school.religionType!.toLowerCase().tr),"
);

fs.writeFileSync(file, content);
console.log('translated');
