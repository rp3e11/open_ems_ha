# OpenEMS Edge

Run [OpenEMS Edge](https://openems.github.io/openems.io/openems/latest/edge/architecture.html) as a Home Assistant add-on for local energy management — **with the OpenEMS UI bundled in the same container**.

- Wraps the upstream `openems/edge` Docker image
- Bundles the upstream `openems/ui-edge` Angular SPA (served by nginx in the same container)
- Persistent configuration across add-on updates
- Pairs with [ha_openems](https://github.com/Lamarqe/ha_openems) for HA integration
- Custom Felix bundle support via add-on config directory

## Ports

| Port | Purpose |
|------|---------|
| 8766 | OpenEMS UI (Angular SPA, what you see from the sidebar / ingress) |
| 8765 | Apache Felix Web Console (low-level OSGi admin at `/system/console`) |
| 8764 | OpenEMS Edge WebSocket (only listens once `Controller.Api.Websocket` is configured) |

See the **Documentation** tab for setup instructions.
