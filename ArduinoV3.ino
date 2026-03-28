#include <AccelStepper.h>

#define DIR_PIN 2
#define STEP_PIN 3
#define ENABLE_PIN 4

// Adjust this based on your microstepping!
// If 180 degrees = 800 steps, put 800 here.
const int TARGET_STEPS_180 = 800;

AccelStepper stepper(AccelStepper::DRIVER, STEP_PIN, DIR_PIN);

int lastReportedAngle = -1;

void setup()
{
    Serial.begin(115200);
    pinMode(ENABLE_PIN, OUTPUT);
    digitalWrite(ENABLE_PIN, LOW); // Enable driver

    stepper.setMaxSpeed(400); // Slower, more realistic radar sweep speed
    stepper.setAcceleration(150);
    stepper.setCurrentPosition(0);

    Serial.println("ARDUINO_READY");
}

void loop()
{
    if (Serial.available() > 0)
    {
        char cmd = Serial.read();
        if (cmd == 'F')
        {
            stepper.moveTo(TARGET_STEPS_180);
        }
        else if (cmd == 'B')
        {
            stepper.moveTo(0);
        }
    }

    stepper.run();

    // --- NEW: Calculate and report angle in real-time ---
    // Convert current step position to an angle (0 to 180)
    int currentAngle = (stepper.currentPosition() * 180L) / TARGET_STEPS_180;

    // Only send data if the angle has changed by at least 1 degree to prevent flooding Python
    if (currentAngle != lastReportedAngle)
    {
        Serial.print("ANGLE:");
        Serial.println(currentAngle);
        lastReportedAngle = currentAngle;
    }

    // --- Report Completion ---
    if (stepper.distanceToGo() == 0 && stepper.currentPosition() != 0 && stepper.targetPosition() == TARGET_STEPS_180)
    {
        Serial.println("DONE_F");
        stepper.moveTo(TARGET_STEPS_180 + 1);
    }
    else if (stepper.distanceToGo() == 0 && stepper.currentPosition() != TARGET_STEPS_180 && stepper.targetPosition() == 0)
    {
        Serial.println("DONE_B");
        stepper.moveTo(-1);
    }
}