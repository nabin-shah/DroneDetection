// Drone Detection Dashboard JavaScript

let lastDataTime = null;
let frozenDataCount = 0;
let connectionErrorCount = 0;
let goodDataCount = 0;
let currentStatus = 'unknown';


// ========================================
// NATIVE CAMERA - PROVEN WORKING VERSION
// ========================================
let myStream = null;

function startCam() {
    console.log('Starting camera...');
    const video = document.getElementById('myVideo');
    const placeholder = document.getElementById('cameraPlaceholder');
    const statusText = document.getElementById('cameraStatusText');
    
    if (statusText) statusText.textContent = 'Requesting access...';
    
    navigator.mediaDevices.getUserMedia({ video: { width: 640, height: 480 } })
        .then(function(stream) {
            myStream = stream;
            video.srcObject = stream;
            
            if (placeholder) placeholder.style.display = 'none';
            if (statusText) {
                statusText.textContent = 'Status: Active ✓';
                statusText.style.color = '#00ff00';
            }
            
            console.log('✅ Camera started successfully!');
        })
        .catch(function(error) {
            console.error('❌ Camera error:', error);
            
            if (statusText) {
                statusText.textContent = 'Status: Access Denied';
                statusText.style.color = '#ff4444';
            }
            
            alert('Camera access denied!\n\nError: ' + error.message + '\n\nFix:\n1. Click 🔒 in address bar\n2. Allow camera\n3. Refresh page');
        });
}

function stopCam() {
    const video = document.getElementById('myVideo');
    const placeholder = document.getElementById('cameraPlaceholder');
    const statusText = document.getElementById('cameraStatusText');
    
    if (myStream) {
        myStream.getTracks().forEach(function(track) {
            track.stop();
        });
        myStream = null;
    }
    
    if (video) video.srcObject = null;
    if (placeholder) placeholder.style.display = 'flex';
    if (statusText) {
        statusText.textContent = 'Status: Stopped';
        statusText.style.color = '#888';
    }
    
    console.log('Camera stopped');
}

function takePhoto() {
    if (!myStream) {
        alert('Start camera first!');
        return;
    }
    
    const video = document.getElementById('myVideo');
    const canvas = document.createElement('canvas');
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    canvas.getContext('2d').drawImage(video, 0, 0);
    
    // Get image as base64
    const imageData = canvas.toDataURL('image/jpeg', 0.95);
    
    // Save to server
    fetch('/api/camera/manual_capture', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ image: imageData })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            console.log('✅ Photo saved:', data.filename);
            
            // Also download to PC
            const link = document.createElement('a');
            link.download = data.filename;
            link.href = imageData;
            link.click();
            
            // Refresh captures display
            setTimeout(loadManualCaptures, 500);
        }
    })
    .catch(error => {
        console.error('Error:', error);
    });
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



function loadManualCaptures() {
    fetch('/api/captures_list')
        .then(response => response.json())
        .then(data => {
            const container = document.getElementById('recentCaptures');
            
            if (!data.captures || data.captures.length === 0) {
                container.innerHTML = '<p style="color: #888; text-align: center; padding: 20px;">No captures yet</p>';
                return;
            }
            
            let html = '';
            data.captures.forEach(capture => {
                html += `
                    <div style="margin: 10px 0; padding: 10px; background: #1a1a1a; border-radius: 5px;">
                        <img src="/api/captures/${capture.filename}" 
                             onclick="window.open('/api/captures/${capture.filename}', '_blank')"
                             title="Click to view full size"
                             style="width: 100%; cursor: pointer; border-radius: 5px; margin-bottom: 5px;">
                        <div style="display: flex; justify-content: space-between; font-size: 12px;">
                            <span style="color: #00ff00;">${capture.time}</span>
                            <span style="color: #aaa;">${capture.type}</span>
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
    
    // updateCameraPreview();
    // setInterval(updateCameraPreview, 2000);
     loadManualCaptures();
    setInterval(loadManualCaptures, 5000);
    
    updateRecentCaptures();
    setInterval(updateRecentCaptures, 5000);
    
    console.log('Dashboard ready!');
});
