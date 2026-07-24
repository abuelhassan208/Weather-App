# Weather App

A Flutter technical assessment that retrieves and presents current weather
data for a searched city using WeatherAPI.

## Overview

The app demonstrates a small, testable Flutter application with explicit
loading, success, cached-data, and error states. It supports English and Arabic,
persists the selected language, and can fall back to recent local weather data
when a network request cannot be completed.

## Features

- Search current weather by city.
- Loading, success, validation, and localized error states.
- Retry the latest search.
- English and Arabic localization with LTR and RTL layouts.
- Responsive layouts for small phones, tablets, and wide screens.
- Per-city and per-language offline cache with a cached-data indicator.
- BLoC-managed splash screen.
- Global BLoC observation and sanitized local logging.
- Semantics, text scaling, and accessible touch targets.

## Architecture

The main weather flow is:

```text
Presentation → WeatherBloc → WeatherRepository → WeatherService / CacheService
```

Presentation formatters convert domain-facing weather values into localized
display models before rendering. The splash screen is an independent feature
with its own BLoC, while a global `BlocObserver` records lifecycle and state
metadata. HTTP logs pass through a central sanitizer before reaching the local
logger.

## Project Structure

```text
lib/
├── core/
│   ├── localization/
│   ├── logging/
│   ├── network/
│   └── observers/
├── features/
│   ├── splash/
│   └── weather/
│       ├── data/
│       ├── logic/
│       └── presentation/
├── l10n/
├── app.dart
└── main.dart
```

## Tech Stack

- Flutter and Dart
- `flutter_bloc`, `bloc_concurrency`, and `equatable`
- `dio`
- `shared_preferences`
- `internet_connection_checker_plus`
- `flutter_dotenv`
- `flutter_screenutil`
- Flutter localization and `intl`
- `flutter_test`, `bloc_test`, and `mocktail`

## API

Current conditions are loaded from the WeatherAPI current-weather endpoint.
The API key is supplied locally through an environment file and is never
included in source code.

## Environment Setup

Create a local environment file from the tracked example:

```bash
cp .env.example .env
```

Set your WeatherAPI key in `.env`:

```dotenv
WEATHER_API_KEY=your_weatherapi_key
```

The `.env` file is ignored by Git.

## Running the Project

Install dependencies and start the application:

```bash
flutter pub get
flutter run
```

## Testing

Run static analysis and the test suite:

```bash
flutter analyze
flutter test
```

The suite includes unit, BLoC, network, service, repository, cache, formatter,
localization, and widget tests. Tests do not make real network requests.

## Caching Strategy

Weather responses are cached by normalized city and language. Each entry
contains a schema version and UTC timestamp and expires after 30 minutes.
Recent cache data may be used when the device is offline or a request fails
with a network timeout. Invalid, mismatched, expired, or corrupted entries are
removed, and cached results are identified in the UI.

## Error Handling

Dio failures are mapped to application exceptions before reaching the BLoC.
The UI provides localized states for invalid cities, missing connectivity,
timeouts, unauthorized access, server failures, cache errors, configuration
errors, and unexpected failures. Restartable event handling ensures a newer
search supersedes an older request result.

## Logging

Request method, path, status, duration, cache decisions, and BLoC lifecycle
metadata are logged locally. In debug builds, bounded request and response
details may be logged after sanitization. API keys, authorization headers,
cookies, tokens, and nested secrets are redacted. Release logging excludes
request and response bodies and suppresses verbose levels.

## Localization

English and Arabic are supported. The selected locale is persisted locally,
API condition text is requested in the active language where supported, and
the interface follows the corresponding LTR or RTL direction.

## Accessibility and Responsive Design

The UI includes semantic labels, live error announcements, accessible touch
targets, and text-scale support. Layouts adapt between stacked and horizontal
controls and are tested across small, large, and wide surfaces.

## Security Notes

- The API key is not committed to Git.
- Sensitive HTTP metadata is sanitized before logging.
- A key embedded in any client application can still be extracted from its
  compiled package.
- A production deployment should use provider restrictions and quotas, or a
  backend proxy when the key must remain confidential.

## Trade-offs

- The WeatherAPI key remains client-side for assignment simplicity.
- Cached weather is local, device-specific, and time-limited.
- The splash screen uses a fixed 1.2-second duration.
- Logging is local and is not connected to remote monitoring.

## Possible Improvements

- Add end-to-end integration tests on supported devices.
- Add remote crash reporting with an explicit privacy policy.
- Extend the UI with forecasts and additional weather details.
- Introduce a dependency-injection container if the composition root grows.

## Assignment Notes

This application was created as a Flutter technical assessment focused on
state management, networking, resilience, localization, accessibility, and
testability.
