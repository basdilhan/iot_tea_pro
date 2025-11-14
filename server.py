from flask import Flask, request, jsonify, render_template_string
import os

app = Flask(__name__)

# Google Maps API Key - Replace with your actual key
GOOGLE_MAPS_API_KEY = os.getenv('GOOGLE_MAPS_API_KEY', 'YOUR_API_KEY_HERE')

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Worker Locations Map</title>
    <script src="https://maps.googleapis.com/maps/api/js?key={{ api_key }}"></script>
    <style>
        html, body { height: 100%; margin: 0; padding: 0; }
        #map { height: 100%; width: 100%; }
    </style>
</head>
<body>
    <div id="map"></div>
    <script>
        function initMap() {
            var workers = {{ workers|tojson }};
            var center = {lat: 6.9271, lng: 79.8612}; // Default Colombo

            if (workers.length > 0) {
                var totalLat = 0, totalLng = 0;
                workers.forEach(function(worker) {
                    totalLat += worker.lat;
                    totalLng += worker.lng;
                });
                center = {lat: totalLat / workers.length, lng: totalLng / workers.length};
            }

            var map = new google.maps.Map(document.getElementById('map'), {
                zoom: 10,
                center: center
            });

            workers.forEach(function(worker) {
                var marker = new google.maps.Marker({
                    position: {lat: worker.lat, lng: worker.lng},
                    map: map,
                    title: worker.name
                });

                var infoWindow = new google.maps.InfoWindow({
                    content: '<div><strong>' + worker.name + '</strong></div>'
                });

                marker.addListener('click', function() {
                    infoWindow.open(map, marker);
                });
            });
        }
        window.onload = initMap;
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE, api_key=GOOGLE_MAPS_API_KEY, workers=[])

@app.route('/map', methods=['POST'])
def map_view():
    data = request.get_json()
    workers = data.get('workers', [])
    return render_template_string(HTML_TEMPLATE, api_key=GOOGLE_MAPS_API_KEY, workers=workers)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
