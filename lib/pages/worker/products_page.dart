import 'dart:convert';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:price_book/api_client.dart';
import 'package:price_book/pages/worker/complete_product_page.dart';
import '../../keys.dart';

class WorkerObjectProductsPage extends StatefulWidget {
  final String objectId;
  final String taskId;
  const WorkerObjectProductsPage({
    super.key,
    required this.objectId,
    required this.taskId,
  });

  @override
  State<WorkerObjectProductsPage> createState() =>
      _WorkerObjectProductsPageState();
}

const Map<String, Map<String, String>> productCategories = {
  'fruits_veg': {
    'ru': 'Фрукты и овощи',
    'kk': 'Жемістер мен көкөністер',
    'keywords': 'фрукты,овощи,жемістер,көкөністер',
  },
  'fruits_veg_fresh': {
    'ru': 'Фрукты и овощи свежие',
    'kk': 'Жаңа жиналған жемістер мен көкөністер',
    'keywords': 'свежие,жаңа',
  },
  'fruits_veg_processed': {
    'ru': 'Фрукты и овощи переработанные',
    'kk': 'Қайта өңделген жемістер мен көкөністер',
    'keywords': 'переработанные,өңделген',
  },
  'milk': {
    'ru': 'Молоко',
    'kk': 'Сүт',
    'keywords': 'молоко,сыр,кефир,йогурт,сливки,сүт,ірімшік',
  },
  'meat': {
    'ru': 'Мясо, исключая птицу',
    'kk': 'Құс етін қоспағандағы ет',
    'keywords': 'мясо,ет,құс',
  },
  'cheese': {'ru': 'Сыры', 'kk': 'Ірімшіктер', 'keywords': 'сыр,ірімшік'},
  'baby_food': {
    'ru': 'Питание детское',
    'kk': 'Балалар тағамы',
    'keywords': 'детское,балалар',
  },
  'cookies': {'ru': 'Печенье', 'kk': 'Печенье', 'keywords': 'печенье'},
  'no_fruits_veg_food': {
    'ru': 'Продукты питания без фруктов и овощей',
    'kk': 'Жемістер мен көкөністерсіз тағамдық өнімдер',
    'keywords': 'без фруктов,жоқ жемістер',
  },
  'knitwear_socks': {
    'ru': 'Трикотажные и чулочно-носочные изделия',
    'kk': 'Трикотаж және шұлық-ұйық бұйымдары',
    'keywords': 'трикотаж,шұлық,носк,ұйық',
  },
  'clothes_other': {
    'ru': 'Одежда, кроме трикотажных и чулочно-носочных изделий',
    'kk': 'Трикотаж бен шұлық-ұйық бұйымдарынан басқа киімдер',
    'keywords': 'одежда,киім,шұлық,трикотаж',
  },
  'books': {
    'ru': 'Книги, газеты и журналы',
    'kk': 'Кітаптар, газеттер және журналдар',
    'keywords': 'книги,газеты,журналы,кітап,газет,журнал',
  },
  'soap': {'ru': 'Мыло', 'kk': 'Сабын', 'keywords': 'мыло,сабын'},
  'food_products': {
    'ru': 'Продовольственные товары',
    'kk': 'Азық-түлік тауарлары',
    'keywords': 'товары,тауарлар,продовольственные,азық-түлік',
  },
  'food_products_no_fv': {
    'ru': 'Продовольственные товары без фруктов и овощей',
    'kk': 'Жемістер мен көкөністерсіз азық-түлік тауарлары',
    'keywords': 'без фруктов,жоқ жемістер',
  },
  'furniture': {
    'ru': 'Мебель для дома',
    'kk': 'Үйге арналған жиһаз',
    'keywords': 'мебель,жиһаз',
  },
  'appliances': {
    'ru': 'Электрические бытовые приборы',
    'kk': 'Электр тұрмыстық құралдары',
    'keywords': 'электр,приборы,құралдар',
  },
  'lighting': {
    'ru': 'Осветительные приборы',
    'kk': 'Жарық беретін құралдар',
    'keywords': 'осветительные,жарық',
  },
  'goods_services': {
    'ru': 'Товары и услуги',
    'kk': 'Тауарлар мен қызметтер',
    'keywords': 'товары,услуги,тауарлар,қызмет',
  },
  'auto_services': {
    'ru':
        'Техническое обслуживание автомобиля и прочие услуги, связанные с личными транспортными средствами',
    'kk': 'Жеке көлік құралымен байланысты қызметтер',
    'keywords': 'автомобиль,транспорт,көлік,техобслуживание',
  },
  'all_goods_no_fv': {
    'ru': 'Все товары и услуги без фруктов и овощей',
    'kk': 'Жемістер мен көкөністерсіз барлық тауарлар мен қызметтер',
    'keywords': 'без фруктов,жоқ жемістер',
  },
  'baby_food_goods': {
    'ru': 'Продукты питания и товары для младенцев',
    'kk': 'Сәбилерге арналған тамақ өнімдері және тауарлар',
    'keywords': 'младенцы,сәбилер',
  },
  'comm_services_no_phone': {
    'ru': 'Услуги связи без телефонного и факсимильного оборудования',
    'kk':
        'Телефонды және факсимильді жабдықтарды есепке алмағандағы байланыс қызметтері',
    'keywords': 'связь,байланыс,телефон',
  },
  'central_post_services': {
    'ru': 'Услуги почты и связи (централизованные)',
    'kk': 'Почта және байланыс қызметтері (орталықтандырылған)',
    'keywords': 'почта,связь,байланыс',
  },
  'mobile_internet_services': {
    'ru': 'Услуги мобильной связи и интернет',
    'kk': 'Ұтқыр байланыс және интернет қызметтері',
    'keywords': 'мобильная,интернет,ұтқыр',
  },
  'financial_services': {
    'ru':
        'Прочие финансовые услуги, страхование личных автотранспортных средств',
    'kk': 'Өзге де қаржы қызметтері, жеке автокөлік құралдарын сақтандыру',
    'keywords': 'финансовые,сақтандыру,услуги,қызмет',
  },
  'repair_services': {
    'ru': 'Услуги по ремонту обуви, мебели, бытовых приборов и часов',
    'kk':
        'Аяқкиім, жиһаз, тұрмыстық құралдар мен сағаттарды жөндеу бойынша қызметтер',
    'keywords': 'ремонт,жөндеу',
  },
  'school_kids_goods': {
    'ru': 'Товары для детей школьного возраста',
    'kk': 'Мектеп жасындағы балаларға арналған тауарлар',
    'keywords': 'школьные,балалар',
  },
  'hair_cleaning_services': {
    'ru': 'Услуги парикмахерских, ритуальные, химчистка',
    'kk': 'Шаштараз, салт-жора, химиялық тазалау қызметтері',
    'keywords': 'парикмахерская,химчистка,шаштараз',
  },
  'photo_copy_legal': {
    'ru': 'Услуги фотографов, копировальные и правовые',
    'kk': 'Фотографтардың, көшіру және құқық қызметтері',
    'keywords': 'фотограф,копирование,құқық',
  },
  'paid_services': {
    'ru': 'Платные услуги',
    'kk': 'Ақылы қызметтер',
    'keywords': 'платные,ақылы',
  },
  'non_food_goods': {
    'ru': 'Непродовольственные товары',
    'kk': 'Азық-түлік емес тауарлар',
    'keywords': 'непродовольственные,тауарлар',
  },
  'housing_services': {
    'ru': 'Жилищно-коммунальные услуги',
    'kk': 'Тұрғын үй-коммуналдық қызметтері',
    'keywords': 'жилищно,коммуналдық',
  },
  'regulated_utilities': {
    'ru': 'Коммунальные услуги регулируемые',
    'kk': 'Реттелетін комуналдық қызметтер',
    'keywords': 'регулируемые,реттелетін',
  },
  'nonregulated_utilities': {
    'ru': 'Жилищно-коммунальные услуги нерегулируемые',
    'kk': 'Реттелмейтін тұрғын үй-коммуналдық қызметтер',
    'keywords': 'нерегулируемые,реттелмейтін',
  },
  'goods': {'ru': 'Товары', 'kk': 'Тауарлар', 'keywords': 'товары,тауарлар'},
  'basic_food': {
    'ru': 'Основные продукты питания',
    'kk': 'Негізгі тамақ өнімдері',
    'keywords': 'продукты,таам',
  },
};

final Map<String, Color> categoryColorsRu = {
  'Все': Colors.grey,
  'Молочные': Colors.lightBlue,
  'Крупы': Colors.orange,
  'Макароны': Colors.deepPurple,
  'Мука': Colors.brown,
  'Другое': Colors.teal,
};

final Map<String, Color> categoryColorsKk = {
  'Барлығы': Colors.grey,
  'Сүт': Colors.lightBlue,
  'Күріш, дәнді дақылдар': Colors.orange,
  'Макарондар': Colors.deepPurple,
  'Ұн': Colors.brown,
  'Басқасы': Colors.teal,
};

String detectCategory(String name, String locale) {
  final lower = name.toLowerCase();

  for (final entry in productCategories.entries) {
    final keywords = (entry.value['keywords'] ?? '').toLowerCase().split(',');
    for (final key in keywords) {
      if (lower.contains(key)) return entry.value[locale] ?? entry.value['ru']!;
    }
  }

  return locale == 'kk' ? 'Басқасы' : 'Другое';
}

class _WorkerObjectProductsPageState extends State<WorkerObjectProductsPage> {
  final Map<String, Future<Uint8List>> _imgCache = {};
  Map<String, dynamic>? object;
  bool loading = true;
  bool error = false;
  String selectedCategory = 'Все';

  Future<void> fetchObject() async {
    setState(() {
      loading = true;
      error = false;
    });

    try {
      final response = await ApiClient.get('/task/${widget.taskId}', context);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);

        final found = list.firstWhere(
          (e) => e["id"] == widget.objectId,
          orElse: () => null,
        );

        if (found == null) {
          throw Exception('Object not found in task');
        }

        if (!mounted) return;

        setState(() {
          object = found;
          loading = false;
        });
      } else {
        throw Exception(response.body);
      }
    } catch (e, s) {
      debugPrint('fetchObject error: $e');
      debugPrint('$s');

      if (!mounted) return;

      setState(() {
        loading = false;
        error = true;
      });
    }
  }

  Future<Uint8List> _loadImage(String fileName) {
    final encoded = Uri.encodeComponent(fileName);
    return _imgCache.putIfAbsent(
      encoded,
      () => ApiClient.getBytes('/picture/$encoded', context),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchObject();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    String getName(dynamic raw) {
      if (raw == null) return "";
      if (raw is Map) {
        return raw[locale] ?? raw["en"] ?? raw.values.first.toString();
      }
      return raw.toString();
    }

    final goods = (object?["goods"] as List?) ?? [];
    final marketName = object?["marketId"]?.toString() ?? unknown.tr();
    final allCategories = <String>[locale == 'kk' ? 'Барлығы' : 'Все'];

    for (final g in goods) {
      final name = getName((g as Map)["name"]);
      if (name.isEmpty) continue;

      final cat = detectCategory(name, locale);

      if (!allCategories.contains(cat)) {
        allCategories.add(cat);
      }
    }

    final filteredGoods =
        (selectedCategory == (locale == 'kk' ? 'Барлығы' : 'Все'))
        ? goods
        : goods.where((g) {
            final name = getName((g as Map)["name"]);
            return detectCategory(name, locale) == selectedCategory;
          }).toList();

    final completedCount = goods
        .where((g) => (g as Map)["completed"] == true)
        .length;
    final totalGoods = goods.length;
    final double progress = totalGoods == 0 ? 0 : completedCount / totalGoods;
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error || object == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(errorLoading.tr()),
              TextButton(onPressed: fetchObject, child: Text(retry.tr())),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("${productsK.tr()}"),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade200, Colors.blue.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 255, 255, 255), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: goods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 56,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        noProd.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        noObjYet.tr(),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ),
                            child: const Icon(
                              Icons.storefront,
                              color: Color.fromRGBO(144, 202, 249, 1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  marketName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${productsK.tr()}: $totalGoods, ${completeV.tr()}: $completedCount",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (totalGoods > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(
                              progress >= 1 ? Colors.green : Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: allCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = allCategories[index];
                          final isActive = cat == selectedCategory;
                          final baseColor =
                              (locale == 'kk'
                                  ? categoryColorsKk
                                  : categoryColorsRu)[cat] ??
                              Colors.blueGrey;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategory = cat;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? baseColor
                                    : baseColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? Colors.white : baseColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        itemCount: filteredGoods.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final good = filteredGoods[index];

                          final productName = getName(good["name"]).isEmpty
                              ? noNameM.tr()
                              : getName(good["name"]);

                          final completed = good["completed"] == true;
                          final photoProduct =
                              (good["photoProduct"]?.toString() ?? "").trim();
                          final photoPrice =
                              (good["photoPrice"]?.toString() ?? "").trim();

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 220 + index * 40),
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 16 * (1 - value)),
                                child: child,
                              ),
                            ),
                            child: Card(
                              elevation: 4,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: completed
                                        ? [Colors.green.shade50, Colors.white]
                                        : [Colors.white, Colors.blue.shade50],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: completed
                                        ? Colors.green.shade200
                                        : Colors.blue.shade200,
                                    child: Icon(
                                      completed
                                          ? Icons.check_rounded
                                          : Icons.inventory_2_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    productName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  // ✅ статус + фото под ним
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        completed
                                            ? completedC.tr()
                                            : waiting.tr(),
                                        style: TextStyle(
                                          color: completed
                                              ? Colors.green
                                              : Colors.grey[700],
                                          fontWeight: completed
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      if (completed &&
                                          (photoProduct.isNotEmpty ||
                                              photoPrice.isNotEmpty)) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            if (photoProduct.isNotEmpty)
                                              _PhotoThumb(
                                                fileName: photoProduct,
                                                loader: _loadImage,
                                              ),
                                            if (photoProduct.isNotEmpty &&
                                                photoPrice.isNotEmpty)
                                              const SizedBox(width: 10),
                                            if (photoPrice.isNotEmpty)
                                              _PhotoThumb(
                                                fileName: photoPrice,
                                                loader: _loadImage,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),

                                  trailing: completed
                                      ? ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CompleteGoodPage(
                                                      taskDetailId:
                                                          widget.objectId,
                                                      goodId: good["goodId"],
                                                      marketName: marketName,
                                                      productName: productName,
                                                    ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[400],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: Text(
                                            redo.tr(),
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        )
                                      : ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CompleteGoodPage(
                                                      taskDetailId:
                                                          widget.objectId,
                                                      goodId: good["goodId"],
                                                      marketName: marketName,
                                                      productName: productName,
                                                    ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue[300],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: Text(
                                            execute.tr(),
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// ---------- THUMB ----------
class _PhotoThumb extends StatelessWidget {
  final String fileName;
  final Future<Uint8List> Function(String fileName) loader;

  const _PhotoThumb({required this.fileName, required this.loader});

  @override
  Widget build(BuildContext context) {
    final heroTag = 'pic_$fileName';

    return FutureBuilder<Uint8List>(
      future: loader(fileName),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _box(
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snap.hasError) {
          return _box(
            child: Tooltip(
              message: snap.error.toString(),
              child: const Icon(Icons.error_outline),
            ),
          );
        }

        if (!snap.hasData) {
          return _box(child: const Icon(Icons.broken_image_outlined));
        }

        final bytes = snap.data!;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    _FullscreenImagePage(bytes: bytes, heroTag: heroTag),
              ),
            );
          },
          child: Hero(
            tag: heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                bytes,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _box({required Widget child}) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

/// ---------- FULLSCREEN ----------
class _FullscreenImagePage extends StatelessWidget {
  final Uint8List bytes;
  final String heroTag;

  const _FullscreenImagePage({required this.bytes, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
