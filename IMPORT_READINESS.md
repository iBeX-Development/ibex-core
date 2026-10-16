# Core import copy — review required

This is an incomplete, sanitized source import. It has not been built or run. Do not describe it as runnable Core. Preserve the destination repository's initial commit and README when importing.

## Import boundary

The `source/` directory is the only proposed repository root. Copy and stage only exact relative paths recorded in the latest reviewed import manifest; verify their hashes before import. Never use the parent task/workspace as the repository root or recursively copy its contents. Sibling `approved-remediation/`, `readiness-review/`, scanner, withheld-source, and other evidence directories are not source and must never be imported. Some preserve original sensitive candidates.

The root `.gitignore` is defense in depth, not authorization or a substitute for manifest-only copying/staging. It does not sanitize tracked files or history. Example environment templates remain visible for review, not automatically approved. The narrow `!ios/Podfile.lock` rule in `mobile/.gitignore` keeps the specifically reviewed dependency lockfile visible; never force-add arbitrary ignored paths.

## Approved disabled behavior

- Server upstream authentication requires `CORE_UPSTREAM_USERNAME` and `CORE_UPSTREAM_PASSWORD`. Missing values stop that login before its HTTP request. Provide secrets through the deployment's secret/configuration mechanism; never use frontend public configuration.
- The trigger-administration shell script requires an operator-supplied `PGPASSWORD`. Its SQL operation and other arguments are retained. It was not executed.
- Both company-management pages disable new company/admin provisioning before any associated role, policy, company, or user writes. Existing listing/editing/deletion code is retained. A proper provisioning flow must be reviewed before creation can be re-enabled. No fixed password or public password environment setting is supplied.
- Mobile credential autofill, preset account credentials, and remembered-credential persistence are disabled in the login screen. Users can enter credentials manually and use the existing sign-in flow. Existing stored data is not deleted by this import patch.

## Optional client integrations

Client configuration is visible in browser/mobile builds. It is not a place for server credentials. Before supplying API keys, the owner must verify the intended projects and key restrictions; this import did not validate keys against any service.

Web Firebase configuration uses Nuxt public runtime fields, with no embedded deployment values:

- `NUXT_PUBLIC_FIREBASE_API_KEY`
- `NUXT_PUBLIC_FIREBASE_PROJECT_ID`
- `NUXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID`
- `NUXT_PUBLIC_FIREBASE_APP_ID`
- `NUXT_PUBLIC_FIREBASE_AUTH_DOMAIN`, `NUXT_PUBLIC_FIREBASE_STORAGE_BUCKET`, `NUXT_PUBLIC_FIREBASE_MEASUREMENT_ID` as appropriate
- `NUXT_PUBLIC_FIREBASE_VAPID_KEY`

Web messaging stays disabled if required configuration is missing or the approved `/firebase-messaging-sw.js` service worker is not already registered and active. The original deployment-specific worker is excluded; provision a reviewed worker separately. The import does not register or download one automatically.

Mobile Firebase uses per-build `String.fromEnvironment` values: `CORE_FIREBASE_API_KEY`, `CORE_FIREBASE_APP_ID`, `CORE_FIREBASE_MESSAGING_SENDER_ID`, and `CORE_FIREBASE_PROJECT_ID`. The new configuration module contains no original deployment values. Missing configuration skips Firebase initialization and messaging calls. Native deployment/signing configuration is still excluded and must be supplied separately before an integration-enabled build can be validated.

Mobile Google Calendar uses `CORE_GOOGLE_CALENDAR_API_KEY` and `CORE_GOOGLE_CALENDAR_ID`. If either is absent, it returns no Google events without making that request; local/leave event handling remains represented. Client values are not secret storage.

## Known omissions and limitations

Unresolved contact/profile/account fixture source remains excluded:

- `frontend/.app/components/global/AddonMapboxPanel.vue`
- `frontend/.app/components/global/WorkOrderContractMore.vue`
- `frontend/.app/pages/mytask/profile.vue`

References to these components/pages may still be present. Their features are unavailable and dependent routes/builds can fail until a separate reviewed resolution exists. No substitute customer facts or synthetic records were fabricated.

Also excluded: original `.env` and service-account files, deployment key, uploads/customer datasets, native signing configuration (including the original iOS project settings), Google/Firebase deployment JSON/plists, dependencies/caches/generated output, unreviewed images/fonts/audio and other binary assets, Gradle wrapper JAR, archived symlinks, and nested archives. Restored asset catalogs and resources can reference excluded images. Four original mobile source files were empty and remain so.

## Verification boundaries

Gitleaks runs use verified v8.30.0, trusted upstream default rules, disabled candidate suppressions, and metadata-only redacted reports. The three known Podfile.lock matches are dependency SHA-1 records; no broad scanner suppression is installed. Password/contact-pattern triage supplements the scanner and includes false positives for labels and translation strings.

Checks performed for this import do not execute Core, install dependencies, contact live APIs/databases, test credentials, validate API restrictions, prove asset licensing, or establish runtime compatibility. Native Dart/Flutter compilation and full Nuxt type/build checks remain outstanding. Independent review must precede any upload.
