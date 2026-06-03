$file = 'c:\Users\dell\apps\apps\derasy-app\files\lib\views\admission\new_admission_flow_page.dart'
$content = Get-Content $file -Raw

# Replace national id display to show passport if national id is empty, or hide if both empty
$oldNat = "child.nationalId.isNotEmpty ? `'$(`$child.nationalId.substring(0, 4))... (موثق)`' : `'no_national_id`'.tr,"
$newNat = "child.nationalId.isNotEmpty ? `'$(`$child.nationalId.substring(0, 4))... (موثق)`' : (child.passport != null && child.passport!.isNotEmpty ? `'$(`$child.passport!.substring(0, child.passport!.length < 4 ? child.passport!.length : 4))... (موثق)`' : `'no_national_id`'.tr),"
$content = $content.Replace($oldNat, $newNat)

# Hide if both are empty
$oldContainer = "Container(" + [Environment]::NewLine + "                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)," + [Environment]::NewLine + "                                  decoration: BoxDecoration("
$newContainer = "if (child.nationalId.isNotEmpty || (child.passport != null && child.passport!.isNotEmpty))" + [Environment]::NewLine + "                                Container(" + [Environment]::NewLine + "                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)," + [Environment]::NewLine + "                                  decoration: BoxDecoration("
$content = $content.Replace($oldContainer, $newContainer)

# Change banner image to show official logo if banner is empty
$oldBanner = "imageUrl: school.bannerImage,"
$newBanner = "imageUrl: school.bannerImage ?? school.visibilitySettings?.officialLogo?.url,"
$content = $content.Replace($oldBanner, $newBanner)

Set-Content $file $content
