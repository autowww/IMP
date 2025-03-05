import sys
import json
import subprocess
from pathlib import Path
from ultralytics import YOLO

# Load YOLOv8 model
model = YOLO(r"yolov8x.pt")

# Set the confidence threshold (0.4 = 40%)
CONFIDENCE_THRESHOLD = 0.4
EXIFTOOL_PATH = "exiftool"  # Ensure ExifTool is installed and accessible

def get_existing_metadata(image_path):
    """Retrieve existing XMP:Subject metadata from an image."""
    try:
        result = subprocess.run(
            [EXIFTOOL_PATH, "-XMP:Subject", "-s3", str(image_path)],
            capture_output=True, text=True, check=True
        )
        existing_tags = result.stdout.strip()
        return existing_tags.split(", ") if existing_tags else []
    except subprocess.CalledProcessError:
        print(f"[WARNING] Failed to retrieve metadata for {image_path}", file=sys.stderr)
        return []

def write_metadata(image_path, detected_objects):
    """Merge new detected objects with existing metadata and write back to the image."""
    existing_tags = get_existing_metadata(image_path)

    # Merge existing and new tags, removing duplicates
    merged_tags = sorted(set(existing_tags + detected_objects))

    # Convert list back to a comma-separated string
    final_tags = ", ".join(merged_tags)

    print(f"[DEBUG] Writing metadata to {image_path}: {final_tags}", file=sys.stderr)

    try:
        subprocess.run(
            [EXIFTOOL_PATH, "-XMP:Subject=" + final_tags, "-overwrite_original", str(image_path)],
            capture_output=True, text=True, check=True
        )
    except subprocess.CalledProcessError:
        print(f"[ERROR] Failed to write metadata to {image_path}", file=sys.stderr)

def detect_objects(image_path):
    """Detect objects in an image and return a list of detected object names."""
    print(f"[PROCESSING] {image_path}", file=sys.stderr)
    results = model(image_path)

    detected_objects = set()
    
    for result in results:
        for box in result.boxes.data:  # Loop through detected objects
            confidence = float(box[4])  # Confidence score is in column index 4
            class_id = int(box[5])  # Class ID is in column index 5

            if confidence >= CONFIDENCE_THRESHOLD:  # Keep only confident detections
                detected_objects.add(result.names[class_id])

    if detected_objects:
        print(f"[DETECTED] {image_path}: {', '.join(detected_objects)}", file=sys.stderr)
    else:
        print(f"[INFO] No high-confidence objects detected in: {image_path}", file=sys.stderr)

    return list(detected_objects)

if __name__ == "__main__":
    image_folder = Path(sys.argv[1])
    output = {}

    print(f"[INFO] Searching for images in: {image_folder.resolve()}", file=sys.stderr)

    # Get all images
    image_files = list(image_folder.rglob("*.jpg"))
    print(f"[INFO] Found {len(image_files)} images.", file=sys.stderr)

    if not image_files:
        print("[WARNING] No images found. Exiting.", file=sys.stderr)
        sys.exit(0)

    for image_path in image_files:
        objects = detect_objects(str(image_path))
        if objects:
            output[image_path.name] = objects  # Save detected objects
            write_metadata(image_path, objects)  # Merge and write metadata

    print(f"[INFO] Processed {len(output)} images with detected objects.", file=sys.stderr)

    # Print JSON output
    print(json.dumps(output, indent=4))
