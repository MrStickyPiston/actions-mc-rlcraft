podman build -t dev-actions-mc .
podman run --rm --env-file .dev.env localhost/dev-actions-mc:latest