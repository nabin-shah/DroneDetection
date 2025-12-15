// Drone Detection Dashboard JavaScript

let lastDataTime = null;
let frozenDataCount = 0;
let connectionErrorCount = 0;
let goodDataCount = 0;
let currentStatus = 'unknown';

// Camera Functions
function updateCameraPreview() {
    fetch('/api/camera/preview')
        .then(response => response.json())
        .then(data => {
            const img = document.getElementById('cameraPreview');
            const placeholder = document.getElementById('cameraPlaceholder');
            const statusText = document.getElementById('cameraStatusText');
            
            console.log('Camera data received:', data.image ? 'YES' : 'NO');
            
            if (data.image) {
                // Set image source
                img.src = data.image;
                
                // Show image, hide placeholder
                img.style.display = 'block';
                placeholder.style.display = 'none';
                
                // Update status
                statusText.textContent = 'Status: Active ✓';
                statusText.style.color = '#00ff00';
                
                console.log('Camera preview updated successfully');
            } else {
                // Hide image, show placeholder
                img.style.display = 'none';
                placeholder.style.display = 'flex';
                
                statusText.textContent = 'Status: No feed';
                statusText.style.color = '#ff4444';
                
                console.log('No camera image data');
            }
        })
        .catch(err => {
            console.error('Camera preview error:', err);
            
            const placeholder = document.getElementById('cameraPlaceholder');
            const img = document.getElementById('cameraPreview');
            const statusText = document.getElementById('cameraStatusText');
            
            placeholder.style.display = 'flex';
            img.style.display = 'none';
            statusText.textContent = 'Status: Error';
            statusText.style.color = '#ff4444';
        });
}




function refreshCamera() {
    updateCameraPreview();
}

function updateRecentCaptures() {
    fetch('/api/detection_history')
        .then(response => response.json())
        .then(data => {
            const container = document.getElementById('recentCaptures');
            
            if (data.total === 0) {
                container.innerHTML = '<p style="color: #888; text-align: center; padding: 20px;">No captures yet</p>';
                return;
            }
            
            const detectionsWithImages = data.detections.filter(d => d.image);
            
            if (detectionsWithImages.length === 0) {
                container.innerHTML = '<p style="color: #888; text-align: center; padding: 20px;">No captures yet</p>';
                return;
            }
            
            let html = '';
            detectionsWithImages.reverse().forEach(detection => {
                const time = new Date(detection.timestamp).toLocaleTimeString();
                const freq = (detection.strongest_signal.frequency / 1e9).toFixed(3);
                
                html += `
                    <div class="capture-item">
                        <img src="/api/captures/${detection.image}" 
                             onclick="window.open('/api/captures/${detection.image}', '_blank')"
                             title="Click to view full size">
                        <div class="capture-info">
                            <div style="color: #00ff00; font-weight: bold;">${time}</div>
                            <div style="color: #aaa;">${freq} GHz</div>
                            <div style="color: #aaa;">Score: ${detection.confidence}</div>
                        </div>
                    </div>
                `;
            });
            
            container.innerHTML = html;
        })
        .catch(err => console.error('Captures error:', err));
}

// Scan Control Functions
function updateScanStatus() {
    fetch('/api/auto_scan/status')
        .then(response => response.json())
        .then(data => {
            if (data.active) {
                document.getElementById('scanStatus').textContent = 'Active ✓';
                document.getElementById('scanStatus').style.color = '#00ff00';
                document.getElementById('currentBand').textContent = data.current_band;
            } else {
                document.getElementById('scanStatus').textContent = 'Stopped';
                document.getElementById('scanStatus').style.color = '#ff4444';
                document.getElementById('currentBand').textContent = 'Manual Mode';
            }
        })
        .catch(err => console.error('Scan status error:', err));
}

function startAutoScan() {
    fetch('/api/auto_scan/start')
        .then(response => response.json())
        .then(data => {
            alert('Auto-scan started! Rotating between 2.4 GHz and 5.8 GHz every 5 seconds.');
            updateScanStatus();
        })
        .catch(err => alert('Error starting scan: ' + err));
}

function stopAutoScan() {
    fetch('/api/auto_scan/stop')
        .then(response => response.json())
        .then(data => {
            alert('Auto-scan stopped.');
            updateScanStatus();
        })
        .catch(err => alert('Error stopping scan: ' + err));
}

// Spectrum Data Functions
function updateDashboard() {
    fetch('/api/spectrum', {
        method: 'GET',
        cache: 'no-cache',
        headers: {
            'Cache-Control': 'no-cache'
        }
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Server returned ' + response.status);
        }
        return response.json();
    })
    .then(data => {
        if (data.error) {
            throw new Error(data.error);
        }
        
        const currentDataTime = data.endTime;
        
        if (lastDataTime === currentDataTime) {
            frozenDataCount++;
            goodDataCount = 0;
            
            if (frozenDataCount >= 3 && currentStatus !== 'disconnected') {
                currentStatus = 'disconnected';
                updateStatusDisplay('disconnected');
            }
        } else {
            frozenDataCount = 0;
            connectionErrorCount = 0;
            goodDataCount++;
            lastDataTime = currentDataTime;
            
            if (goodDataCount >= 2 && currentStatus !== 'connected') {
                currentStatus = 'connected';
                updateStatusDisplay('connected');
            }
            
            if (currentStatus === 'connected') {
                document.getElementById('startFreq').textContent = 
                    (data.startFrequency / 1e9).toFixed(3) + ' GHz';
                document.getElementById('endFreq').textContent = 
                    (data.endFrequency / 1e9).toFixed(3) + ' GHz';
                document.getElementById('sampleSize').textContent = data.sampleSize;
                document.getElementById('minPower').textContent = data.minPower + ' dBm';
                document.getElementById('maxPower').textContent = data.maxPower + ' dBm';
                document.getElementById('antenna').textContent = data.antenna.name;
                
                const now = new Date();
                document.getElementById('lastUpdate').textContent = 
                    now.toLocaleTimeString();
                
                handleDetection(data.detection);
            }
        }
    })
    .catch(error => {
        console.error('Connection error:', error);
        connectionErrorCount++;
        goodDataCount = 0;
        
        if (connectionErrorCount >= 2 && currentStatus !== 'disconnected') {
            currentStatus = 'disconnected';
            frozenDataCount = 0;
            lastDataTime = null;
            updateStatusDisplay('disconnected');
        }
    });
}

function updateStatusDisplay(status) {
    if (status === 'connected') {
        document.getElementById('statusIndicator').className = 
            'status-indicator connected';
        document.getElementById('statusText').textContent = 'Connected';
    } else {
        document.getElementById('statusIndicator').className = 
            'status-indicator disconnected';
        document.getElementById('statusText').textContent = 'Disconnected';
        
        document.getElementById('detectionIndicator').className = 
            'status-indicator disconnected';
        document.getElementById('detectionStatus').textContent = 'No Signal';
        document.getElementById('alertBox').classList.remove('active');
        document.getElementById('noAlerts').style.display = 'block';
    }
}

function handleDetection(detection) {
    if (!detection) return;
    
    if (detection.detected) {
        document.getElementById('detectionIndicator').className = 
            'status-indicator detecting';
        document.getElementById('detectionStatus').textContent = 
            'DETECTED (' + detection.count + ' signal' + (detection.count > 1 ? 's' : '') + ')';
        
        document.getElementById('alertBox').classList.add('active');
        document.getElementById('noAlerts').style.display = 'none';
        
        const strongest = detection.strongest;
        const detailsHTML = `
            <div class="detection-item">
                <span class="detection-label">Frequency:</span>
                <span class="detection-value">${(strongest.frequency / 1e9).toFixed(4)} GHz</span>
            </div>
            <div class="detection-item">
                <span class="detection-label">Power Level:</span>
                <span class="detection-value">${strongest.power.toFixed(2)} dBm</span>
            </div>
            <div class="detection-item">
                <span class="detection-label">Bandwidth:</span>
                <span class="detection-value">${(strongest.bandwidth / 1e6).toFixed(2)} MHz</span>
            </div>
            <div class="detection-item">
                <span class="detection-label">Detection Score:</span>
                <span class="detection-value">${strongest.drone_score}%</span>
            </div>
            <div class="detection-item">
                <span class="detection-label">Band:</span>
                <span class="detection-value">${strongest.band_name}</span>
            </div>
        `;
        document.getElementById('detectionDetails').innerHTML = detailsHTML;
        
        updateRecentCaptures();
        
    } else {
        document.getElementById('detectionIndicator').className = 
            'status-indicator connected';
        document.getElementById('detectionStatus').textContent = 'Monitoring';
        document.getElementById('alertBox').classList.remove('active');
        document.getElementById('noAlerts').style.display = 'block';
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    console.log('Dashboard initializing...');
    
    // Start all updates
    updateDashboard();
    setInterval(updateDashboard, 1000);
    
    updateScanStatus();
    setInterval(updateScanStatus, 2000);
    
    updateCameraPreview();
    setInterval(updateCameraPreview, 2000);
    
    updateRecentCaptures();
    setInterval(updateRecentCaptures, 5000);
    
    console.log('Dashboard ready!');
});
