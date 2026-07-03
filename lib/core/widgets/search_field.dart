import 'package:flutter/material.dart';
import '../utils/context_extension.dart';

class SearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final void Function(String)? onChanged;
  final void Function()? onClear;

  const SearchField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _showClearButton = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final show = _controller.text.isNotEmpty;
    if (_showClearButton != show) {
      setState(() {
        _showClearButton = show;
      });
    }
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText ?? context.translate('search_placeholder'),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: context.colorScheme.onSurface.withOpacity(0.5),
        ),
        suffixIcon: _showClearButton
            ? IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: context.colorScheme.onSurface.withOpacity(0.5),
                ),
                onPressed: _handleClear,
              )
            : null,
      ),
    );
  }
}
