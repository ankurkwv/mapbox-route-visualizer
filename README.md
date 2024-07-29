# Mapbox Route Visualizer
Ankur Kumar

## Overview
The Mapbox Route Visualizer is a powerful bash script that creates a visually appealing map of a road trip using Mapbox APIs. It takes a list of locations, geocodes them, calculates routes between them, and generates a custom map image with the route, visited and planned locations, and trip statistics.

## Features
- Geocodes locations using Mapbox Geocoding API
- Calculates routes between locations using Mapbox Directions API
- Creates a custom map style with Mapbox Styles API
- Generates a static map image using Mapbox Static Images API
- Adds trip statistics, legend, and date to the final image
- Supports color-coding for visited and planned locations

## Prerequisites
- Bash shell
- curl
- jq (`brew install jq`)
- ImageMagick (`brew install imagemagick`)
- Mapbox account and access token

## Installation
1. Clone this repository or download the `bash_mapbox_route_visualizer.sh` script.
2. Make the script executable:
   ```
   chmod +x bash_mapbox_route_visualizer.sh
   ```
3. Ensure you have all the prerequisites installed.

## Configuration
1. Set your Mapbox access token as an environment variable:
   ```
   export MAPBOX_ACCESS_TOKEN="your_mapbox_access_token_here"
   ```
2. Edit the `locations` array in the script to include your trip locations and their status (blue for visited, gray for planned).
3. Edit the `USERNAME` variable in the script to include your Mapbox username.

## Usage
Run the script from the command line:
   ```
   ./bash_mapbox_route_visualizer.sh
   ```
This will execute the script and generate the map image based on the provided locations and their statuses. Ensure that your terminal has access to the required environment variables and dependencies before running the script. Run it in the same location you saved the file.

## Credits
This project was developed with the assistance of Claude Sonnet 3.5 and the team at Anthropic. Their support and contributions were invaluable in writing and refining the code.


## Disclaimer: Use at Your Own Risk

This script is provided "as is" without any warranties or guarantees of any kind, either expressed or implied. The user assumes all responsibility and risk for the use of this script. The authors and contributors are not liable for any damages or losses resulting from the use or misuse of this script.

Always review and test the script thoroughly before using it in any critical or production environment. It is recommended to use this script only for personal or educational purposes, and to exercise caution when working with APIs and external services.

By using this script, you acknowledge that you have read this disclaimer, understand its contents, and agree to use the script at your own risk.

