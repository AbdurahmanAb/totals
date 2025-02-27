import 'package:flutter/material.dart';
import 'package:totals/data/consts.dart';

class BanksListPage extends StatefulWidget {
  final Function(int) onBankSelected;

  BanksListPage({required this.onBankSelected});

  @override
  _BanksListPageState createState() => _BanksListPageState();
}

class _BanksListPageState extends State<BanksListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Choose Bank', style: TextStyle(fontSize: 20)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Creates 3 columns
          crossAxisSpacing: 12, // Horizontal spacing between items
          mainAxisSpacing: 12, // Vertical spacing between items
          childAspectRatio: 0.75, // Adjust this value to control item height
        ),
        itemCount: AppConstants.banks.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              widget.onBankSelected(AppConstants.banks[index].id);
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        AppConstants.banks[index].image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.banks[index].name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF444750),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
