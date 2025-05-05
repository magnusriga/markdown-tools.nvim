# Contributing to markdown-tools.nvim

Thank you for considering contributing to `markdown-tools.nvim`! We appreciate your time and effort.

## How Can I Contribute?

### Reporting Bugs

- Ensure the bug was not already reported by searching on GitHub under [Issues](https://github.com/magnusriga/markdown-tools.nvim/issues).
- If you're unable to find an open issue addressing the problem, [open a new one](https://github.com/magnusriga/markdown-tools.nvim/issues/new). Be sure to include a **title and clear description**, as much relevant information as possible, and a **code sample** or an **executable test case** demonstrating the expected behavior that is not occurring.
- Use the "Bug Report" template if available.

### Suggesting Enhancements

- Open a new issue to discuss your enhancement suggestion. Please provide a clear description of the enhancement and its potential benefits.
- Use the "Feature Request" template if available.

### Development Setup

Please refer to the [Development section in the README.md](README.md#development) for instructions on setting up your environment, running tests, and linting code.

### Pull Requests

1.  **Branch:** Create your feature branch from `main` (`git checkout -b feat/my-new-feature main`). Direct commits to `main` are blocked.
2.  **Code:** Make your changes.
3.  **Test:** If you've added code that should be tested, add tests in the `tests/` directory. Run `make test` to ensure all tests pass.
4.  **Format:** Format your code using `make format`. Run `make lint` to check for issues.
5.  **Commit:** Commit your changes using the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format. The commit hook will validate your message.
    ```bash
    git commit -m "feat: Add amazing new feature"
    # or
    git commit -m "fix: Correct issue with table insertion"
    ```
6.  **Push:** Push your feature branch to your fork (`git push origin feat/my-new-feature`).
7.  **Pull Request:** Open a pull request against the `main` branch of the `magnusriga/markdown-tools.nvim` repository. Provide a clear description of your changes.

## Styleguides

### Code Style

- Please try to follow the coding style of the existing codebase.
- Use `stylua` for formatting Lua code (`make format`).

### Commit Messages

- This project strictly follows the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification. Adherence is enforced by commit hooks.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
