# OpenEMS Add-ons for Home Assistant

Home Assistant add-on repository for [OpenEMS](https://openems.github.io/openems.io/) components.

## Add-ons

### [OpenEMS Edge](openems_edge/)

Runs OpenEMS Edge alongside Home Assistant for local energy management. Pairs with the [ha_openems](https://github.com/Lamarqe/ha_openems) HACS integration.

## Testing

Run the smoke test locally (requires Docker or Podman):

```
./test.sh
```

This builds the image, starts the container, and verifies that the entrypoint creates persistent directories, sets up symlinks, creates the non-root user, and launches OpenEMS.

## Installation

1. Go to **Settings > Add-ons > Add-on Store**.
2. Click the three-dot menu and select **Repositories**.
3. Add this URL: `https://github.com/rp3e11/open_ems_ha`
4. The **OpenEMS Edge** add-on will appear in the store.
