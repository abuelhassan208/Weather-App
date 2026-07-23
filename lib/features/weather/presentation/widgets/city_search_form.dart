import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../logic/bloc/weather_bloc.dart';
import '../../logic/bloc/weather_event.dart';
import '../../logic/bloc/weather_state.dart';

class CitySearchForm extends StatefulWidget {
  const CitySearchForm({super.key});

  @override
  State<CitySearchForm> createState() => _CitySearchFormState();
}

class _CitySearchFormState extends State<CitySearchForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cityController;
  late final FocusNode _cityFocusNode;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController();
    _cityFocusNode = FocusNode();
  }

  void _submitSearch() {
    if (!_formKey.currentState!.validate()) {
      _cityFocusNode.requestFocus();
      return;
    }
    final city = _cityController.text.trim();

    FocusManager.instance.primaryFocus?.unfocus();

    context.read<WeatherBloc>().add(
      WeatherRequested(
        city,
        languageCode: Localizations.localeOf(context).languageCode,
      ),
    );
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

        return Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stackControls = constraints.maxWidth < 420;
              final field = TextFormField(
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
                  prefixIcon: const Icon(Icons.location_city_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? localizations.emptyCityValidation
                    : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onFieldSubmitted: (_) {
                  if (!isLoading) {
                    _submitSearch();
                  }
                },
              );
              final button = FilledButton.icon(
                key: const Key('citySearchButton'),
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: isLoading ? null : _submitSearch,
                icon: const Icon(Icons.search),
                label: Text(localizations.searchButton),
              );

              if (stackControls) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    field,
                    SizedBox(height: 12.h),
                    button,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: field),
                  SizedBox(width: 12.w),
                  button,
                ],
              );
            },
          ),
        );
      },
    );
  }
}
