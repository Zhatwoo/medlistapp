import 'package:flutter/material.dart';
import 'package:medlistapp/utils/app_colors.dart';

class SearchBarWidget extends StatefulWidget {
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;

  const SearchBarWidget({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onClear,
    this.onSubmitted,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _internalController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
    _hasText = _internalController.text.isNotEmpty;
    _internalController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    } else {
      _internalController.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _internalController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.skyBlue.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.skyBlue.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: _internalController,
        onChanged: (value) {
          widget.onChanged?.call(value);
        },
        onSubmitted: (_) => widget.onSubmitted?.call(),
        style: const TextStyle(
          color: AppColors.deepNavy,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search medications...',
          hintStyle: TextStyle(
            color: AppColors.mediumGray.withOpacity(0.6),
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 10),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.skyBlue,
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          suffixIcon: _hasText
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _internalController.clear();
                        widget.onClear?.call();
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.mediumGray.withOpacity(0.7),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          isDense: true,
        ),
      ),
    );
  }
}

