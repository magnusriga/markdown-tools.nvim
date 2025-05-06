## [1.4.0](https://github.com/magnusriga/markdown-tools.nvim/compare/v1.3.1...v1.4.0) (2025-05-06)

### Features

* added list continuation tests ([#13](https://github.com/magnusriga/markdown-tools.nvim/issues/13)) ([c50953c](https://github.com/magnusriga/markdown-tools.nvim/commit/c50953c3871921db0ac225ca4a07021168e5358e))

## [1.3.1](https://github.com/magnusriga/markdown-tools.nvim/compare/v1.3.0...v1.3.1) (2025-05-05)

### Bug Fixes

* added husky exception for semantic release ([#9](https://github.com/magnusriga/markdown-tools.nvim/issues/9)) ([1283f50](https://github.com/magnusriga/markdown-tools.nvim/commit/1283f5052db5fd9efe54b93a35590c7f6628a550))
* ci update ([#8](https://github.com/magnusriga/markdown-tools.nvim/issues/8)) ([2784f73](https://github.com/magnusriga/markdown-tools.nvim/commit/2784f73d7d8345e35ff807df7c6ce926602eebcb))
* ci updates ([#6](https://github.com/magnusriga/markdown-tools.nvim/issues/6)) ([9d51610](https://github.com/magnusriga/markdown-tools.nvim/commit/9d516104e785b865ba42dc29c30470a13333ada2))
* semantic-release ([#11](https://github.com/magnusriga/markdown-tools.nvim/issues/11)) ([84b4360](https://github.com/magnusriga/markdown-tools.nvim/commit/84b436001ba2bcebc153b3391c584049411192b1))
* semantic-release ([#12](https://github.com/magnusriga/markdown-tools.nvim/issues/12)) ([ce84dc4](https://github.com/magnusriga/markdown-tools.nvim/commit/ce84dc49f559c396ea277bcafa8dc9a771cf7563))

<!-- markdownlint-disable MD024 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Updated actions.

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [1.1.0] - 2025-05-05

### Added

- Added comprehensive test suite using `plenary.nvim`.
- Added `stylua` for code formatting and linting.

### Changed

- Updated `MarkdownCodeBlock` command to correctly handle visual selections, including multi-line selections and selections starting mid-line.
- Formatted codebase using `stylua`.

## [1.0.1] - 2025-05-05

### Added

### Changed

- Allow `MarkdownNewTemplate` command to be used in any filetype.

### Deprecated

### Removed

### Fixed

- Visual mode keymap for inserting headers now correctly exits visual mode before executing the command.

### Security

## [1.0.0] - 2025-05-05

### Added

- Added default keybinding `<leader>mH` for inserting headers.
- Added ability to use generator functions for frontmatter and placeholders in templates.
- Added health checks (`:checkhealth markdown-tools`).
- Initial release of `markdown-tools.nvim`.

### Changed

- Updated health checks (`:checkhealth markdown-tools`).

### Deprecated

### Removed

### Fixed

### Security

[Unreleased]: https://github.com/magnusriga/markdown-tools.nvim/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/magnusriga/markdown-tools.nvim/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/magnusriga/markdown-tools.nvim/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/magnusriga/markdown-tools.nvim/compare/v0.1.0...v1.0.0
