# Privacy and data handling

> **Draft for maintainers; not a publishable legal privacy policy.** Confirm the Firebase project configuration, service providers, retention practices, contact details, and applicable legal requirements before publishing or distributing the app.

## Data handled by the current code

Based on the application code in this repository:

- Firebase Authentication handles account credentials and identity-provider sign-in. Email/password and Google sign-in are implemented; an Apple provider flow is also present.
- The app writes a user profile containing a display name, email address, photo URL, and update timestamp to Cloud Firestore.
- Group documents can contain a group name, category, spending limit, invite code, member identifiers and names, contribution totals, spending/savings totals, and creation time.
- Payment request and transaction documents can contain purchase descriptions, merchant/category/method labels, amounts, savings estimates, votes, status, and timestamps. The current payment flow is a simulated ledger and does not move money.
- If `GEMINI_API_KEY` is configured, prompts and group context assembled by the app are sent to Google's Gemini API. Do not send sensitive information through this feature.
- Firebase Analytics is included as a dependency. Verify whether it is enabled and what events/data the deployed Firebase configuration collects before release.

## Important limitations

The app's data handling depends on the Firebase and Google Cloud projects configured by the operator. This repository does not define a retention schedule, deletion workflow, support contact, or complete account-data export process. The current Firestore rules also allow any authenticated user to read group documents, so do not store real financial data until access rules have been redesigned and tested.

## Release checklist

Before publishing a user-facing privacy notice, maintainers must:

- Identify the legal entity/controller and provide a valid privacy contact.
- Confirm Firebase, Google Sign-In, Gemini, and any future payment providers, their roles, data regions, and applicable terms.
- Document purposes, lawful basis where applicable, retention/deletion periods, user rights, and how account/data deletion is handled.
- Verify Analytics configuration and disclose any collected diagnostics or usage data.
- Remove client-side API secrets and ensure sensitive prompts/data are not sent to third parties without appropriate notice and safeguards.
- Obtain legal review for each target jurisdiction and keep the published notice aligned with the released app.
