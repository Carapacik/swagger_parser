import 'package:flutter/material.dart';

class LabeledCheckbox extends StatelessWidget {
  const LabeledCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(!value);
      },
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          Checkbox(
            fillColor: MaterialStateProperty.all(const Color(0xFFD0BCFF)),
            value: value,
            onChanged: (newValue) {
              onChanged(newValue!);
            },
          ),
        ],
      ),
    );
  }
}
