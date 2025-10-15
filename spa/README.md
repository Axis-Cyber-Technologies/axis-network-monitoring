# Axis Network Monitor SPA (Aurelia)

This directory houses the Aurelia single-page application that mirrors Zenarmor's
UI layout. Use the same build toolchain to produce `axis-app.js` and
`axis-vendor.js`, which are then deployed to the plugin's `src/opnsense/www/js`
folder.

## Development Build

1. Install Node.js (LTS).
2. Install dependencies:
   ```sh
   cd spa/aurelia-app
   npm install
   ```
3. Run the dev server (optional):
   ```sh
   npm start
   ```
4. Build production bundle:
   ```sh
   npm run build
   ```
   Compiled assets appear in `dist/axis-app.js` (and css). Move them into
   `src/opnsense/www/js/axisnetworkmonitor/` replacing the placeholder files.

## Notes
- The current implementation includes placeholder modules for Dashboard, Status,
  Reports, Security, App Controls, Web Controls, Configuration, and Advanced.
  These will be replaced with real components as API endpoints are implemented.
- No licensing code is included; all features will be accessible without cloud
  activation.
