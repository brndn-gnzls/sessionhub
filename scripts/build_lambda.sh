#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build/lambda"
ZIP_PATH="${ROOT_DIR}/build/lambda_package.zip"

rm -rf "${BUILD_DIR}" "${ZIP_PATH}"
mkdir -p "${BUILD_DIR}"

# Build inside a container that matches Lambda's Python 3.12 environment.
# SAM build image is intended for this purpose.
docker run --rm \
  -v "${ROOT_DIR}:/var/task" \
  -w /var/task \
  --entrypoint /bin/bash \
  public.ecr.aws/sam/build-python3.12:latest \
  -lc '
    python -m pip install --upgrade pip &&
    # Install your package + runtime deps directly into the target dir
    pip install --target build/lambda . &&
    # Trim caches
    find build/lambda -type d -name "__pycache__" -prune -exec rm -rf {} + || true
  '

# Ensure your source package is present (for good measure)
rsync -a api/ "${BUILD_DIR}/api/"

# Create the deployment zip with files at the ZIP *root* (required by Lambda)
( cd "${BUILD_DIR}" && zip -qr9 "${ZIP_PATH}" . )

echo "Created ${ZIP_PATH}"