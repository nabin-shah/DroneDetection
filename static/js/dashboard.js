// Drone Detection Dashboard JavaScript

let lastAutoCaptureTime = 0; // Prevents spamming photos
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








// // Scan Control Functions
// function updateScanStatus() {
//     fetch('/api/auto_scan/status')
//         .then(response => response.json())
//         .then(data => {
//             if (data.active) {
//                 document.getElementById('scanStatus').textContent = 'Active ✓';
//                 document.getElementById('scanStatus').style.color = '#00ff00';
//                 document.getElementById('currentBand').textContent = data.current_band;
//             } else {
//                 document.getElementById('scanStatus').textContent = 'Stopped';
//                 document.getElementById('scanStatus').style.color = '#ff4444';
//                 document.getElementById('currentBand').textContent = 'Manual Mode';
//             }
//         })
//         .catch(err => console.error('Scan status error:', err));
// }

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
    
    // --- NEW: IGNORE DETECTIONS IF RADAR IS OFF ---
    if (!isRadarActive) {
        return; 
    }
    // ----------------------------------------------
    
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
        
        // --- NEW RADAR CODE ---
        // We now use targetRadarAngle, which is the exact physical 
        // angle reported by the Arduino at this exact millisecond!
        blips.push({
            angle: targetRadarAngle, 
            power: strongest.power,
            band: strongest.matched_profile ? strongest.profile_name : 'Unknown',
            timestamp: Date.now()
        });
        // ----------------------
        
        // --- NEW: AUTO CAPTURE LOGIC ---
        const now = Date.now();
        // Only capture if Radar is ON, Camera is ON, and 5 seconds have passed
        if (isRadarActive && myStream && (now - lastAutoCaptureTime > 5000)) {
            lastAutoCaptureTime = now;
            performAutoCapture(strongest, targetRadarAngle);
        }
        // -------------------------------
        
        updateRecentCaptures();
        
    } else {
        document.getElementById('detectionIndicator').className = 
            'status-indicator connected';
        document.getElementById('detectionStatus').textContent = 'Monitoring';
        document.getElementById('alertBox').classList.remove('active');
        document.getElementById('noAlerts').style.display = 'block';
    }
}

// ==========================================
// FREQUENCY SCANNER CONTROLS
// ==========================================

let scannerStatusInterval = null;

function toggleScanner() {
    const button = document.getElementById('toggleScanBtn');
    const isScanning = button.textContent.includes('Stop');
    
    const endpoint = isScanning ? '/api/scanner/stop' : '/api/scanner/start';
    
    fetch(endpoint, { method: 'POST' })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                updateScannerStatus();
            }
        })
        .catch(err => console.error('Scanner toggle error:', err));
}

function updateScannerStatus() {
    fetch('/api/scanner/status')
        .then(response => response.json())
        .then(data => {
            const statusDiv = document.getElementById('scannerStatus');
            const button = document.getElementById('toggleScanBtn');
            
            if (data.scanning) {
                button.textContent = '⏸️ Stop Auto-Scan';
                button.className = 'btn-stop';
                
                statusDiv.innerHTML = `
                    <div style="background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); padding: 15px; border-radius: 8px; border-left: 4px solid #00ff00;">
                        <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 8px;">
                            <span style="font-size: 24px;">${data.icon}</span>
                            <div>
                                <div style="font-weight: bold; font-size: 16px; color: #00ff00;">
                                    ${data.current_band}
                                </div>
                                <div style="font-size: 12px; color: #aaa;">
                                    ${data.description}
                                </div>
                            </div>
                        </div>
                        <div style="display: flex; justify-content: space-between; font-size: 12px; color: #ddd; margin-top: 8px;">
                            <span>Center: ${(data.center_frequency / 1e9).toFixed(3)} GHz</span>
                            <span>Span: ${(data.span / 1e6).toFixed(1)} MHz</span>
                        </div>
                        <div style="margin-top: 8px;">
                            <div style="background: rgba(0,0,0,0.3); height: 4px; border-radius: 2px; overflow: hidden;">
                                <div style="background: #00ff00; height: 100%; width: ${((data.current_band_index + 1) / data.total_bands) * 100}%; transition: width 0.3s;"></div>
                            </div>
                            <div style="font-size: 11px; color: #888; text-align: center; margin-top: 4px;">
                                Band ${data.current_band_index + 1} of ${data.total_bands} • Dwell: ${data.dwell_time}s
                            </div>
                        </div>
                    </div>
                `;
            } else {
                button.textContent = '🔄 Start Auto-Scan';
                button.className = 'btn-primary';
                
                statusDiv.innerHTML = `
                    <div style="padding: 15px; text-align: center; color: #888; background: rgba(255,255,255,0.05); border-radius: 8px;">
                        <div style="font-size: 32px; margin-bottom: 8px;">⏸️</div>
                        <div>Auto-scan stopped</div>
                        <div style="font-size: 12px; margin-top: 5px;">Click "Start Auto-Scan" to begin</div>
                    </div>
                `;
            }
        })
        .catch(err => console.error('Scanner status error:', err));
}

function loadFrequencyBands() {
    fetch('/api/scanner/bands')
        .then(response => response.json())
        .then(data => {
            const container = document.getElementById('frequencyBands');
            
            let html = '<div style="display: grid; grid-template-columns: 1fr; gap: 8px;">';
            
            data.bands.forEach((band, index) => {
                html += `
                    <button onclick="setManualBand(${index})" 
                            style="padding: 10px; background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.2); 
                                   border-radius: 5px; cursor: pointer; text-align: left; color: white; transition: all 0.2s;"
                            onmouseover="this.style.background='rgba(255,255,255,0.2)'" 
                            onmouseout="this.style.background='rgba(255,255,255,0.1)'">
                        <div style="display: flex; align-items: center; gap: 8px;">
                            <span style="font-size: 20px;">${band.icon}</span>
                            <div style="flex: 1;">
                                <div style="font-weight: bold; font-size: 13px;">${band.name}</div>
                                <div style="font-size: 11px; color: #aaa;">${(band.center / 1e9).toFixed(3)} GHz</div>
                            </div>
                        </div>
                    </button>
                `;
            });
            
            html += '</div>';
            container.innerHTML = html;
        })
        .catch(err => console.error('Bands error:', err));
}

function setManualBand(bandIndex) {
    fetch(`/api/scanner/set_band/${bandIndex}`, { method: 'POST' })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                console.log(`✅ Switched to band ${bandIndex}`);
                updateScannerStatus();
            }
        })
        .catch(err => console.error('Set band error:', err));
}

// ==========================================
// SYNCHRONIZED RADAR LOGIC
// ==========================================

function toggleRadarSync() {
    const button = document.getElementById('toggleRadarBtn');
    const isScanning = button.textContent.includes('Stop');
    
    // NEW: Automatically start the camera if we are starting the radar!
    if (!isScanning && !myStream) {
        startCam(); 
    }
    
    const endpoint = isScanning ? '/api/radar/stop' : '/api/radar/start';
    
    fetch(endpoint, { method: 'POST' })
        .then(response => {
            if (response.status === 503) {
                alert("Cannot start: Arduino is not connected. Check your COM port!");
                throw new Error("Arduino not connected");
            }
            return response.json();
        })
        .then(data => {
            if (data.success) {
                updateRadarStatus();
            }
        })
        .catch(err => console.error('Radar toggle error:', err));
}

function updateRadarStatus() {
    fetch('/api/radar/status')
        .then(response => response.json())
        .then(data => {
            // --- NEW LINE: Save the physical angle (converted to radians) ---
            targetRadarAngle = data.current_angle * (Math.PI / 180); 
            // ----------------------------------------------------------------
            
            const statusDiv = document.getElementById('radarSyncStatus');
            const button = document.getElementById('toggleRadarBtn');
            const statusText = document.getElementById('radarStatusText');
            
            if (!data.arduino_connected) {
                button.disabled = true;
                button.style.background = '#555';
                button.textContent = '❌ Arduino Disconnected';
                return;
            }

            if (data.is_scanning) {
                isRadarActive = true; // NEW: Starts the canvas sweeping line
                button.textContent = '⏹️ Stop Hardware Sync';
                button.style.background = '#ff4444';
                
                statusDiv.innerHTML = `
                    <div style="padding: 15px; text-align: center; color: #00ff00; background: rgba(0, 255, 0, 0.1); border-radius: 8px; border: 1px solid #00ff00;">
                        <div style="font-size: 32px; margin-bottom: 8px; animation: pulse 1s infinite;">📡</div>
                        <div style="font-weight: bold;">Hardware Sync Active</div>
                        <div style="font-size: 12px; margin-top: 5px; color: #aaa;">Antenna and RTSA are sweeping in tandem...</div>
                    </div>
                `;
            } else {
                isRadarActive = false; // NEW: Stops the canvas sweeping line
                
                // --- NEW: STOP CAMERA AND CLEAR ALERTS ---
                if (myStream) {
                    stopCam(); // Turn off the webcam
                }
                
                // Reset the detection UI immediately
                document.getElementById('detectionIndicator').className = 'status-indicator connected';
                document.getElementById('detectionStatus').textContent = 'Radar Stopped';
                document.getElementById('alertBox').classList.remove('active');
                document.getElementById('noAlerts').style.display = 'block';
                // -----------------------------------------

                button.disabled = false;
                button.textContent = '▶️ Start Hardware Radar Sync';
                button.style.background = '#00aaff';
                
                statusDiv.innerHTML = `
                    <div style="padding: 15px; text-align: center; color: #888; background: rgba(255,255,255,0.05); border-radius: 8px;">
                        <div style="font-size: 32px; margin-bottom: 8px;">⏸️</div>
                        <div>Hardware sync stopped</div>
                    </div>
                `;
            }
        })
        .catch(err => console.error('Radar status error:', err));
}


document.addEventListener('DOMContentLoaded', function() {
    console.log('Dashboard initializing...');
    
    // Dashboard updates
    updateDashboard();
    setInterval(updateDashboard, 1000);
    
    // OLD: Remove these if you had them
    // updateScanStatus();
    // setInterval(updateScanStatus, 2000);
    
    // NEW: Scanner updates
    updateScannerStatus();
    setInterval(updateScannerStatus, 2000);

    // RADAR SYNC updates
    updateRadarStatus();
    setInterval(updateRadarStatus, 200);
    
    // Load frequency bands
    loadFrequencyBands();
    
    // Manual captures
    loadManualCaptures();
    setInterval(loadManualCaptures, 5000);
    
    // --- NEW: FETCH HISTORICAL DETECTIONS ON PAGE LOAD ---
    updateRecentCaptures();
    // -----------------------------------------------------
    
    console.log('✅ Dashboard ready with auto-scanner!');
});

// ==========================================
// LIVE CANVAS RADAR SCREEN
// ==========================================

const canvas = document.getElementById('radarCanvas');
const ctx = canvas.getContext('2d');

let targetRadarAngle = 0;   // The true physical angle from Arduino
let currentRadarAngle = 0;  // The visual angle on screen
let isRadarActive = false;
let blips = []; 

// Draw the static radar grid (Semi-circle)
function drawRadarGrid() {
    const centerX = canvas.width / 2;
    const centerY = canvas.height;
    const radius = canvas.width / 2 - 20;

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw concentric distance rings
    ctx.strokeStyle = 'rgba(0, 255, 0, 0.3)';
    ctx.lineWidth = 1;
    for (let i = 1; i <= 4; i++) {
        ctx.beginPath();
        ctx.arc(centerX, centerY, radius * (i / 4), Math.PI, 0);
        ctx.stroke();
    }

    // Draw angle lines (30, 60, 90, 120, 150 degrees)
    for (let i = 1; i <= 5; i++) {
        const angle = Math.PI - (i * Math.PI / 6);
        ctx.beginPath();
        ctx.moveTo(centerX, centerY);
        ctx.lineTo(centerX + Math.cos(angle) * radius, centerY - Math.sin(angle) * radius);
        ctx.stroke();
    }
}

// Animate the sweeping line and draw blips
function animateRadar() {
    const centerX = canvas.width / 2;
    const centerY = canvas.height;
    const radius = canvas.width / 2 - 20;

    drawRadarGrid(); // Uses the function we wrote previously

    if (isRadarActive) {
        // --- TRUE SYNCHRONIZATION (Linear Interpolation) ---
        // Instead of guessing speed, the visual line smoothly follows the physical antenna.
        // The "0.1" makes it glide smoothly even if network packets are delayed.
        currentRadarAngle += (targetRadarAngle - currentRadarAngle) * 0.1;

        // Draw the sweeping scanner beam exactly where the antenna is
        ctx.beginPath();
        ctx.moveTo(centerX, centerY);
        const endX = centerX + Math.cos(Math.PI - currentRadarAngle) * radius;
        const endY = centerY - Math.sin(Math.PI - currentRadarAngle) * radius;
        ctx.lineTo(endX, endY);
        ctx.strokeStyle = '#00ff00';
        ctx.lineWidth = 3;
        ctx.stroke();

        // Optional: Draw text showing the exact physical degree
        ctx.fillStyle = '#00ff00';
        ctx.font = '14px monospace';
        const degreeText = Math.round(currentRadarAngle * (180 / Math.PI)) + "°";
        ctx.fillText("Antenna: " + degreeText, 10, 20);
    }

    // 2. Draw and fade detection blips (Same as before)
    const currentTime = Date.now();
    blips = blips.filter(blip => currentTime - blip.timestamp < 5000); 

    blips.forEach(blip => {
        const age = currentTime - blip.timestamp;
        const opacity = 1 - (age / 5000);
        
        const powerRange = Math.max(0, Math.min(1, (blip.power + 90) / 60)); 
        const distance = radius - (powerRange * radius); 

        const blipX = centerX + Math.cos(Math.PI - blip.angle) * distance;
        const blipY = centerY - Math.sin(Math.PI - blip.angle) * distance;

        ctx.beginPath();
        ctx.arc(blipX, blipY, 6, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(255, 0, 0, ${opacity})`; 
        ctx.fill();
        ctx.strokeStyle = `rgba(255, 255, 255, ${opacity})`;
        ctx.lineWidth = 2;
        ctx.stroke();
        
        ctx.fillStyle = `rgba(255, 255, 255, ${opacity})`;
        ctx.font = '10px Arial';
        ctx.fillText(blip.band, blipX + 10, blipY);
    });

    requestAnimationFrame(animateRadar);
}



// Automatically snaps a photo, burns text on it, and saves to JSON
function performAutoCapture(strongestSignal, angleRad) {
    const video = document.getElementById('myVideo');
    if (!video.videoWidth) return; // Camera not ready

    const canvas = document.createElement('canvas');
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    const ctx = canvas.getContext('2d');
    
    // Draw the camera frame
    ctx.drawImage(video, 0, 0);

    // Calculate degrees
    const degrees = Math.round(angleRad * (180 / Math.PI));
    const freqGHz = (strongestSignal.frequency / 1e9).toFixed(3);

    // Burn "DRONE DETECTED" and the exact Angle/Frequency onto the image!
    ctx.fillStyle = "rgba(0, 0, 0, 0.6)";
    ctx.fillRect(0, 0, canvas.width, 100); // Dark background at top for readability
    
    ctx.fillStyle = "#ff4444";
    ctx.font = "bold 28px Arial";
    ctx.fillText("🚨 DRONE DETECTED", 20, 40);
    
    ctx.fillStyle = "#00ff00";
    ctx.font = "20px monospace";
    ctx.fillText(`Angle: ${degrees}° | Freq: ${freqGHz} GHz`, 20, 80);

    // Convert to base64
    const imageData = canvas.toDataURL('image/jpeg', 0.90);

    // Send to the new backend route
    fetch('/api/camera/auto_capture', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            image: imageData,
            angle: degrees,
            frequency: strongestSignal.frequency,
            power: strongestSignal.power,
            band: strongestSignal.matched_profile ? strongestSignal.profile_name : 'Unknown',
            score: strongestSignal.drone_score
        })
    })
    .then(r => r.json())
    .then(data => {
        if(data.success) {
            updateRecentCaptures(); // Refresh the UI immediately
        }
    })
    .catch(e => console.error("Auto-capture error:", e));
}

// Update the UI function to display the Angle beautifully
function updateRecentCaptures() {
    fetch('/api/detection_history')
        .then(response => response.json())
        .then(data => {
            
            // --- NEW: Also update the text log! ---
            updateDetectionsTextLog(data);
            // --------------------------------------

            const container = document.getElementById('recentCaptures');
            
            if (data.total === 0 || !data.detections) {
                container.innerHTML = '<p style="color: #888; text-align: center; padding: 20px;">No captures yet</p>';
                return;
            }
            
            const detectionsWithImages = data.detections.filter(d => d.image && d.image.startsWith('radar_detect'));
            
            if (detectionsWithImages.length === 0) {
                container.innerHTML = '<p style="color: #888; text-align: center; padding: 20px;">No radar captures yet</p>';
                return;
            }
            
            let html = '';
            // Show the 5 most recent drone detections
            detectionsWithImages.reverse().slice(0, 5).forEach(detection => {
                const time = new Date(detection.timestamp).toLocaleTimeString();
                const freq = (detection.frequency / 1e9).toFixed(3);
                const angle = detection.angle !== undefined ? `${detection.angle}°` : 'Unknown';
                
                html += `
                    <div class="capture-item" style="border: 1px solid #ff4444;">
                        <img src="/api/captures/${detection.image}" 
                             onclick="window.open('/api/captures/${detection.image}', '_blank')"
                             title="Click to view full size">
                        <div class="capture-info" style="display: flex; flex-direction: column; gap: 4px;">
                            <div style="display: flex; justify-content: space-between;">
                                <span style="color: #00ff00; font-weight: bold;">⏱️ ${time}</span>
                                <span style="color: #ffaa00; font-weight: bold;">🧭 ${angle}</span>
                            </div>
                            <div style="display: flex; justify-content: space-between;">
                                <span style="color: #aaa;">📡 ${freq} GHz</span>
                                <span style="color: #aaa;">Confidence: ${detection.confidence}%</span>
                            </div>
                            <div style="color: #00aaff; font-size: 10px;">🏷️ Band: ${detection.band}</div>
                        </div>
                    </div>
                `;
            });
            
            container.innerHTML = html;
        })
        .catch(err => console.error('Captures error:', err));
}



// Start the animation loop
if (canvas && ctx) {
    animateRadar();
}

// NEW: Renders a clean, professional text-based log of detections
function updateDetectionsTextLog(data) {
    const logContainer = document.getElementById('recentDetectionsLog');
    
    if (!data || data.total === 0 || !data.detections || data.detections.length === 0) {
        logContainer.innerHTML = '<p style="color: #888; text-align: center; padding: 20px;">No detections yet</p>';
        return;
    }

    let html = '<ul style="list-style: none; padding: 0; margin: 0;">';
    
    // Grab the 15 most recent detections, reverse them so newest is on top
    const recentLogs = [...data.detections].reverse().slice(0, 15);

    recentLogs.forEach(d => {
        const time = new Date(d.timestamp).toLocaleTimeString();
        const freq = (d.frequency / 1e9).toFixed(3);
        const angle = d.angle !== undefined ? `${d.angle}°` : '--';
        const power = d.power ? d.power.toFixed(1) : '--';
        const band = d.band || 'Unknown Signal';

        html += `
            <li style="padding: 12px 0; border-bottom: 1px solid #444; font-family: monospace; font-size: 13px;">
                <div style="display: flex; justify-content: space-between; margin-bottom: 8px;">
                    <span style="color: #00ff00; font-weight: bold;">[${time}]</span>
                    <span style="color: #00aaff; font-weight: bold; text-align: right;">${band}</span>
                </div>
                <div style="color: #ccc; display: flex; flex-direction: column; gap: 4px; padding-left: 10px; border-left: 2px solid #555;">
                    <div style="display: flex; justify-content: space-between;">
                        <span style="color: #888;">Freq:</span> <span>${freq} GHz</span>
                    </div>
                    <div style="display: flex; justify-content: space-between;">
                        <span style="color: #888;">Angle:</span> <span style="color: #ffaa00;">${angle}</span>
                    </div>
                    <div style="display: flex; justify-content: space-between;">
                        <span style="color: #888;">Power:</span> <span>${power} dBm</span>
                    </div>
                </div>
            </li>
        `;
    });
    
    html += '</ul>';
    logContainer.innerHTML = html;
}


