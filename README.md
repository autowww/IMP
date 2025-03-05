# IMP
PowerShell-based automation for image processing, EXIF metadata management, and object detection using YOLOv8.

# 🖼️ Image Processing & Object Detection Automation

## 🚀 Overview
This PowerShell-based project automates **image processing**, including:
- ✅ **Creating proxy images** (compressed versions with metadata)
- ✅ **Restoring EXIF metadata** from proxy images to originals
- ✅ **Detecting objects in images** using YOLOv8 and tagging metadata

🔗 **Uses:**
- PowerShell for automation
- Python & YOLOv8 for object detection
- ImageMagick for image resizing
- ExifTool for metadata handling

---

## 📁 Project Structure

/image-processing/
│── image_proxy.ps1          # Main script (user runs this)
│── Config.ps1               # Configuration & dependency checks
│── Proxy.ps1                # Creates proxy images
│── Metadata.ps1             # Restores EXIF metadata
│── ObjectDetection.ps1      # Detects objects & updates metadata
│── detect_objects.py        # Python script for YOLO object detection
│── README.md                # Documentation (this file)

# 🚀 Installation Instructions for Image Processing & Object Detection Script

This guide will help you set up and run the project step by step.

---

## 1️⃣ Install Required Dependencies

Before running the script, install the following dependencies:

### 🔹 Install PowerShell (If Not Installed)
PowerShell is pre-installed on **Windows 10+**, but if needed:
- Download from: https://github.com/PowerShell/PowerShell
- Install via **Windows Package Manager**:
  winget install Microsoft.PowerShell

---

### 🔹 Install Python & YOLOv8
1. **Install Python 3**:
   winget install Python.Python.3

2. **Install YOLOv8 & Dependencies**:
   pip install ultralytics opencv-python pillow

---

### 🔹 Install ImageMagick
1. Download **ImageMagick** from https://imagemagick.org/script/download.php
2. During installation, **enable "Install legacy utilities (convert, mogrify, etc.)"**.
3. Verify the installation:
   magick --version

---

### 🔹 Install ExifTool
1. Download **ExifTool** from https://exiftool.org/
2. Extract or install it on your system.
3. Ensure it’s accessible in PowerShell:
   exiftool -ver

---

## 2️⃣ Clone the Repository
If using **Git**, run:
   git clone https://github.com/autowww/IMP.git
   cd IMP

Or **manually download** the ZIP from GitHub.

---

## 3️⃣ Run the Script
Execute the main PowerShell script:
   .\image_proxy.ps1

### 🛠️ Choose a Mode
The script will prompt:
   Select mode:
   1 - Create Proxy Images (with original path metadata)
   2 - Restore EXIF Data to Original Files (using stored metadata)
   3 - Detect Objects in Proxy Images & Tag Metadata

- `1` → **Creates proxy images**.
- `2` → **Restores EXIF metadata** to originals.
- `3` → **Runs YOLOv8 object detection** and tags images.

---

## 4️⃣ Verify Object Detection (Mode 3)
Check if objects were detected and added as metadata:
   exiftool -XMP:Subject "path/to/image.jpg"

Example output:
   Subject                         : Favorite, boat, sea, person

---

## ✅ Installation Complete!
You’re now ready to use the **image processing & object detection automation** 🎯. 

**GitHub Repository:** https://github.com/autowww/IMP/

---

