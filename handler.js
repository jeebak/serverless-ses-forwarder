"use strict";

var forwarder = require('aws-lambda-ses-forwarder')

module.exports.handle = (event, context, callback) => {
  var overrides = {
    config: {
      fromEmail: "noreply@example.com",
      subjectPrefix: "",
      emailBucket: "s3-bucket-name",
      emailKeyPrefix: "emailsPrefix/",
      forwardMapping: {
        "info@example.com": [
          "example.john@example.com",
          "example.jen@example.com"
        ],
        "abuse@example.com": [
          "example.jim@example.com"
        ],
        "@example.com": [
          "example.john@example.com"
        ],
        "info": [
          "info@example.com"
        ]
      }
    }
  };
  forwarder.handler(event, context, callback, overrides)
};