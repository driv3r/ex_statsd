# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## tag [0.6.0] - 2016-11-24
### Added
- `tags` configuration option, those will be merged with passed in `tags` when executing functions.
- Added `ConfigExt` helpers in order to support dynamic configuration via environment variables or custom functions.

### Changed
- Refactored and extracted configuration to a separate `ExStatsD.Config` module.
- Updated `ExStatsD.stop/1` function.
