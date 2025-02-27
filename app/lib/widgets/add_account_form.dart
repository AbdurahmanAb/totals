import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:totals/components/custom_inputfield.dart';
import 'package:totals/data/consts.dart';
import 'package:totals/widgets/banks_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterAccountForm extends StatefulWidget {
  final void Function() onSubmit;

  const RegisterAccountForm({required this.onSubmit, super.key});

  @override
  State<RegisterAccountForm> createState() => _RegisterAccountFormState();
}

class _RegisterAccountFormState extends State<RegisterAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNumber = TextEditingController();
  final TextEditingController _accountHolderName = TextEditingController();
  int selected_bank = 1;
  bool isFormValid = false;

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var bankAccounts = prefs.getStringList("accounts") ?? [];
      if (bankAccounts.isNotEmpty) {
        for (var i = 0; i < bankAccounts.length; i++) {
          var account = jsonDecode(bankAccounts[i]);
          if (account['accountNumber'] == _accountNumber.text) {
            return;
          }
        }
      }
      bankAccounts.add(jsonEncode({
        "accountNumber": _accountNumber.text,
        "accountHolderName": _accountHolderName.text,
        "bank": selected_bank
      }));
      await prefs.setStringList("accounts", bankAccounts);
      widget.onSubmit();
      Navigator.pop(context);
    }
  }

  void _validateForm() {
    setState(() {
      isFormValid =
          _accountHolderName.text.isNotEmpty && _accountNumber.text.isNotEmpty
              ? true
              : false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      onChanged: _validateForm,
      child: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft, // Aligns text to the left
            child: const Text(
              "New Account",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF444750),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, // Makes the button take full width
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BanksListPage(
                      onBankSelected: (p0) => {
                        setState(() {
                          selected_bank = p0;
                        })
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side:
                      const BorderSide(color: Color.fromRGBO(158, 158, 158, 1)),
                ),
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                AppConstants.banks
                    .firstWhere((element) => element.id == selected_bank)
                    .name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _accountNumber,
            labelText: "Account Number",
            validator: (value) => (value == null || value.isEmpty)
                ? "Enter account number"
                : null,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _accountHolderName,
            labelText: "Account Holder Name",
            validator: (value) => (value == null || value.isEmpty)
                ? "Enter account holder name"
                : null,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Color(0xFF444750),
                  ),
                ),
              ),
              const SizedBox(width: 5), // Small space between buttons
              TextButton(
                onPressed: isFormValid ? _submitForm : null,
                child: Text(
                  "Save",
                  style: TextStyle(
                    color: isFormValid ? Color(0xFF444750) : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
