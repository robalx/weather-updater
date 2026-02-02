#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
LOC_FILE="$BASE_DIR/locations.conf"
OUT_FILE="$BASE_DIR/data.json"
TMP_FILE="$(mktemp)"

NOW_UTC="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# ---------------------------
# META
# ---------------------------
echo '{' > "$TMP_FILE"
echo '  "meta": {' >> "$TMP_FILE"
echo '    "source": "Open-Meteo (open data)",' >> "$TMP_FILE"
echo '    "source_url": "https://open-meteo.com/",' >> "$TMP_FILE"
echo "    \"generated\": \"$NOW_UTC\"," >> "$TMP_FILE"
echo '    "api_calls": {' >> "$TMP_FILE"

FIRST_API=1
while IFS='|' read -r ID NAME LAT LON; do
  [[ -z "$ID" || "$ID" =~ ^# ]] && continue
  API_URL="https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current_weather=true&hourly=pressure_msl"

  [[ $FIRST_API -eq 0 ]] && echo ',' >> "$TMP_FILE"
  FIRST_API=0

  echo "      \"$ID\": \"$API_URL\"" >> "$TMP_FILE"
done < "$LOC_FILE"

echo '    }' >> "$TMP_FILE"
echo '  },' >> "$TMP_FILE"

# ---------------------------
# DANE LOKALIZACJI
# ---------------------------
echo '  "locations": {' >> "$TMP_FILE"

FIRST_LOC=1
while IFS='|' read -r ID NAME LAT LON; do
  [[ -z "$ID" || "$ID" =~ ^# ]] && continue

  API_URL="https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current_weather=true&hourly=pressure_msl"

  [[ $FIRST_LOC -eq 0 ]] && echo ',' >> "$TMP_FILE"
  FIRST_LOC=0

  echo "    \"$ID\": {" >> "$TMP_FILE"
  echo "      \"code\": \"${ID^^}\"," >> "$TMP_FILE"
  echo "      \"name\": \"$NAME\"," >> "$TMP_FILE"
  echo '      "weather":' >> "$TMP_FILE"

  curl -s "$API_URL" | sed 's/^/      /' >> "$TMP_FILE"

  echo "    }" >> "$TMP_FILE"
done < "$LOC_FILE"

echo '  }' >> "$TMP_FILE"
echo '}' >> "$TMP_FILE"

mv "$TMP_FILE" "$OUT_FILE"
chmod 644 "$OUT_FILE"

echo "OK: data.json updated at $NOW_UTC"
