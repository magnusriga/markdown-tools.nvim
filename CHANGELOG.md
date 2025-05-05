<!-- markdownlint-disable MD024 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added comprehensive test suite using `plenary.nvim`.

### Changed

- Updated `MarkdownCodeBlock` command to correctly handle visual selections, including multi-line selections and selections starting mid-line.

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

[Unreleased]: https://github.com/magnusriga/markdown-tools.nvim/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/magnusriga/markdown-tools.nvim/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/magnusriga/markdown-tools.nvim/compare/v0.1.0...v1.0.0
