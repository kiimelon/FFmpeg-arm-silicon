#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="twolame"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

mkdir -p "$LOGS"
cd "$SRC_DIR"

make distclean >/dev/null 2>&1 || true

TOOLS_DIR="$BUILD/tools"
mkdir -p "$TOOLS_DIR"

cat > "$TOOLS_DIR/libtoolize" <<'EOF'
#!/usr/bin/env bash
exec /opt/homebrew/bin/glibtoolize "$@"
EOF

chmod +x "$TOOLS_DIR/libtoolize"

export PATH="$TOOLS_DIR:$PATH"
export LIBTOOLIZE="$TOOLS_DIR/libtoolize"
unset LIBTOOL

if [ ! -x "./configure" ]; then
  ./autogen.sh 2>&1 | tee "$LOG_FILE"
else
  : > "$LOG_FILE"
fi

./configure \
  --prefix="$PREFIX" \
  --host=arm-apple-darwin \
  --disable-maintainer-mode \
  2>&1 | tee -a "$LOG_FILE"

# twolame upstream doc/ build bug:
# remove doc from recursive make targets after configure
if [ -f Makefile ]; then
  sed -i '' 's/ doc / /g; s/ doc$//g; s/^doc //g' Makefile
fi

make $MAKEFLAGS 2>&1 | tee -a "$LOG_FILE"
make install 2>&1 | tee -a "$LOG_FILE"

echo
echo "==== verify twolame ====" | tee -a "$LOG_FILE"

test -f "$PREFIX/include/twolame.h" \
  && echo "[ok] twolame header found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing twolame header" | tee -a "$LOG_FILE"; exit 1; }

ls "$PREFIX/lib"/libtwolame* >/dev/null 2>&1 \
  && echo "[ok] libtwolame found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing libtwolame" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion twolame 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs twolame 2>&1 | tee -a "$LOG_FILE"
