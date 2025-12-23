import 'package:flutter/material.dart';

class WeekCalendarFilter extends StatelessWidget {
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDayTap;

  final Color selectedColor;
  final Color todayColor;
  final Color pillColor;

  const WeekCalendarFilter({
    super.key,
    required this.selectedDay,
    required this.onDayTap,
    this.selectedColor = Colors.black,
    this.todayColor = const Color.fromARGB(255, 54, 108, 244),
    this.pillColor = const Color(0xFFF2F2F2),
  });

  static const _weekdaysRu = ["П", "В", "С", "Ч", "П", "С", "В"];

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _startOfWeekMonday(DateTime d) {
    final date = _dateOnly(d);
    final diff = date.weekday - DateTime.monday;
    return date.subtract(Duration(days: diff));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final baseWeekStart = _startOfWeekMonday(today);

    const weeksAround = 52;
    final initialPage = weeksAround;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Высота приходит от Expanded/Flexible сверху
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 86.0;

        return SizedBox(
          height: h,
          child: PageView.builder(
            physics: const BouncingScrollPhysics(),
            controller: PageController(
              initialPage: initialPage,
              viewportFraction: 0.92,
            ),
            itemCount: weeksAround * 2 + 1,
            itemBuilder: (context, index) {
              final weekStart =
                  baseWeekStart.add(Duration(days: (index - initialPage) * 7));

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: List.generate(7, (i) {
                      final day = _dateOnly(weekStart.add(Duration(days: i)));
                      final isSelected = selectedDay != null &&
                          _isSameDay(day, _dateOnly(selectedDay!));
                      final isToday = _isSameDay(day, today);

                      final isFuture = day.isAfter(today);
                      final weekdayColor =
                          isFuture ? Colors.grey.shade500 : Colors.black54;

                      Color dayTextColor;
                      if (isSelected) {
                        dayTextColor = Colors.white;
                      } else if (isToday) {
                        dayTextColor = todayColor;
                      } else {
                        dayTextColor =
                            isFuture ? Colors.grey.shade500 : Colors.black87;
                      }

                      return Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => onDayTap(day),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _weekdaysRu[i],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: weekdayColor,
                                ),
                              ),
                              const SizedBox(height: 5),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? selectedColor
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  "${day.day}",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: dayTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              SizedBox(
                                height: 5,
                                child: (!isSelected && isToday)
                                    ? Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: todayColor,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
