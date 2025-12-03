#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

echo " Building lambda.zip ..."

# Clean previous build
rm -rf build lambda.zip
mkdir -p build

# Copy handler + CA bundle
cp app.py build/
cp global-bundle.pem build/

# Install dependencies
pip install -r requirements.txt -t build >/dev/null

echo " Packaging using Python zip library"

python << 'EOF'
import os, zipfile

build_dir = "build"
zip_name = "lambda.zip"

with zipfile.ZipFile(zip_name, "w", zipfile.ZIP_DEFLATED) as z:
    # Walk the build directory and add everything at zip root
    for root, dirs, files in os.walk(build_dir):
        for f in files:
            full_path = os.path.join(root, f)
            arcname = os.path.relpath(full_path, build_dir)  # ensures no 'build/' prefix
            z.write(full_path, arcname)

print("✔ lambda.zip created with python zip")
EOF

echo " Lambda packaged: lambda.zip"
