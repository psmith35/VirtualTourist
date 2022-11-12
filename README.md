# Virtual Tourist

This iOS app allows a user to add pins to an MKMapView and view photos based on the location of the pins on said map view using the Flickr API.

## Features

- Adding Map Pins
- Viewing/Editing Photo Collections

## Tech Stack

- **Languages:** Swift

- **Software:** Xcode, Git

- **Frameworks:** UIKit, CoreData, Foundation, MapKit

## API Reference

```http
  GET /?method=flickr.photos.search&api_key={apiKey}&bbox=-10%2C-10%2C10%2C10&content_type=1
  &lat={lat}&lon={lon}&page={page}&per_page={perPage}&format=json&nojsoncallback=1
```

| Parameter | Type     | Description                                        |
| :-------- | :------- | :------------------------------------------------- |
| `apiKey`  | `String` | **Required.** API Key to use.                      |
| `lat`     | `Double` | **Optional.** A latitude value for geo searching.  |
| `lon`     | `Double` | **Optional.** A longitude value for geo searching. |
| `page`    | `Int`    | **Optional.** The page of results to return.       |
| `perPage` | `Int`    | **Optional.** Number of photos to return per page. |

## Screenshots

| Adding Pins to the Map | Photo Collection |
| :----------------- | :----------------- |
| ![App Screenshot](https://live.staticflickr.com/65535/52493701651_f51fe4f262_w.jpg) | ![App Screenshot](https://live.staticflickr.com/65535/52493218697_918d9edc5f_w.jpg)|
