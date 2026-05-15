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

ARG BUILD_FROM=openems/edge:2026.5.0
ARG UI_FROM=openems/ui-edge:2026.5.0

# Stage 1: pull the prebuilt OpenEMS UI artifacts from upstream. We only
# need the static Angular bundle — we author our own nginx config since
# all proxy targets are known at build time.
FROM ${UI_FROM} AS ui_artifacts

# Stage 2: combined edge + UI runtime
FROM ${BUILD_FROM}

USER root

# Non-root user creation happens in run.sh at runtime so we can
# inspect the base image's existing users and handle errors visibly.

# nginx serves the OpenEMS UI in front of the Java/OSGi edge.
# The edge base is linuxserver/baseimage-alpine, so we use apk.
RUN apk add --no-cache nginx

# Pull the Angular SPA produced by openems/ui-edge.
COPY --from=ui_artifacts /var/www/html/openems /var/www/html/openems

# Install our own nginx server block and strip the default :80 listener
# that would otherwise bind a port we don't want exposed.
COPY openems-ui.conf /etc/nginx/http.d/openems-ui.conf
RUN rm -f /etc/nginx/http.d/default.conf

# Replace the writable dirs with symlinks into /data. We do this at build
# time so OpenEMS sees the correct paths on first boot.
RUN mkdir -p /var/opt/openems \
 && rm -rf /var/opt/openems/config /var/opt/openems/data \
 && ln -sfn /data/config /var/opt/openems/config \
 && ln -sfn /data/data   /var/opt/openems/data

# Tiny init wrapper that creates /data subdirs on first start, launches
# nginx, then hands off to OpenEMS's own launcher.
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Labels for the Supervisor UI — BUILD_VERSION is provided by the
# Supervisor from config.yaml's version field, keeping it in one place.
ARG BUILD_VERSION
LABEL \
    io.hass.name="OpenEMS Edge" \
    io.hass.description="OpenEMS Edge inside Home Assistant" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}"

# Ensure entrypoint runs as root so run.sh can create dirs and chown
# before dropping privileges to the openems user.
USER root
ENTRYPOINT ["/run.sh"]
