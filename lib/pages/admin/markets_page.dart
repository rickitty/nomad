import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:price_book/config.dart';
import 'dart:convert';

import '../../keys.dart';
import 'create_market_page.dart';

const Color kPrimaryColor = Color.fromRGBO(144, 202, 249, 1);

class MarketsPage extends StatefulWidget {
  const MarketsPage({super.key});

  @override
  State<MarketsPage> createState() => _MarketsPageState();
}

class _MarketsPageState extends State<MarketsPage> {
  List markets = [];
  bool loading = true;

  Future<void> loadMarkets() async {
    setState(() => loading = true);

    try {
      final headers = await Config.authorizedJsonHeaders();

      if (!headers.containsKey('Authorization')) {
        print("Токен не найден. Авторизуйтесь заново.");
        markets = [];
        return;
      }

      final response = await http.get(
        Uri.parse("$QYZ_API_BASE/markets"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        markets = json.decode(utf8.decode(response.bodyBytes));
      } else {
        print(
          "${loading_markets_error.tr()}: "
          "${response.statusCode} ${response.body}",
        );
        markets = [];
      }
    } catch (e) {
      print("Exception при загрузке рынков: $e");
      markets = [];
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadMarkets();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: Text(
          Markets.tr(),
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
            MaterialPageRoute(builder: (_) => const CreateMarketPage()),
          );
          loadMarkets();
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
          : markets.isEmpty
              ? _buildEmptyState(textTheme)
              : RefreshIndicator(
                  onRefresh: loadMarkets,
                  color: kPrimaryColor,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    itemCount: markets.length,
                    itemBuilder: (context, index) {
                      final m = markets[index];
                      return _MarketCard(market: m);
                    },
                  ),
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
              Icons.store_mall_directory_outlined,
              size: 52,
              color: kPrimaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              noobjyet.tr(),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2933),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              addTask.tr(),
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  final Map<String, dynamic> market;

  const _MarketCard({super.key, required this.market});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final name = (market["name"] ?? "").toString();
    final address = (market["address"] ?? "").toString();
    final type = (market["type"] ?? "").toString();
    final workHours = (market["workHours"] ?? "").toString();
    final id = (market["id"] ?? market["_id"] ?? "").toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // иконка слева
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.store,
                  color: kPrimaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // текстовая часть
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // название
                    Text(
                      name.isEmpty ? noNameM.tr() : name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2933),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // адрес
                    if (address.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    // чипы: тип + часы работы
                    Row(
                      children: [
                        if (type.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(
                              255,
                              84,
                              123,
                              154,
                            ).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.category_outlined,
                                  size: 14,
                                  color: Color.fromARGB(
                              255,
                              84,
                              123,
                              154,
                            ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  type,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (type.isNotEmpty && workHours.isNotEmpty)
                          const SizedBox(width: 8),
                        if (workHours.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Color(0xFF4C6FFF),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  workHours,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF4C6FFF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // id внизу мелким шрифтом
                    if (id.isNotEmpty)
                      Text(
                        "ID: $id",
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
