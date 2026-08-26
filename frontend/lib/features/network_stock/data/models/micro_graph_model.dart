import 'person_model.dart';
import 'company_model.dart';

class RadialNodeModel {
  final String nodeId;
  final String nodeName;
  final String nodeType; // PERSON or COMPANY
  final String relationType;
  final String relationBadge;
  final double weight;
  final String? detailInfo;
  final int connectedCompanyCount;
  final String? sourceUrl;

  RadialNodeModel({
    required this.nodeId,
    required this.nodeName,
    required this.nodeType,
    required this.relationType,
    required this.relationBadge,
    required this.weight,
    this.detailInfo,
    this.connectedCompanyCount = 0,
    this.sourceUrl,
  });

  factory RadialNodeModel.fromJson(Map<String, dynamic> json) {
    return RadialNodeModel(
      nodeId: json['node_id'] as String,
      nodeName: json['node_name'] as String,
      nodeType: json['node_type'] as String? ?? 'PERSON',
      relationType: json['relation_type'] as String? ?? '',
      relationBadge: json['relation_badge'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.5,
      detailInfo: json['detail_info'] as String?,
      connectedCompanyCount: json['connected_company_count'] as int? ?? 0,
      sourceUrl: json['source_url'] as String?,
    );
  }
}

class MicroGraphModel {
  final String status;
  final PersonModel? centerPerson;
  final CompanyModel? centerCompany;
  final List<RadialNodeModel> radialNodes;

  MicroGraphModel({
    required this.status,
    this.centerPerson,
    this.centerCompany,
    required this.radialNodes,
  });

  factory MicroGraphModel.fromJson(Map<String, dynamic> json) {
    return MicroGraphModel(
      status: json['status'] as String? ?? 'success',
      centerPerson: json['center_person'] != null
          ? PersonModel.fromJson(json['center_person'] as Map<String, dynamic>)
          : null,
      centerCompany: json['center_company'] != null
          ? CompanyModel.fromJson(json['center_company'] as Map<String, dynamic>)
          : null,
      radialNodes: (json['radial_nodes'] as List<dynamic>?)
              ?.map((e) => RadialNodeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
