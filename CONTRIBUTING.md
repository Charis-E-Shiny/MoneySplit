# Contributing

Thanks for helping improve Paisa Vasool. Contributions should keep the prototype's limitations clear and must not introduce claims that demo payments or sample offers are real.

## Before you start

- Search existing issues and pull requests before starting substantial work.
- For a large change, open an issue first to agree on scope.
- Keep changes focused and include tests for behavior changes.
- Never include secrets, real financial records, or personal account data in a change.

## Development setup

1. Install Flutter with Dart 3.3 or later and the Android SDK.
2. Follow the Firebase and `.env` setup in the README.
3. Install dependencies:

   ```shell
   flutter pub get
   ```

## Validate changes

Run the analyzer and tests before submitting:

```shell
flutter analyze
flutter test
```

Format changed Dart files with:

```shell
dart format <changed-dart-files>
```

For UI changes, include screenshots captured from the app with test or anonymized data. Follow [`docs/screenshots/README.md`](docs/screenshots/README.md).

## Pull requests

- Explain the problem and the approach.
- List the checks you ran and any checks you could not run.
- Call out Firebase rules, authentication, privacy, or payment behavior changes explicitly.
- Update relevant documentation and `.env.example` when configuration changes.
- Do not commit `.env`, signing keys, service account credentials, or generated build output.
- Follow the repository's [Code of Conduct](CODE_OF_CONDUCT.md).
