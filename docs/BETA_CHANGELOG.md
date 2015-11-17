### 2.4.0

* Change onboarding callback to use a block rather then a delegate message. - 1aurabrown
* Migrated to frameworks under the hood. This is a massive change to a lot
  of the foundations of the app. Most importantly it required making breaking 
  changes to facebook that are more or lesss impossible to test automatically. - orta
* Load all artworks in an artwork's show in the "artwork related artworks" view. - 1aurabrown
* Fixes auctions route. – ashfurrow
* Fix crash that could easily occur when the user would navigate back from a martsy view before it was fully done loading. - alloy
* Remove opaque background from Search keyboard. - 1aurabrown
* Adds local downloading of the shows feed for instant loading on the next run - orta
* Unify way to set whether to perform work asynchronously with ARPerformWorkAsynchronously - jorystiefel
* [iOS 9] Fix FLKAutoLayout issues with top and bottom layout guides. - alloy
* [iOS 9] Allow non-SSL connections to any domain. This is needed for now as we might present non-SSL sites in the
  external web-browser. - alloy
* [iOS 9] Fix tab bar not showing. - alloy
* [iOS 9] Fix search view text field not showing. - alloy
* [iOS 9] Fix artwork view layout on first launch. - alloy
* [iOS 9] Fix artwork view layout after rotating into and out of VIR. - alloy
* [iOS 9] Fix layout of artwork set view after rotating into and out of VIR. - alloy
* [iOS 9] Fix layout of onboarding views. - alloy
* [iOS 9] Fix artist view not getting a frame when opened from a search result. - alloy
* [iOS 9] Ensure cells on genes overview are all properly sized on first launch. - alloy
* [iOS 9] Ensure navigation buttons are shown/hidden on gene view when scrolling. - alloy
* [iOS 9] Fix views where undefined behaviour of FLKAutoLayout constraints was being depended on. - alloy
* [iOS 9] Make all uses of FLKAutoLayout explicit. - alloy
* Skip onboarding flow when registering to bid on iPhone - jorystiefel
* Adds a web view admin gesture to get information. Do a long press on a blank space on any web view - orta
* Fix artwork zoom bug and only zoom if we have a big enough tiled image for iPad screen - 1aurabrown
* Add Artwork "Exhibition History" section to More Info view - jorystiefel
* Add a warning message when creating account if password too short or email doesn't validate - jorystiefel
* Convert to AFNEtworking 2.0
* Fix FLKAutoLayout issues with top and bottom layout guides. - alloy
* Caches website content from martsy/force, vastly speeding up hybrid pages - orta
* Layout fixes for the Auction Results for an Artwork - orta
* Total Re-write for the show feed - orta