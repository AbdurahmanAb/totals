// stateless widget
import 'package:flutter/material.dart';
import 'package:totals/data/consts.dart';

class HomeTabs extends StatelessWidget {
  final void Function(int tabId) onChangeTab;
  final int activeTab;
  final List<int> tabs;
  const HomeTabs(
      {super.key,
      required this.tabs,
      required this.activeTab,
      required this.onChangeTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(tabs.length, (index) {
            return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: activeTab == tabs[index]
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: activeTab == tabs[index] ? 2 : 0),
                  ),
                ),
                child: TextButton(
                  onPressed: () => onChangeTab(tabs[index]),
                  style: TextButton.styleFrom(
                    foregroundColor: activeTab == tabs[index]
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                  child: Text(tabs[index] == 0
                      ? "Summary"
                      : AppConstants.banks
                          .firstWhere((element) => element.id == tabs[index])
                          .shortName),
                ));
          }),
        )),
      ),
    );
  }
}
