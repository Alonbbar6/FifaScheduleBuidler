# Stadium Indoor Navigation Data - Research Report

**Author:** Manus AI
**Date:** November 26, 2025

## 1. Introduction

This report details the findings of a comprehensive research initiative to gather indoor navigation data for the FIFA World Cup 2026 venues. The primary objective is to collect the necessary assets for developing an augmented reality (AR) wayfinding feature for a mobile application. The required data includes high-resolution floor plans, precise coordinate mapping for key points of interest (POIs), indoor positioning system data (e.g., BLE beacons), and a navigable routing graph for each stadium. This document outlines the availability of such data, the challenges in acquiring it, and a recommended strategy for moving forward.

## 2. FIFA World Cup 2026 Venues

The tournament will be held across 16 stadiums in three countries: the United States, Canada, and Mexico. The official venues are listed below [1].

| Country         | City                  | Stadium Name (Real Name)        | FIFA Official Name             |
| --------------- | --------------------- | ------------------------------- | ------------------------------ |
| Canada          | Vancouver, BC         | BC Place                        | BC Place Vancouver Stadium     |
| Canada          | Toronto, ON           | BMO Field                       | Toronto Stadium                |
| Mexico          | Mexico City, CDMX     | Estadio Azteca                  | Estadio Azteca Mexico City     |
| Mexico          | Guadalajara, JAL      | Estadio Akron                   | Estadio Guadalajara            |
| Mexico          | Monterrey, NL         | Estadio BBVA                    | Estadio Monterrey              |
| United States   | Atlanta, GA           | Mercedes-Benz Stadium           | Atlanta Stadium                |
| United States   | Boston, MA            | Gillette Stadium                | Boston Stadium                 |
| United States   | Dallas, TX            | AT&T Stadium                    | Dallas Stadium                 |
| United States   | Houston, TX           | NRG Stadium                     | Houston Stadium                |
| United States   | Kansas City, MO       | Arrowhead Stadium               | Kansas City Stadium            |
| United States   | Los Angeles, CA       | SoFi Stadium                    | Los Angeles Stadium            |
| United States   | Miami, FL             | Hard Rock Stadium               | Miami Stadium                  |
| United States   | New York/New Jersey   | MetLife Stadium                 | New York New Jersey Stadium    |
| United States   | Philadelphia, PA      | Lincoln Financial Field         | Philadelphia Stadium           |
| United States   | San Francisco Bay Area| Levi's Stadium                  | San Francisco Bay Area Stadium |
| United States   | Seattle, WA           | Lumen Field                     | Seattle Stadium                |

## 3. Data Availability and Sourcing

A multi-pronged approach was taken to identify sources for the required data, including official channels, third-party providers, and public data repositories.

### 3.1. Official and Public Sources

Research indicates that detailed indoor navigation data, such as CAD files, BIM models, and structured coordinate data (JSON/CSV), is **not publicly available** from official sources like FIFA or the individual stadium websites. The information that can be obtained is generally limited to static image files.

> **FIFA Official Website:** Provides basic stadium maps that show seating category layouts but lack the detail needed for granular wayfinding (e.g., concourse pathways, specific amenity locations) [1].

> **Individual Stadium Websites:** Offer seating charts that are more detailed, showing section numbers and gate names. For instance, the Hard Rock Stadium website provides a clear map of its seating levels and gate locations [2], while the MetLife Stadium site offers downloadable maps for its various concourses [3]. However, these are typically presented as PDF or PNG images and do not contain the structured, machine-readable data required for an AR application.

### 3.2. Commercial and Proprietary Data

The most accurate and detailed data is held by private entities and is not freely accessible. Accessing this data would require establishing direct business partnerships.

-   **Venue Technology Providers:** Companies such as **Mappedin** [4], **VenueNext**, and **YinzCam** specialize in digital fan experiences and have likely created detailed indoor maps for many of these venues. Similarly, **Navigine** and **ARway.ai** offer specific solutions for stadium wayfinding and AR navigation [5].
-   **Architectural and Engineering Firms:** The original BIM and CAD models are held by the architectural firms responsible for the stadium's design (e.g., HOK, Populous). These files contain the most precise data but are highly proprietary and are unlikely to be shared without a formal agreement.

### 3.3. Indoor Positioning Data

Data for indoor positioning systems, such as BLE beacon locations and UUIDs, is not publicly available. This information is specific to each stadium's technology infrastructure and would only be accessible through a partnership with the stadium operator or their technology provider. Research into the underlying technology shows a strong industry preference for BLE beacons due to their higher accuracy (±1-2 meters) compared to WiFi-based positioning (±5-10 meters) [6].

## 4. Data Acquisition and Development Strategy

Given the lack of publicly available, structured data, a multi-step strategy is recommended to create the required dataset.

### Step 1: Manual Digitization of Public Maps

The initial phase involves manually digitizing the publicly available seating charts and maps. This process would involve:
1.  **Image to Vector Conversion:** Converting the PNG/PDF maps into a vector format like SVG to create a scalable base layer.
2.  **Georeferencing:** Establishing a local coordinate system for each stadium (e.g., origin at center field) and georeferencing the vector map to real-world GPS coordinates.
3.  **Data Extraction:** Manually identifying and plotting the coordinates of key features, including seating sections, gates, concourses, stairs, elevators, and major amenities.

This process will yield a foundational dataset with an estimated accuracy of ±10-20 meters, which can be used for initial prototyping but falls short of the desired ±2-meter accuracy.

### Step 2: Structured Data Template Implementation

To ensure consistency, the collected data should be organized into the structured JSON and CSV formats specified in the initial request. A set of templates has been created for this purpose, covering:
-   **Coordinate Mapping:** A comprehensive JSON structure for all stadium features.
-   **Positioning Systems:** A template for documenting BLE beacon and WiFi access point data.
-   **Routing Graph:** A node-and-edge-based JSON structure for defining navigable paths.

A sample data file for Hard Rock Stadium has been created using this manual digitization approach to demonstrate the structure and the level of detail that can be achieved from public sources.

### Step 3: Direct Outreach and Partnerships

To achieve the required level of accuracy and completeness, direct engagement with data owners is essential. The recommended course of action is to:
1.  **Contact Stadium Operators:** Reach out to the facility management departments of each of the 16 stadiums to request access to their architectural drawings or BIM models.
2.  **Engage Technology Providers:** Initiate discussions with companies like Mappedin or Navigine to explore licensing their existing indoor map data.

### Step 4: On-Site Surveying and Verification

Professional, on-site surveying is the ultimate solution for achieving high-precision data. This would involve using technologies like LiDAR or photogrammetry to create a highly accurate 3D point cloud of the entire venue, from which precise coordinates and 3D models can be extracted.

## 5. Conclusion and Recommendations

While the request for comprehensive indoor navigation data is well-defined, the reality is that this data is not open or easily accessible. The path to building the desired AR wayfinding feature involves a significant data creation and acquisition effort.

It is recommended to proceed with a parallel approach:

-   **Internal Development:** Begin the manual digitization process to create a low-fidelity but functional prototype. This will allow the development team to build and test the core application logic.
-   **External Outreach:** Simultaneously, pursue partnerships with stadium operators and technology vendors to acquire the high-fidelity data needed for a production-ready application.

This dual strategy will enable progress on the application while the more complex and time-consuming data acquisition process is underway.

## 6. References

[1] FIFA. (2025). *STADIUM INFORMATION*. Retrieved from https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/stadium-information-details
[2] Hard Rock Stadium. (2025). *STADIUM SEATING CHART*. Retrieved from https://www.hardrockstadium.com/stadium-maps/
[3] MetLife Stadium. (2025). *Seating Charts & Maps*. Retrieved from https://www.metlifestadium.com/stadium/seating-charts-maps/
[4] Mappedin. (n.d.). *Interactive Stadium Mapping and Navigation Software*. Retrieved from https://www.mappedin.com/industries/stadiums
[5] Navigine. (n.d.). *Sports Stadium Wayfinding | Sports Tracking System*. Retrieved from https://navigine.com/industries/sport/
[6] Pointr. (2024). *WiFi or Bluetooth Beacons for indoor location?*. Retrieved from https://www.pointr.tech/blog/wifi-or-beacons-for-indoor-location
