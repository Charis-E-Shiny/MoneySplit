# Security Policy

## Project status

Paisa Vasool is a prototype. Its current Firestore rules are not suitable for real financial or sensitive user data, payments are simulated, and the optional Gemini key is bundled into the client. Do not use this repository as a production wallet.

## Reporting a vulnerability

Please do not publish vulnerability details in a public issue or pull request. Use GitHub's private vulnerability reporting for this repository if it is enabled. Otherwise, contact the repository maintainers privately through GitHub and include:

- A concise description of the affected component and impact
- Reproduction steps or a proof of concept that does not access another person's data
- Any suggested mitigation

Do not include real credentials, personal information, or financial records. Allow maintainers a reasonable opportunity to investigate and coordinate a fix before public disclosure.

## Security notes for deployments

- Review and test `firestore.rules` for least privilege before connecting real users.
- Keep server credentials and payment-provider secrets off the client.
- Treat all values shipped in `.env` or an APK as public.
- Use a backend for real payment order creation and signature verification.
