# Experiment Data Extraction – MATLAB UI

A MATLAB-based graphical user interface (GUI) for extracting, organizing, and processing multimodal experimental data from `.xdf` files across multiple subjects, activities, and experimental conditions.

This tool was developed to support large-scale human performance and sensorimotor experiments involving synchronized physiological, biomechanical, and behavioral data streams.

---

## Author

**Jeevan Jayasuriya**  
NeuroErgonomics Lab  
University of Wisconsin–Madison

---

## Overview

This repository provides a unified MATLAB UI for:

- Selecting subject ranges (e.g., S1–S10)
- Selecting experimental activities (single activity or all activities)
- Selecting data streams (e.g., fNIRS, EMG, Force Plate, Eye Tracking, Xsens kinematics)
- Extracting synchronized time series and time stamps from `.xdf` files
- Automatically routing extracted data to dedicated processing functions

The UI is designed to minimize manual file handling and enforce consistent data organization across large experimental datasets.

---

## Key Features

- Interactive MATLAB UI built with `uifigure`
- Batch extraction across:
  - Multiple subjects
  - Multiple activities
  - Pre/Post sessions
  - Stimulated / Non-stimulated trials
- Modular processing architecture
- Supports multimodal data streams commonly used in neuroergonomics research
- Easily extendable to new streams or processing functions

---

## Repository Structure

### UI and Core Logic
- `Main_UI_V1.m`  
  Main UI entry point (`Data_extraction_functions_v12`) and data extraction logic.

- `load_xdf.m`  
  XDF file loader used throughout the pipeline.

### Processing Modules
- `processfNIRS_V1.m`
- `processHomer3_V1.m`
- `processEMG_V1.m`
- `processHeartRate_V1.m`
- `processForcePlate_V1.m`
- `processEyeTracking_V1.m`
- `processLinearSegmentKinematics_V1.m`
- `processAngularKinematics1_V1.m`
- `processCenterOfMass1_V1.m`
- `processEulerDatagram1_V1.m`
- `processTimeFrames_V1.m`
- `processVideoFrames_V1.m`
- `processQuaternion.m`

### Utilities
- `Extract_ECG_from_XDFandActiheart.m`
- `CombineMATFiles.m`

---

## Supported Data Streams

- Brain data: fNIRS, Homer3
- Muscle & physiology: EMG, Heart Rate (including HRV metrics)
- Biomechanics: Force Plate, Center of Mass
- Motion capture (Xsens): Linear and Angular kinematics, Euler angles, Quaternions
- Perceptual & auxiliary: Eye Tracking, Video frames, Timestamp streams

Channel and segment options are dynamically updated in the UI based on the selected data type.

---

## How to Run

1. Clone or download the repository
2. Add the repository to your MATLAB path:
   ```matlab
   addpath(genpath(pwd))
   ```
3. Launch the UI:
   ```matlab
   Main_UI_V1
   ```
4. Use the UI to select subjects, activities, and data types, then click **Extract Data**.

---

## Outputs

Depending on the selected data type, processing functions may export processed data to MATLAB variables, save analysis-ready files, or generate plots. Output behavior is defined within each `process*.m` file.

---

## Extending the Tool

To add a new data stream:
1. Add the stream name to the UI dropdown
2. Define channel/segment options
3. Implement a new `processYourStream_V1.m`
4. Register it in the `switch dataType` block

---

## Notes

- File paths and storage locations are intentionally not hard-coded
- Users are expected to configure their own data directories externally
- Experimental data are not included in this repository

---

## License

This project is licensed under the **MIT License**. See the `LICENSE` file for details.

---

## Acknowledgments

Developed as part of ongoing research at the NeuroErgonomics Lab, University of Wisconsin–Madison.
