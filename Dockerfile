# Wrap the upstream OpenEMS Edge image as a Home Assistant add-on.
#
# Design notes:
#   * /data is HA Supervisor's persistent per-add-on volume (survives updates).
#   * OpenEMS writes its mutable state to:
#         /var/opt/openems/config   (Apache Felix configuration store)
#         /var/opt/openems/data     (runtime data, e.g. embedded H2 DB)
#     We replace those with symlinks into /data so config and data persist
#     across add-on rebuilds.
#   * We do NOT override the upstream ENTRYPOINT/CMD by default — we install
#     a thin wrapper that prepares /data and then exec's the original
#     launch command discovered at runtime.

ARG BUILD_FROM=openems/edge:latest
FROM ${BUILD_FROM}

USER root

# Replace the writable dirs with symlinks into /data. We do this at build
# time so OpenEMS sees the correct paths on first boot.
RUN rm -rf /var/opt/openems/config /var/opt/openems/data \
 && ln -sfn /data/config /var/opt/openems/config \
 && ln -sfn /data/data   /var/opt/openems/data

# Tiny init wrapper that creates /data subdirs on first start and then
# hands off to OpenEMS's own launcher.
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Labels for the Supervisor UI
LABEL \
    io.hass.name="OpenEMS Edge" \
    io.hass.description="OpenEMS Edge inside Home Assistant" \
    io.hass.type="addon" \
    io.hass.version="0.1.0"

ENTRYPOINT ["/run.sh"]
