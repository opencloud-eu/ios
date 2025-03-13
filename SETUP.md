If you want to start help developing OpenCloud please follow the [contribution guidelines][0] and observe these instructions:


NOTE: To compile the code you need Xcode 10.2, iOS11, cocoa pods and swiftlint.

### 1. Fork and download ios-app/master repository:

* Navigate to https://github.com/opencloud/ios-app, click fork.
* Clone your new repo: ```git clone git@github.com:YOURGITHUBNAME/ios-app.git```
* Move to the project folder with ```cd ios-app```
* Checkout remote develop branch: ```git checkout -b master remotes/origin/master```
* Pull changes from your develop branch: ```git pull origin master```
* Make official OpenCloud repo known as upstream: ```git remote add upstream git@github.com:opencloud/ios-app.git```
* Make sure to get the latest changes from official ios-issues/master branch: ```git pull upstream master```


### 2. Add the OpenCloud iOS SDK:

NOTE: This will connect with our OpenCloud iOS Library repository at ```https://github.com/opencloud/ios-sdk```.

* Inside the folder ios:
  - Init the library submodule: ```git submodule init```
  - Update the library submodule: ```git submodule update```

### 3. Set up in your local

* [Cocoa pods][cocoapods]
* [Swiftlint][swiftlint]
* [EarlGrey][earlGrey]

[cocoapods]:https://cocoapods.org/
[swiftlint]:https://github.com/realm/SwiftLint/blob/master/README.md
[earlGrey]:https://github.com/google/EarlGrey/blob/master/docs/install-and-run.md#cocoapods-installation

### 4. Create your own certificates

NOTE: You must use the same "extension" on the certificates of the extensions (OpenCloudExtApp, OpenCloudExtAppFileProvider, OC-Share-Sheet)

* Login at https://developer.apple.com/ as developer and there to to the Certificates section.
* Create a Development Certificate for you (probably you got it one now)
* Create an App Id for the main app. Ex: com.mywebpage.opencloud.ios
* Create an AppGroup and add it too all the App Id. Must have the App Id than the main app but with the group. Ex: group.com.mywebpage.opencloud.ios
* Add the UDID of your device on the Devices section.
* Create 4 Development Profiles. One for each App Id.

### 5. Create pull request:

NOTE: You must sign the [Contributor Agreement][1] or contribute your code under the [MIT license][2] before your changes can be accepted! See the [iOS license exception][3] for testing the OpenCloud iOS app on Apple hardware.

* Remove your own App Id from the project and set again the OpenCloud ones:
  - Main app: eu.opencloud.ios

* Commit your changes locally: ```git commit -a```
* Push your changes to your Github repo: ```git push```
* Browse to ```https://github.com/YOURGITHUBNAME/ios/pulls``` and issue pull request
* Click "Edit" and set "base:master"
* Again, click "Edit" and set "compare:master"
* Enter description and send pull request.

### 6. Create another pull request:

To make sure your new pull request does not contain commits which are already contained in previous PRs, create a new branch which is a clone of upstream/master.

* ```git fetch upstream```
* ```git checkout -b my_new_master_branch upstream/master```
* If you want to rename that branch later: ```git checkout -b my_new_master_branch_with_new_name```
* Push branch to server: ```git push -u origin name_of_local_master_branch```
* Use Github to issue PR

## Translations
Please submit translations via [Transifex][transifex].

[transifex]: https://www.transifex.com/projects/p/opencloud/


[0]: https://github.com/opencloud/ios/CONTRIBUTING.md
[1]: https://opencloud.eu/about/contributor-agreement/
[2]: http://opensource.org/licenses/MIT
[3]: https://opencloud.eu/contribute/iOS-license-exception/

## Local OpenCloud server for testing

You can easily fire up an OpenCloud server on your Mac using Docker.

1. [Install Docker](https://docs.docker.com/docker-for-mac/)
2. Run this in Terminal.app to start OpenCloud with Docker
```
docker run --rm -d \
  --name opencloud \
  -p 18080:8080 \
  -e OPENCLOUD_APPS_ENABLE=oauth2 \
  -e ADMIN_USERNAME=admin \
  -e ADMIN_PASSWORD=admin \
  opencloud/server:latest
```
3. Access from local Mac browser or Simulator:  
 http://localhost:18080/  
 user: admin  
 password: admin
4. To test the  app on a iOS device in your local network, you can use the IP of your machine as the Server URL
5. To remove the OpenCloud Docker, just run `docker kill opencloud`

Here you can find more information about running OpenCloud with Docker:
https://github.com/opencloud-docker/server
