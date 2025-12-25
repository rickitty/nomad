import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:price_book/api_client.dart';
import 'package:price_book/keys.dart';
import 'package:price_book/pages/admin/create_good.dart';
import 'package:price_book/pages/widgets/drawer.dart';

class GoodsPage extends StatefulWidget {
  const GoodsPage({super.key});

  @override
  State<GoodsPage> createState() => _GoodsPageState();
}

class CategoryItem {
  final String ru;
  final String kz;

  const CategoryItem({required this.ru, required this.kz});



  String localized(BuildContext context) {
    final locale = context.locale.languageCode;
    return locale == 'kz' ? kz : ru;
  }
}

final List<CategoryItem> categories = [
  CategoryItem(ru: 'Фрукты и овощи', kz: 'Жемістер мен көкөністер'),
  CategoryItem(
    ru: 'Фрукты и овощи свежие',
    kz: 'Жаңа жиналған жемістер мен көкөністер',
  ),
  CategoryItem(
    ru: 'Фрукты и овощи переработанные',
    kz: 'Қайта өңделген жемістер мен көкөністер',
  ),
  CategoryItem(ru: 'Молоко', kz: 'Сүт'),
  CategoryItem(ru: 'Мясо, исключая птицу', kz: 'Құс етін қоспағандағы ет'),
  CategoryItem(ru: 'Сыры', kz: 'Ірімшіктер'),
  CategoryItem(ru: 'Питание детское', kz: 'Балалар тағамы'),
  CategoryItem(ru: 'Печенье', kz: 'Печенье'),
  CategoryItem(ru: 'Продовольственные товары', kz: 'Азық-түлік тауарлары'),
  CategoryItem(
    ru: 'Непродовольственные товары',
    kz: 'Азық-түлік емес тауарлар',
  ),
  CategoryItem(ru: 'Основные продукты питания', kz: 'Негізгі тамақ өнімдері'),
];

class _GoodsPageState extends State<GoodsPage> {
  bool loading = true;
  List goods = [];
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String category = '';
  CategoryItem? selectedCategory;
  String categorySearch = '';

  Future<void> loadGoods() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await ApiClient.get('/goods/$category', context);

      if (response.statusCode == 200) {
        goods = json.decode(utf8.decode(response.bodyBytes));
      } else {
        print("${error.tr()}:${response.body}");
        goods = [];
      }
    } catch (e) {
      print(e);
      goods = [];
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadGoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filteredGoods = goods.where((m) {
      if (searchQuery.isEmpty) return true;

      final name = (m["goodName"] ?? "").toString().toLowerCase();
      final categoryName = (m["categoryName"] ?? "").toString().toLowerCase();
      final unit = (m["unit"] ?? "").toString().toLowerCase();
      final brand = (m["brand"] ?? "").toString().toLowerCase();

      return name.contains(searchQuery) ||
          categoryName.contains(searchQuery) ||
          unit.contains(searchQuery) ||
          brand.contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      drawer: AppDrawer(current: DrawerRoute.goods),
      appBar: AppBar(
        title: Text(
          goodsK.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGood()),
          );
          loadGoods();
        },
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add),
        label: Text(
          Create.tr(),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final result = await showModalBottomSheet<CategoryItem>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) {
                          return StatefulBuilder(
                            builder: (context, setModalState) {
                              final filtered = categories.where((c) {
                                return c
                                    .localized(context)
                                    .toLowerCase()
                                    .contains(categorySearch.toLowerCase());
                              }).toList();

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(
                                    context,
                                  ).viewInsets.bottom,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 12),
                                    Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[400],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: TextField(
                                        decoration: InputDecoration(
                                          hintText: search.tr(),
                                          prefixIcon: const Icon(Icons.search),
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        onChanged: (v) {
                                          setModalState(
                                            () => categorySearch = v,
                                          );
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: filtered.length,
                                        itemBuilder: (_, i) {
                                          final c = filtered[i];
                                          return ListTile(
                                            title: Text(c.localized(context)),
                                            onTap: () =>
                                                Navigator.pop(context, c),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );

                      if (result != null) {
                        setState(() {
                          selectedCategory = result;
                          category = result.ru; // ← отправляешь RU на сервер
                        });
                        loadGoods();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.category_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedCategory?.localized(context) ??
                                  chooseCategory.tr(),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: search.tr(),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase().trim();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: loadGoods,
                    color: kPrimaryColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      itemCount: filteredGoods.length,
                      itemBuilder: (context, index) {
                        final g = filteredGoods[index];
                        return _GoodCard(good: g);
                      },
                    ),
                  ),
                ),
                Expanded(child: _buildEmptyState(textTheme)),
              ],
            ),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.production_quantity_limits,
              size: 52,
              color: kPrimaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              "${noGoodYet.tr()},${chooseCategory.tr()}",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2933),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _GoodCard extends StatelessWidget {
  final Map good;

  const _GoodCard({required this.good});

  @override
  Widget build(BuildContext context) {
    final name = good["goodName"] ?? '';
    final brand = good["brand"] ?? '';
    final unit = good["unit"] ?? '';
    final category = good["categoryName"] ?? '';
    final imageUrl = good["imageUrl"];
    final isActive = good["isActive"] == true;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            // INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (brand.isNotEmpty)
                    Text(
                      brand,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    "$category • $unit",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            // STATUS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withOpacity(0.15)
                    : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? active.tr() : inactive.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
