# Release Workflow

This repository uses GitHub Actions to automatically create releases when you push a new tag to the main branch.

## How it works

1. **Trigger**: The workflow triggers when you push a tag starting with `v` (e.g., `v1.0.0`, `v2.1.3`) to the `main` branch
2. **Validation**: It runs Swift build and tests to ensure the code is working
3. **Changelog**: Automatically generates release notes from git commits
4. **Release**: Creates a GitHub release with the tag, release notes, and source archive

## Creating a Release

### Method 1: Using Git (Recommended)

```bash
# Make sure you're on the main branch and it's up to date
git checkout main
git pull origin main

# Create and push the tag
git tag v2.0.0
git push origin v2.0.0
```

### Method 2: Using GitHub CLI

```bash
# Create and push the tag
gh release create v2.0.0 --generate-notes
```

### Method 3: Using GitHub Web Interface

1. Go to your repository on GitHub
2. Click on "Releases" → "Create a new release"
3. Choose or create a tag (e.g., `v2.0.0`)
4. The workflow will automatically run and create the release

## Tag Naming Convention

- Use semantic versioning: `v1.0.0`, `v1.1.0`, `v1.0.1`
- Beta/Alpha releases: `v2.0.0-beta.1`, `v2.0.0-alpha.1`
- Release candidates: `v2.0.0-rc.1`

## What the Workflow Does

1. **Builds the Swift package** to ensure it compiles
2. **Runs tests** to ensure everything works
3. **Generates changelog** from commit messages
4. **Creates release notes** with:
   - List of changes since last release
   - Installation instructions for Swift Package Manager and CocoaPods
   - Links to documentation
5. **Uploads source archive** as a release asset
6. **Marks as prerelease** if tag contains `beta`, `alpha`, or `rc`

## Commit Message Format

For better changelog generation, use conventional commit messages:

- `feat: add new feature` - New features
- `fix: resolve issue` - Bug fixes
- `docs: update documentation` - Documentation changes
- `refactor: improve code structure` - Code refactoring
- `test: add test cases` - Test additions

## Troubleshooting

### Workflow doesn't trigger
- Make sure the tag starts with `v` (e.g., `v1.0.0`, not `1.0.0`)
- Ensure you're pushing to the `main` branch
- Check that the tag doesn't already exist

### Build fails
- Ensure your Swift code compiles locally
- Run `swift build` and `swift test` locally first
- Check that all dependencies are properly specified

### Release creation fails
- Verify you have write permissions to the repository
- Check that the `GITHUB_TOKEN` secret is available (it should be automatic)

## Customization

You can modify the workflow in `.github/workflows/release.yml` to:
- Change the trigger conditions
- Modify the changelog generation
- Add additional release assets
- Change the Swift version used for building
- Add additional validation steps
