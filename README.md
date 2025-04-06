# Mobile EBT Store Locator

Mobile EBT Store Locator is a Flutter-based mobile application designed for iOS devices. It provides a streamlined, mobile-friendly version of the official EBT Store Locator website, allowing users to quickly locate active EBT retailers on a Google Maps interface.

## Features

- **Google Maps Integration:**  
  Visualize active EBT retailer locations on an interactive Google Map.
  
- **CSV Data Parsing:**  
  Loads and parses retailer data (including location details) from a CSV file stored in the assets folder.
  
- **Active Store Filtering:**  
  Filters out inactive retailers (stores with an "End Date") to display only currently active locations.
  
- **Filtering by Distance & Store Type (Planned):**  
  Easily narrow down search results based on proximity and retailer category.

- **User-Friendly Interface:**  
  Clean and intuitive UI optimized for iOS devices.

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Xcode](https://developer.apple.com/xcode/) (for building and running on iOS)
- A valid [Google Maps API key](https://developers.google.com/maps/documentation/ios-sdk/start) configured for iOS
