import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/family_service.dart';
import 'models/family_member.dart';

class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key});

  static const Color blue = Color(0xff5E7FCB);
  static const Color mint = Color(0xff9FE2D4);
  static const Color textColor = Color(0xff53617F);
  static const Color grayText = Color(0xff9A9A9A);

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  final Graph graph = Graph()..isTree = true;
  final BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
  final Map<String, Node> nodeMap = {};
  List<FamilyMember> members = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    builder
      ..siblingSeparation = 40
      ..levelSeparation = 60
      ..subtreeSeparation = 40
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
    loadTree();
  }

  Future<void> loadTree() async {
    setState(() => isLoading = true);

    members = await FamilyService().getAllMembers();
    nodeMap.clear();
    graph.nodes.clear();
    graph.edges.clear();

    for (var m in members) {
      nodeMap[m.id] = Node.Id(m.id);
    }

    for (var m in members) {
      if (m.fatherId != null && nodeMap.containsKey(m.fatherId)) {
        graph.addEdge(nodeMap[m.fatherId]!, nodeMap[m.id]!);
      } else {
        graph.addNode(nodeMap[m.id]!);
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  FamilyMember _memberOf(Node node) =>
      members.firstWhere((m) => m.id == node.key!.value);

  String? _fatherNameOf(FamilyMember member) {
    if (member.fatherId == null) return null;
    final matches = members.where((m) => m.id == member.fatherId);
    if (matches.isEmpty) return null;
    return matches.first.name;
  }

  List<FamilyMember> _childrenOf(FamilyMember member) {
    return members.where((m) => m.fatherId == member.id).toList();
  }

  void _openMemberDetails(FamilyMember member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MemberDetailsSheet(
        member: member,
        fatherName: _fatherNameOf(member),
        children: _childrenOf(member),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _header(context),
            const SizedBox(height: 30),

            const Text(
              'شجرة العائلة',
              style: TextStyle(
                color: FamilyTreeScreen.textColor,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'استعرض أفراد العائلة والأجيال',
              style: TextStyle(
                color: FamilyTreeScreen.grayText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: FamilyTreeScreen.blue,
                ),
              )
                  : members.isEmpty
                  ? _EmptyState()
                  : InteractiveViewer(
                constrained: false,
                boundaryMargin: const EdgeInsets.all(100),
                minScale: 0.2,
                maxScale: 3.0,
                child: GraphView(
                  graph: graph,
                  algorithm: BuchheimWalkerAlgorithm(
                    builder,
                    TreeEdgeRenderer(builder),
                  ),
                  builder: (Node node) {
                    final member = _memberOf(node);
                    return _MemberCard(
                      member: member,
                      onTap: () => _openMemberDetails(member),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return SizedBox(
      height: 165,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/header_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 142,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new,
                    size: 15,
                    color: FamilyTreeScreen.textColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'العودة',
                    style: TextStyle(
                      color: FamilyTreeScreen.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_tree_outlined,
            size: 60,
            color: FamilyTreeScreen.grayText,
          ),
          const SizedBox(height: 14),
          const Text(
            'لا يوجد أفراد مضافين بعد',
            style: TextStyle(
              color: FamilyTreeScreen.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'اضغط + لإضافة أول فرد',
            style: TextStyle(
              color: FamilyTreeScreen.grayText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onTap;

  const _MemberCard({required this.member, required this.onTap});

  /// يعرض الاسم الأول + اسم الأب + اسم الجد (أول 3 كلمات من الاسم الكامل)
  /// بدل الاسم الكامل بكل الأربع مقاطع، عشان الكارد يفضل صغير ومقروء.
  String get _displayName {
    final words = member.name.trim().split(RegExp(r'\s+'));
    if (words.length <= 3) return member.name;
    return words.take(3).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isMale = member.gender == 'male';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMale ? const Color(0xffE8EEFB) : const Color(0xffE8F9F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isMale ? FamilyTreeScreen.blue : FamilyTreeScreen.mint,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMale ? Icons.man : Icons.woman,
              color: FamilyTreeScreen.textColor,
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              _displayName,
              style: const TextStyle(
                color: FamilyTreeScreen.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberDetailsSheet extends StatelessWidget {
  final FamilyMember member;
  final String? fatherName;
  final List<FamilyMember> children;

  const _MemberDetailsSheet({
    required this.member,
    required this.fatherName,
    required this.children,
  });

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  int? _ageOf(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _maritalStatusText(String value) {
    switch (value) {
      case 'single':
        return 'أعزب';
      case 'married':
        return 'متزوج';
      case 'divorced':
        return 'مطلق';
      case 'widowed':
        return 'أرمل';
      default:
        return value;
    }
  }

  String _occupationText(String value) {
    switch (value) {
      case 'student':
        return 'طالب';
      case 'government_employee':
        return 'موظف قطاع حكومي';
      case 'private_employee':
        return 'موظف قطاع خاص';
      default:
        return value;
    }
  }

  /// يفتح تطبيق الاتصال بالرقم المعطى بعد تنظيفه من أي مسافات أو رموز غير رقمية
  /// (باستثناء + في حالة وجود كود دولي).
  Future<void> _callPhone(BuildContext context, String rawPhone) async {
    final String cleaned = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri uri = Uri(scheme: 'tel', path: cleaned);

    final bool launched = await launchUrl(uri);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح تطبيق الاتصال على هذا الجهاز')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMale = member.gender == 'male';
    final avatarColor = isMale ? FamilyTreeScreen.blue : FamilyTreeScreen.mint;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xffE0E0E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                Center(
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: avatarColor.withValues(alpha: 0.15),
                    backgroundImage: (member.photoUrl != null &&
                        member.photoUrl!.isNotEmpty)
                        ? NetworkImage(member.photoUrl!)
                        : null,
                    child: (member.photoUrl == null ||
                        member.photoUrl!.isEmpty)
                        ? Icon(
                      isMale ? Icons.man : Icons.woman, // يمكنك تغييرها حسب رغبتك
                      color: avatarColor,
                      size: 40,
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 14),

                Center(
                  child: Text(
                    member.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: FamilyTreeScreen.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                Center(
                  child: Text(
                    isMale ? 'ذكر' : 'أنثى',
                    style: const TextStyle(
                      color: FamilyTreeScreen.grayText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                if (member.bio != null && member.bio!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xffF7F8FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      member.bio!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: FamilyTreeScreen.textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 26),

                if (member.birthDate != null && _ageOf(member.birthDate!) != null)
                  _DetailRow(
                    icon: Icons.cake_outlined,
                    label: 'العمر',
                    value: '${_ageOf(member.birthDate!)} سنة',
                  ),

                if (member.maritalStatus != null &&
                    member.maritalStatus!.trim().isNotEmpty)
                  _DetailRow(
                    icon: Icons.favorite_border_rounded,
                    label: 'الحالة الاجتماعية',
                    value: _maritalStatusText(member.maritalStatus!),
                  ),

                if (member.occupation != null &&
                    member.occupation!.trim().isNotEmpty)
                  _DetailRow(
                    icon: Icons.work_outline_rounded,
                    label: 'الوظيفة',
                    value: _occupationText(member.occupation!),
                  ),

                if (member.city != null && member.city!.trim().isNotEmpty)
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'المدينة',
                    value: member.city!,
                  ),

                if (fatherName != null)
                  _DetailRow(
                    icon: Icons.arrow_upward_rounded,
                    label: 'الأب',
                    value: fatherName!,
                  ),

                _DetailRow(
                  icon: Icons.account_tree_outlined,
                  label: 'الجيل',
                  value: '${member.generation}',
                ),

                // رقم الجوال - قابل للنقر لفتح تطبيق الاتصال مباشرة
                // يظهر فقط إذا لم يختر العضو إخفاءه (hidePhoneInTree == false)
                if (!member.hidePhoneInTree &&
                    member.phone != null &&
                    member.phone!.trim().isNotEmpty)
                  _DetailRow(
                    icon: Icons.phone_outlined,
                    label: 'رقم الجوال',
                    value: member.phone!,
                    valueColor: FamilyTreeScreen.blue,
                    trailing: const Icon(
                      Icons.call_rounded,
                      size: 18,
                      color: FamilyTreeScreen.blue,
                    ),
                    onTap: () => _callPhone(context, member.phone!),
                  ),

                if (children.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(color: Color(0xffEDEDED)),
                  const SizedBox(height: 10),
                  Text(
                    'الأبناء (${children.length})',
                    style: const TextStyle(
                      color: FamilyTreeScreen.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...children.map(
                        (child) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            child.gender == 'male'
                                ? Icons.male
                                : Icons.female,
                            size: 16,
                            color: FamilyTreeScreen.grayText,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              child.name,
                              style: const TextStyle(
                                color: FamilyTreeScreen.textColor,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xffF3F5FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: FamilyTreeScreen.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: FamilyTreeScreen.grayText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? FamilyTreeScreen.textColor,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: row,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: row,
        ),
      ),
    );
  }
}