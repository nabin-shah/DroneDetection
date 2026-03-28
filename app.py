"""
Drone Detection System - Main Application
Bachelor Thesis Project
"""
from flask import Flask, render_template
from routes import register_routes
from camera import init_camera

# Initialize Flask app
app = Flask(__name__)

# Main dashboard route
@app.route('/')
def dashboard():
    """Render the main dashboard page"""
    return render_template('dashboard.html')

# Register all API routes
register_routes(app)

if __name__ == '__main__':
    print("=" * 50)
    print("Drone Detection System Starting...")
    print("=" * 50)
    
    # Initialize camera on startup
    print("\n[1/2] Initializing camera...")
    # init_camera(0)
    
    print("\n[2/2] Starting Flask server...")
    print("\nDashboard: http://localhost:5000")
    print("=" * 50)
    
    # app.run(debug=True, port=5000)
    app.run(debug=True, use_reloader=False, port=5000)
