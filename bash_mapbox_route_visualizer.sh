#!/usr/bin/env bash

# This script was developed with the assistance of Claude Sonnet 3.5, an AI language model created by Anthropic.

# DISCLAIMER: USE AT YOUR OWN RISK
# This script is provided "as is" without any warranties or guarantees of any kind, either expressed or implied.
# The user assumes all responsibility and risk for the use of this script. The authors and contributors
# are not liable for any damages or losses resulting from the use or misuse of this script.
# Always review and test the script thoroughly before using it in any critical or production environment.

locations=(
  "Charleston, WV|blue"
  "Harpers Ferry, WV|gray"
  "Philadelphia, PA|gray"
  "Promised Land, PA|gray"
  "Brooklyn, NY|gray"
  "Sturbridge, MA|gray"
  "Pownal, ME|gray"
  "Deer Isle, ME|gray"
)

# Mapbox API parameters
USERNAME="ankurkwv"
ACCESS_TOKEN="$MAPBOX_ACCESS_TOKEN"
TILESET_NAME="bash_mapbox_route_visualizer" # Can be anything!
TODAYS_DATE=$(date "+%B %d, %Y")

# Image parameters
WIDTH=1280
HEIGHT=900
ZOOM=3.5

# Output image filename
OUTPUT_IMAGE=""

# Initialize total variables
visited_miles_total=0
miles_total=0
visited_hours_total=0
hours_total=0

# Function to URL encode a string
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * )               printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}

# Function to geocode a location
geocode() {
    local location="$1"
    local encoded_location=$(urlencode "$location")
    local url="https://api.mapbox.com/geocoding/v5/mapbox.places/${encoded_location}.json?access_token=${ACCESS_TOKEN}"
    local response=$(curl -s "$url")
    local coords=$(echo $response | jq -r '.features[0].center | "\(.[0]),\(.[1])"')
    echo "$coords|$location"
}

# Main script execution starts here

# Find the last blue city and set the output image filename
LAST_BLUE_CITY=""
for location in "${locations[@]}"; do
    IFS='|' read -r city color <<< "$location"
    if [ "$color" == "blue" ]; then
        formatted_city=$(echo "$city" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//')
        LAST_BLUE_CITY="$formatted_city"
    fi
done
OUTPUT_IMAGE="road_trip_map_until_${LAST_BLUE_CITY}.png"

echo -e "\n\033[1;36m🌎 Starting Your Road Trip Adventure! 🚗\033[0m\n"

echo -e "\033[1;33m📍 Geocoding locations using Mapbox geocoding/v5...\033[0m"
geocoded_locations=()
for location_info in "${locations[@]}"; do
    IFS='|' read -r location color <<< "$location_info"
    geocoded_info=$(geocode "$location")
    geocoded_locations+=("$geocoded_info|$color")
    echo -e "  \033[0;32m✓\033[0m $location ($color): $geocoded_info"
done

echo -e "\n\033[1;33m📝 Geocoding routes using Mapbox directions/v5...\033[0m"
geojson='{"type":"FeatureCollection","features":['

# Add points to GeoJSON
for location_info in "${geocoded_locations[@]}"; do
    IFS='|' read -r coords location color <<< "$location_info"
    geojson+='{"type":"Feature","geometry":{"type":"Point","coordinates":['"$coords"']},"properties":{"name":"'"$location"'","color":"'"$color"'"}},'
done

# Add routes to GeoJSON and calculate totals
for i in $(seq 0 $((${#geocoded_locations[@]} - 2))); do
    IFS='|' read -r start start_location start_color <<< "${geocoded_locations[$i]}"
    IFS='|' read -r end end_location end_color <<< "${geocoded_locations[$((i+1))]}"

    route_color="$start_color"

    # Get directions
    directions_url="https://api.mapbox.com/directions/v5/mapbox/driving/${start};${end}?geometries=geojson&overview=full&access_token=${ACCESS_TOKEN}"
    directions_response=$(curl -s "$directions_url")
    echo -e "  \033[0;32m✓\033[0m Fetched directions for ${start_location} to ${end_location}"
    route_geometry=$(echo "$directions_response" | jq -c '.routes[0].geometry')

    # Extract and format distance and duration
    distance_miles=$(echo "$directions_response" | jq -r '.routes[0].distance | . / 1609.344')
    duration_hours=$(echo "$directions_response" | jq -r '.routes[0].duration | . / 3600')
    distance_miles=$(printf "%.2f" $distance_miles)
    duration_hours=$(printf "%.2f" $duration_hours)

    # Update totals
    miles_total=$(echo "$miles_total + $distance_miles" | bc)
    hours_total=$(echo "$hours_total + $duration_hours" | bc)

    if [ "$route_color" = "blue" ]; then
        visited_miles_total=$(echo "$visited_miles_total + $distance_miles" | bc)
        visited_hours_total=$(echo "$visited_hours_total + $duration_hours" | bc)
    fi

    geojson+='{"type":"Feature","geometry":'"$route_geometry"',"properties":{"start":"'"$start_location"'","end":"'"$end_location"'","color":"'"$route_color"'"}},'
done

# Finalize GeoJSON
geojson=${geojson%,}
geojson+=']}'

# Check if the file exists, if not create it
if [ ! -f "route.geojson" ]; then
    touch route.geojson
    if [ $? -ne 0 ]; then
        echo -e "  \033[0;31m✗\033[0m Failed to create route.geojson. Exiting."
        exit 1
    fi
fi

# Write the GeoJSON to the file
if ! echo "$geojson" > route.geojson; then
    echo -e "  \033[0;31m✗\033[0m Failed to write to route.geojson. Exiting."
    exit 1
fi
echo -e "  \033[0;32m✓\033[0m GeoJSON saved as route.geojson"

# Format total variables
visited_miles_total=$(printf "%'d" ${visited_miles_total%.*})
miles_total=$(printf "%'d" ${miles_total%.*})
visited_hours_total=$(printf "%'d" ${visited_hours_total%.*})
hours_total=$(printf "%'d" ${hours_total%.*})

echo -e "\n\033[1;33m📊 Trip Statistics:\033[0m"
echo -e "  \033[0;36m•\033[0m Visited miles: \033[1m$visited_miles_total\033[0m"
echo -e "  \033[0;36m•\033[0m Total miles: \033[1m$miles_total\033[0m"
echo -e "  \033[0;36m•\033[0m Visited hours: \033[1m$visited_hours_total\033[0m"
echo -e "  \033[0;36m•\033[0m Total hours: \033[1m$hours_total\033[0m"

sleep 3
echo -e "\n\033[1;33m🔑 Getting Mapbox temporary S3 credentials...\033[0m"
CREDENTIALS=$(curl -s -X POST "https://api.mapbox.com/uploads/v1/${USERNAME}/credentials?access_token=${ACCESS_TOKEN}")

sleep 3
# Extract S3 details from credentials
BUCKET=$(echo $CREDENTIALS | jq -r '.bucket')
KEY=$(echo $CREDENTIALS | jq -r '.key')
ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.accessKeyId')
SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.secretAccessKey')
SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.sessionToken')

echo -e "\n\033[1;33m☁️  Uploading file to S3...\033[0m"
CURRENT_DATE=$(date -u '+%a, %d %b %Y %H:%M:%S GMT')
STRING_TO_SIGN="PUT\n\napplication/json\n${CURRENT_DATE}\nx-amz-acl:public-read\nx-amz-security-token:${SESSION_TOKEN}\n/${BUCKET}/${KEY}"
SIGNATURE=$(echo -en ${STRING_TO_SIGN} | openssl sha1 -hmac ${SECRET_ACCESS_KEY} -binary | base64)

UPLOAD_RESPONSE=$(curl -X PUT -T route.geojson \
  -H "Host: ${BUCKET}.s3.amazonaws.com" \
  -H "Date: ${CURRENT_DATE}" \
  -H "Content-Type: application/json" \
  -H "Authorization: AWS ${ACCESS_KEY_ID}:${SIGNATURE}" \
  -H "x-amz-security-token: ${SESSION_TOKEN}" \
  -H "x-amz-acl: public-read" \
  "https://${BUCKET}.s3.amazonaws.com/${KEY}")

echo -e "  \033[0;32m✓\033[0m S3 upload completed successfully!"

if [ $? -ne 0 ]; then
  echo -e "  \033[0;31m✗\033[0m S3 upload failed. Exiting."
  exit 1
fi

echo -e "\n\033[1;33m🗺️  Creating Mapbox Tileset upload...\033[0m"
UPLOAD_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
  -d "{\"url\": \"http://${BUCKET}.s3.amazonaws.com/${KEY}\", \"tileset\": \"${USERNAME}.${TILESET_NAME}\"}" \
  "https://api.mapbox.com/uploads/v1/${USERNAME}?access_token=${ACCESS_TOKEN}")

UPLOAD_ID=$(echo $UPLOAD_RESPONSE | jq -r '.id')

echo -e "  \033[0;32m✓\033[0m Mapbox Upload ID: \033[1m$UPLOAD_ID\033[0m"

if [ -z "$UPLOAD_ID" ] || [ "$UPLOAD_ID" = "null" ]; then
  echo -e "  \033[0;31m✗\033[0m Failed to get upload ID. Exiting."
  exit 1
fi

echo -e "\n\033[1;33m🔄 Checking Tileset processing status...\033[0m"
ATTEMPTS=0
MAX_ATTEMPTS=30
while true; do
  STATUS_RESPONSE=$(curl -s "https://api.mapbox.com/uploads/v1/${USERNAME}/${UPLOAD_ID}?access_token=${ACCESS_TOKEN}")
  COMPLETE=$(echo $STATUS_RESPONSE | jq -r '.complete')
  PROGRESS=$(echo $STATUS_RESPONSE | jq -r '.progress')
  ERROR=$(echo $STATUS_RESPONSE | jq -r '.error')
  echo -e "  \033[0;36m•\033[0m Complete: $COMPLETE, Progress: $PROGRESS, Error: $ERROR"

  if [ "$COMPLETE" = "true" ]; then
    if [ "$ERROR" != "null" ]; then
      echo -e "  \033[0;31m✗\033[0m Upload failed with error: $ERROR"
      exit 1
    else
      echo -e "  \033[0;32m✓\033[0m Upload completed successfully!"
      break
    fi
  elif [ "$COMPLETE" = "false" ]; then
    echo -e "  \033[0;36m•\033[0m Upload is still processing..."
  else
    echo -e "  \033[0;31m✗\033[0m Unexpected completion status: $COMPLETE"
    exit 1
  fi

  ATTEMPTS=$((ATTEMPTS + 1))
  if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
    echo -e "  \033[0;31m✗\033[0m Maximum number of attempts reached. Exiting."
    exit 1
  fi

  sleep 5
done

echo -e "\n\033[1;33m🖼️  Calculating center and zoom level...\033[0m"

TILESET_ID="${USERNAME}.${TILESET_NAME}"

# Fetch tileset information and extract center coordinates
TILESET_INFO=$(curl -s "https://api.mapbox.com/v4/${TILESET_ID}.json?access_token=${ACCESS_TOKEN}")
CENTER=$(echo $TILESET_INFO | jq -r '.center[0:2] | join(",")')

echo -e "  \033[0;36m•\033[0m Center: $CENTER"
echo -e "  \033[0;36m•\033[0m Zoom: $ZOOM"


# Create a custom style
STYLE_JSON=$(cat <<EOF
{
  "version": 8,
  "name": "Custom Road Trip Style",
  "sources": {
    "mapbox": {
      "type": "vector",
      "url": "mapbox://mapbox.mapbox-streets-v8"
    },
    "road-trip": {
      "type": "vector",
      "url": "mapbox://${TILESET_ID}"
    }
  },
  "layers": [
    {
      "id": "background",
      "type": "background",
      "paint": {
        "background-color": "#f8f4f0"
      }
    },
    {
      "id": "landuse",
      "type": "fill",
      "source": "mapbox",
      "source-layer": "landuse",
      "paint": {
        "fill-color": [
          "match",
          ["get", "class"],
          "park", "#d8e8c8",
          "airport", "#f0e9e7",
          "glacier", "#fff",
          "pitch", "#c8dcc8",
          "sand", "#f8e8c8",
          "recreation_ground", "#e8e8c8",
          "#f8f4f0"
        ]
      }
    },
    {
      "id": "water",
      "type": "fill",
      "source": "mapbox",
      "source-layer": "water",
      "paint": {
        "fill-color": "#a0c8f0"
      }
    },
    {
      "id": "roads",
      "type": "line",
      "source": "mapbox",
      "source-layer": "road",
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          5, 0.5,
          10, 2
        ]
      }
    },
    {
      "id": "admin-country-boundaries",
      "type": "line",
      "source": "mapbox",
      "source-layer": "admin",
      "filter": ["==", ["get", "admin_level"], 0],
      "paint": {
        "line-color": "#8b8a8a",
        "line-width": 1
      }
    },
    {
      "id": "admin-state-boundaries",
      "type": "line",
      "source": "mapbox",
      "source-layer": "admin",
      "filter": ["==", ["get", "admin_level"], 1],
      "paint": {
        "line-color": "#a9a9a9",
        "line-dasharray": [2, 1],
        "line-width": 0.7
      }
    },
    {
      "id": "blue-route",
      "type": "line",
      "source": "road-trip",
      "source-layer": "original",
      "paint": {
        "line-color": "#0000FF",
        "line-width": 3
      },
      "filter": ["==", ["get", "color"], "blue"]
    },
    {
      "id": "gray-route",
      "type": "line",
      "source": "road-trip",
      "source-layer": "original",
      "paint": {
        "line-color": "#808080",
        "line-width": 3
      },
      "filter": ["==", ["get", "color"], "gray"]
    },
    {
      "id": "points",
      "type": "circle",
      "source": "road-trip",
      "source-layer": "original",
      "paint": {
        "circle-radius": 5,
        "circle-color": [
          "match",
          ["get", "color"],
          "blue", "#0000FF",
          "red", "#FF0000",
          "#808080"
        ],
        "circle-stroke-width": 2,
        "circle-stroke-color": "#ffffff"
      },
      "filter": ["==", ["geometry-type"], "Point"]
    },
    {
      "id": "point-labels",
      "type": "symbol",
      "source": "road-trip",
      "source-layer": "original",
      "layout": {
        "text-field": ["get", "name"],
        "text-font": ["Open Sans Regular"],
        "text-size": 9,
        "text-offset": [0, 1],
        "text-anchor": "top"
      },
      "paint": {
        "text-color": "#000000",
        "text-halo-color": "#ffffff",
        "text-halo-width": 1
      },
      "filter": ["==", ["geometry-type"], "Point"]
    }
  ]
}
EOF
)


# Create a new style
STYLE_RESPONSE=$(curl -X POST "https://api.mapbox.com/styles/v1/${USERNAME}?access_token=${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$STYLE_JSON")

STYLE_ID=$(echo $STYLE_RESPONSE | jq -r '.id')

echo -e "\033[0;32m✓\033[0m Created custom style with ID: \033[1;36m$STYLE_ID\033[0m"

# Wait for the style to be processed
sleep 3

# Generate the static map image using the custom style
echo -e "\n\033[1;33m🗺️  Generating image using Mapbox Static Image API...\033[0m"
URL="https://api.mapbox.com/styles/v1/${USERNAME}/${STYLE_ID}/static/${CENTER},${ZOOM}/${WIDTH}x${HEIGHT}@2x?access_token=${ACCESS_TOKEN}"

RESPONSE=$(curl -v "$URL" -o "$OUTPUT_IMAGE" 2>&1)

# Check if the file was created and has content
if [ -f "$OUTPUT_IMAGE" ] && [ -s "$OUTPUT_IMAGE" ]; then
    echo -e "  \033[0;32m✓\033[0m Static map image saved as $OUTPUT_IMAGE"

    # Check if the file is actually an image
    if file "$OUTPUT_IMAGE" | grep -q "image"; then
        echo -e "  \033[0;32m✓\033[0m File appears to be a valid image."
    else
        echo -e "  \033[0;31m✗\033[0m File does not appear to be a valid image. Contents:"
        cat "$OUTPUT_IMAGE"
    fi
else
    echo -e "  \033[0;31m✗\033[0m Error: Failed to save the image or the image is empty."
    echo -e "  \033[0;31m✗\033[0m Curl Response:"
    echo "$RESPONSE"
fi

# Add date, legend, and header to the image
if [ -f "$OUTPUT_IMAGE" ] && [ -s "$OUTPUT_IMAGE" ]; then
    echo -e "\n\033[1;33m✏️  Adding date to the image...\033[0m"
    magick "$OUTPUT_IMAGE" \
        -gravity southeast \
        -pointsize 70 \
        -font Acme-Regular \
        -fill "#404040" \
        -annotate +150+500 "Map Last Updated" \
        -annotate +150+410 "${TODAYS_DATE}" \
        "$OUTPUT_IMAGE"

    echo -e "\033[1;33m🏷️  Adding legend to the image...\033[0m"
    magick "$OUTPUT_IMAGE" \
        \( -size 400x300 xc:none \
           -fill "#404040" -draw "rectangle 0,0 359,299" \
           -fill white -draw "rectangle 1,1 358,298" \
           -font Acme-Regular -pointsize 40 \
           -fill "#404040" -draw "text 30,70 'Planned'" \
           -fill "#404040" -draw "text 30,150 'Visited'" \
           -fill gray -draw "circle 280,60 300,60" \
           -fill blue -draw "circle 280,140 300,140" \
           -fill "#404040" -pointsize 30 \
           -draw "text 30,230 'Currently traveled'" \
           -draw "text 30,270 '${visited_miles_total} of ${miles_total} miles'" \
        \) -gravity southwest -geometry +100+350 -composite \
        "$OUTPUT_IMAGE"

    echo -e "\n\033[1;36m🖊️  Adding 'LIVE TRIP MAP' header to the image...\033[0m"
    magick "$OUTPUT_IMAGE" \
        \( -size 70x70 xc:none -fill red -draw "circle 30,30 30,0" \) \
        -gravity northwest -geometry +100+255 -composite \
        -gravity northwest \
        -pointsize 90 \
        -font Acme-Regular \
        -fill "#404040" \
        -annotate +180+230 "LIVE TRIP MAP" \
        "$OUTPUT_IMAGE"

    echo -e "\n\033[1;32m🎉 All done! Opening the final image...\033[0m"
    open "$OUTPUT_IMAGE"
else
    echo -e "\n\033[1;31m❌ Oops! We couldn't create the image.\033[0m"
    echo -e "   \033[0;90mThe file doesn't exist or is empty. Double-check the previous steps.\033[0m"
fi

echo -e "\n\033[1;33m✨ Process complete! Your beautiful trip map is ready!\033[0m"
echo -e "\033[0;90mTake a moment to admire your work. Happy travels! 🚗🗺️\033[0m\n"
