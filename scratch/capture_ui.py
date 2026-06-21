import time
from html2image import Html2Image
import os

print("Waiting for Vite server to settle...")
time.sleep(3)

print("Capturing Command Center UI...")
try:
    hti = Html2Image(browser='edge', size=(1440, 900))
    hti.screenshot(url='http://localhost:5173', save_as='titan_command_center.png')
    
    # Move it to the correct folder
    if os.path.exists('titan_command_center.png'):
        os.replace('titan_command_center.png', r'c:\Users\singb\Downloads\gpuuhj\docs\assets\titan_command_center.png')
        print("Screenshot successfully captured and moved to docs/assets!")
    else:
        print("Screenshot failed!")
except Exception as e:
    print(f"Error capturing screenshot: {e}")
