class SchoolReportResponse {
  final Map<String, dynamic> stats;
  final Map<String, dynamic>? studentsByClass;
  final String markdown;
  final String html;

  SchoolReportResponse({
    required this.stats,
    this.studentsByClass,
    required this.markdown,
    required this.html,
  });

  factory SchoolReportResponse.fromJson(Map<String, dynamic> json) {
    return SchoolReportResponse(
      stats: json['stats'] ?? {},
      studentsByClass: json['studentsByClass'],
      markdown: json['markdown'] ?? '',
      html: json['html'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stats': stats,
      'studentsByClass': studentsByClass,
      'markdown': markdown,
      'html': html,
    };
  }
}

class ReportTemplate {
  final String id;
  final String name;
  final String code;
  final String category;
  final String type;

  ReportTemplate({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.type,
  });

  factory ReportTemplate.fromJson(Map<String, dynamic> json) {
    return ReportTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      category: json['category'] ?? '',
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'category': category,
      'type': type,
    };
  }
}

class ReportTemplatesResponse {
  final List<ReportTemplate> reports;

  ReportTemplatesResponse({required this.reports});

  factory ReportTemplatesResponse.fromJson(Map<String, dynamic> json) {
    return ReportTemplatesResponse(
      reports: (json['reports'] as List<dynamic>?)
              ?.map((e) => ReportTemplate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reports': reports.map((e) => e.toJson()).toList(),
    };
  }
}

