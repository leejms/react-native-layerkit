/**
 * @providesModule RNLayerKit
 * @flow
 */
'use strict';

var NativeRNLayerKit = require('NativeModules').RNLayerKit;
var invariant = require('invariant');

/**
 * High-level docs for the RNLayerKit iOS API can be written here.
 */

var RNLayerKit = {
  test: function() {
    NativeRNLayerKit.test();
  }
};

module.exports = NativeRNLayerKit;
