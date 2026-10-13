# Releasing Fine Volume

Fine Volume releases are built by GitHub Actions from version tags. The
workflow creates a universal, ad-hoc signed app bundle and attaches
`FineVolume.zip` to the GitHub release automatically.

## Checklist

1. Update `CFBundleShortVersionString` and `CFBundleVersion` in
   `Resources/Info.plist`.
2. Add user-visible changes to `CHANGELOG.md`.
3. Run the local checks:

   ```sh
   make test
   make package
   ```

4. Verify the package locally:

   ```sh
   codesign --verify --deep --strict dist/FineVolume.app
   unzip -l dist/FineVolume.zip
   ```

5. Commit the changes on a branch. Open a pull request and merge it after
   the checks pass. Fetch the merged commit and switch to it. Create an
   annotated tag that matches the plist. Push only the tag:

   ```sh
   git tag -a v0.6.0 -m "Fine Volume 0.6.0"
   git push origin v0.6.0
   ```

6. Confirm that the release workflow passes and that the ZIP is attached to
   the new GitHub release.

Releases currently use an ad-hoc signature so that anyone can build them from
source. Developer ID signing and notarization can be added later without
changing the app's runtime architecture.
