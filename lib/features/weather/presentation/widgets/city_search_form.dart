import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../logic/bloc/weather_bloc.dart';
import '../../logic/bloc/weather_event.dart';
import '../../logic/bloc/weather_state.dart';

class CitySearchForm extends StatefulWidget {
  const CitySearchForm({this.onSearchSubmitted, super.key});

  final ValueChanged<String>? onSearchSubmitted;

  @override
  State<CitySearchForm> createState() => _CitySearchFormState();
}

class _CitySearchFormState extends State<CitySearchForm> {
  late final TextEditingController _cityController;
  late final FocusNode _cityFocusNode;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController();
    _cityFocusNode = FocusNode();
  }

  void _submitSearch() {
    final city = _cityController.text.trim();

    if (city.isEmpty) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    widget.onSearchSubmitted?.call(city);

    context.read<WeatherBloc>().add(WeatherRequested(city));
  }

  @override
  void dispose() {
    _cityController.dispose();
    _cityFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BlocBuilder<WeatherBloc, WeatherState>(
      buildWhen: (previous, current) {
        return previous is WeatherLoading != (current is WeatherLoading);
      },
      builder: (context, state) {
        final isLoading = state is WeatherLoading;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const Key('citySearchTextField'),
                controller: _cityController,
                focusNode: _cityFocusNode,
                enabled: !isLoading,
                textInputAction: TextInputAction.search,
                autocorrect: false,
                enableSuggestions: true,
                decoration: InputDecoration(
                  labelText: localizations.cityInputLabel,
                  hintText: localizations.cityInputHint,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  if (!isLoading) {
                    _submitSearch();
                  }
                },
              ),
            ),
            SizedBox(width: 12.w),
            SizedBox(
              height: 56.h,
              child: FilledButton(
                key: const Key('citySearchButton'),
                onPressed: isLoading ? null : _submitSearch,
                child: Text(localizations.searchButton),
              ),
            ),
          ],
        );
      },
    );
  }
}
