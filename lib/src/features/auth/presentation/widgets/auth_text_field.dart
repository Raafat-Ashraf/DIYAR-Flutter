import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.textInputAction,
    this.prefixIcon,
    this.maxLines = 1,
    this.hintText,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final int? maxLines;
  final String? hintText;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _hidden = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _hidden,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        hintMaxLines: 10,
        hintStyle: TextStyle(
          fontSize: 12.5,
          height: 1.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: .7),
        ),
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        alignLabelWithHint:
            widget.maxLines != null && widget.maxLines! > 1 && !widget.obscureText,
        // Eye toggle on the LEFT (trailing in RTL) for password fields
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
    );
  }
}
