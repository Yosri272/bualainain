import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
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
                    return _MemberCard(member: member);
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
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final isMale = member.gender == 'male';
    return Container(
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
            isMale ? Icons.male : Icons.female,
            color: FamilyTreeScreen.textColor,
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            member.name,
            style: const TextStyle(
              color: FamilyTreeScreen.textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}