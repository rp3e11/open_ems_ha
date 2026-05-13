# Changelog

## 0.1.0

- Initial release
- Wraps upstream `openems/edge:2026.5.0` image
- Persistent config and data via `/data` volume
- Custom bundle support via `/data/bundles`
- Felix Web Console accessible via Open Web UI button (port 8080)
- Runs as non-root `openems` user
- Custom AppArmor profile scoped to the entrypoint commands, Java runtime, OpenEMS launchers, and persistent data paths
- Watchdog health check on WebSocket port 8085
