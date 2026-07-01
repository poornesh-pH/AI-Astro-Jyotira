Swiss Ephemeris data files (.se1)
=================================
For full astronomical precision, place the Swiss Ephemeris data files here, e.g.:
  seas_18.se1   sepl_18.se1   semo_18.se1
 
The `sweph` Flutter package bundles a default ephemeris asset, so the app still
runs without these. For production accuracy across a wide date range, obtain the
.se1 files from the official Swiss Ephemeris distribution (AGPL / professional
license — review licensing for commercial use) and add them to this folder, then
list them in pubspec.yaml under flutter: assets:.
