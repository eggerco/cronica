<p align="center">
    <img src="https://www.oncronica.com/resources/img/cronica/icon.webp" alt="Cronica Icon" width="150" height="150" />
</p>

<h1 align="center">
Cronica
</h1>

<p align="center">
    Cronica is a minimalist watchlist app that reminds you about upcoming releases.
</p>

<p align="center">
    <a href="https://www.x.com/CronicaApp">
        <img src="https://img.shields.io/badge/X-@CronicaApp-blue.svg?style=flat" alt="X: @CronicaApp" />
    </a>
    <img src="https://img.shields.io/github/license/egger/cronica" alt="GitHub License MIT Badge" />
</p>

## About

Cronica is built using Swift and SwiftUI, it uses Core Data to persist the user's watchlist, and CloudKit to sync the list effortlessly between the user's device. 

To provide release notifications, the app takes advantage of local notifications to notify users about new episodes or a movie release. To keep notifications useful, there's a background task that updates item values with new information using TMDb API, if needed.

Thanks to CloudKit and SwiftUI, Cronica also can run on every Apple device, and the information will automatically sync.

## Project Organization

If you want to contribute with code, here are some important details about the project's organization:

- The code-base for the Mac, iPhone, iPad, and Apple TV versions is shared and resides within the "Shared" folder.
- While the Apple Watch also utilizes the same networking as the other platforms, it has a different user interface (UI) design. The Apple Watch-specific UI components are located in the "Apple Watch" folder. However, certain UI components are shared among all platforms and can be found in the "Shared" folder.
- The views are organized based on their relationship with models or functionality. For instance, the "ItemContent" struct represents data fetched from the TMDb service, which can refer to a movie or a TV show. The UI elements associated with this struct are grouped under the "ItemContent" group in the "Views" folder. An example of such a UI element is the details page that users see when they open a movie.
- The logic for most of the views is separated using extensions, primarily to help maintain the project in the long run.

## Help Translate Cronica

Contribute to the localization efforts of our open-source project by assisting in the translation of the application into your native language. Utilize the provided [xcstrings file](https://github.com/egger/cronica/blob/main/Shared/Localization/Localizable.xcstrings), which contains all the strings requiring translation. Simply send your completed translations via email, and I will ensure their incorporation in the upcoming update. Your contributions play a crucial role in making Cronica accessible to everyone. Thank you for your support!

## Build information

#### Targets iOS 17+, iPadOS 17+, watchOS 10+, macOS 14+, tvOS 17+, visionOS 1+. Requires **Xcode 26** (iOS 26 SDK) for App Store submissions.

To get started:

1. Install [Xcode 26](https://developer.apple.com/xcode/) or later.
2. Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig`.
3. Add your TMDb API key to `Config/Secrets.xcconfig` (get one at [TMDb](https://www.themoviedb.org/documentation/api)).
4. Open `Cronica.xcodeproj` and build with the **Cronica (EN-US)** scheme.

For CI, set repository secrets `TMDB_API_KEY`, optionally `APTABASE_CLIENT_KEY`, and `SENTRY_DSN`. See [SECURITY.md](SECURITY.md) for the full security policy.

### Architecture

Shared TMDb models and networking live in the local Swift package `Packages/CronicaCore`, used by the app, widget, watch app, and tests.

## App Store

### iOS & iPadOS

<p align="center">
	<img src="https://raw.githubusercontent.com/egger/cronica/main/Screenshots/iPad.webp" alt="Cronica running on iPad displaying the details page for the TV Show Kaguya-sama: Love Is War." minWidth="220" maxWidth="440" maxHeight="340">
</p>
<p align="center">
<a href="https://apple.co/38SXpVJ">
	<img src="https://www.oncronica.com/resources/img/cronica/AppStoreBadge.svg" alt="Badge for download Cronica on App Store" width="160" height="80">
</a>
</p>

### Apple Watch

<p align="center">
	<img src="https://raw.githubusercontent.com/egger/cronica/main/Screenshots/Apple%20Watch.webp" alt="Cronica running on Apple Watch S7." minWidth="220" maxWidth="440" height="240">
</p>
<p align="center"> 
<a href="https://apps.apple.com/app/cronica/id1614950275">
	<img src="https://www.oncronica.com/resources/img/cronica/AppStoreBadge.svg" alt="Badge for download Cronica on Apple Watch App Store" width="160" height="80">
</a>
</p>

### Mac

<p align="center">
	<img src="https://raw.githubusercontent.com/egger/cronica/main/Screenshots/Mac.webp" alt="Cronica running on MacBook Air displaying details for Top Gun: Maverick." width="440">
</p>
<p align="center">
<a href="https://apple.co/38SXpVJ">
	<img src="https://raw.githubusercontent.com/egger/cronica/main/Screenshots/Badges/Mac.svg" alt="Badge for download Cronica on Mac App Store" width="160" height="80">
</a>
</p>

### Apple TV

<p align="center">
	<img src="https://raw.githubusercontent.com/egger/cronica/main/Screenshots/TV.webp" alt="Cronica running on Apple TV displaying details for Top Gun: Maverick." width="560">
</p>
<p align="center">
<a href="https://apps.apple.com/app/cronica/id1614950275">
	<img src="https://raw.githubusercontent.com/egger/cronica/main/Screenshots/Badges/AppleTV.svg" alt="Badge for download Cronica on Apple TV App Store" width="160" height="80"> 
</a>
</p>

### Apple Vision Pro

<p align="center">
	<img src="https://raw.githubusercontent.com/egger/cronica/main/Screenshots/Vision.webp" alt="Cronica running on Apple Vision Pro displaying details for Top Gun: Maverick." width="440">
</p>
<p align="center"> 
<a href="https://apps.apple.com/app/cronica/id1614950275">
	<img src="https://www.oncronica.com/resources/img/cronica/AppStoreBadge.svg" alt="Badge for download Cronica on Apple Vision Pro App Store" width="160" height="80">
</a>
</p>


## Contact

- If you have any questions, you can send us an email at <a href = "mailto:support@eggerco.com">support@eggerco.com</a><br>
- Follow Cronica on X: [@CronicaApp](https://www.x.com/CronicaApp)