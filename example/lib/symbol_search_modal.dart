import 'package:example/custom_text_field.dart';
import 'package:flutter/material.dart';

class SymbolsSearchModal extends StatefulWidget {
  const SymbolsSearchModal({
    super.key,
    required this.onSelect,
    required this.symbols,
  });

  final Function(String symbol) onSelect;
  final List<String> symbols;

  @override
  State<SymbolsSearchModal> createState() => _SymbolSearchModalState();
}

class _SymbolSearchModalState extends State<SymbolsSearchModal> {
  String symbolSearch = "";

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          height: MediaQuery.of(context).size.height * 0.75,
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomTextField(
                  onChanged: (value) {
                    setState(() {
                      symbolSearch = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  children: widget.symbols
                      .where((element) => element
                          .toLowerCase()
                          .contains(symbolSearch.toLowerCase()))
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 50,
                            height: 30,
                            child: RawMaterialButton(
                              elevation: 0,
                              fillColor: const Color(0xFF494537),
                              onPressed: () {
                                widget.onSelect(e);
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                e,
                                style: const TextStyle(
                                  color: Color(0xFFF0B90A),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
