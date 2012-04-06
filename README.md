Warning
===
This is still a work in progress. The API for modifying elements will be cleaned up to remove the need for hackish data management for updating elements, everything else should be final.

Overview
===
Reduces the complexity for dealing with importing and exporting using the [Google Contacts v3](https://developers.google.com/google-apps/contacts/v3/) API. Handles preserving the existing data and modifying any new data added without having to deal with it yourself. Supports all of the API calls except for photo management.

Compability
-
Tested against Ruby 1.8.7, 1.9.2, 2.0.0, RBX and JRuby, build history is available [here](http://travis-ci.org/Placester/google-contacts).

<img src="https://secure.travis-ci.org/Placester/google-contacts.png?branch=master&.png"/>

Documentation
-
See http://rubydoc.info/github/Placester/google-contacts/master/frames for full documentation.

License
-
Dual licensed under MIT and GPL.