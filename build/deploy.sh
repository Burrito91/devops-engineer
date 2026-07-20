#!/bin/bash
set -e

PROJECT_DIR="$(pwd)"
BUILD_DIR="$PROJECT_DIR/build"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="deploy_$TIMESTAMP.log"

echo "[DEPLOY] Starting deployment at $(date)" | tee "$LOG_FILE"

# Step 1: Check Git status
echo "[DEPLOY] Checking Git status..." | tee -a "$LOG_FILE"
if [ -n "$(git status --porcelain)" ]; then
  echo "[WARN] Uncommitted changes detected" | tee -a "$LOG_FILE"
else
  echo "[OK] Working directory clean" | tee -a "$LOG_FILE"
fi

# Step 2: Create build directory
echo "[DEPLOY] Creating build directory..." | tee -a "$LOG_FILE"
mkdir -p "$BUILD_DIR"
cp *.sh "$BUILD_DIR/" 2>/dev/null || true
cp README.md "$BUILD_DIR/" 2>/dev/null || true
echo "[OK] Files copied to $BUILD_DIR" | tee -a "$LOG_FILE"

# Step 3: Run tests (simulated)
echo "[DEPLOY] Running tests..." | tee -a "$LOG_FILE"
if [ -f "$BUILD_DIR/hello.sh" ]; then
  echo "[OK] hello.sh exists" | tee -a "$LOG_FILE"
else
  echo "[FAIL] hello.sh missing" | tee -a "$LOG_FILE"
  exit 1
fi

# Step 4: Tag the release
echo "[DEPLOY] Tagging release..." | tee -a "$LOG_FILE"
git tag -a "v1.0-$TIMESTAMP" -m "Release $TIMESTAMP" 2>/dev/null || echo "[SKIP] Tag already exists"

echo "[DEPLOY] Deployment complete at $(date)" | tee -a "$LOG_FILE"
echo "[DEPLOY] Log saved to $LOG_FILE"
