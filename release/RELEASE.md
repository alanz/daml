# Making a Release

1. Make a PR that bumps the version number in the `VERSION`
   file and adds a new header and label for the new version in
   `docs/source/support/release-notes.rst` (see previous releases as examples).
   Release notes should be cut and pasted under the new header from `unreleased.rst`.
   Each change outlined in `unreleased.rst` is preceded by the section to which it belongs: create one entry per section and add all pertaining items (without the section tag) to the release notes.
   It is important that the PR only changes `VERSION`, `release-notes.rst` and `unreleased.rst`.
1. "Squash and merge" the PR.
1. Once CI has passed for the corresponding master build, the release should be
   available on bintray and GitHub, as well as properly tagged.
1. Activate the new version with `da use VERSION`. Note that it will
   not be picked up by `da upgrade` at this point.
1. Run through the manual test plan described in https://docs.google.com/document/d/16amcy7bQodXSHjEmKhAUiaPf6O92gUbch1OyixDEvSM/edit?ts=5ca5be00.

   The test plan currently still targets the old `da` assistant. We
   will migrate the test plan fully to the new assistant soon but for
   now, there is a shorter test plan for the new assistant that
   you should run on Windows:

   1. Download the installer from https://github.com/digital-asset/daml/releases
   1. Close any running SDK instance in PowerShell (Navigator or Sandbox)
   1. Remove any existing installation: `rm -r -Force $env:AppData\daml`
   1. Run the installer.
   1. Open a new Powershell.
   1. Remove any existing quickstart directory : `rm -r quickstart`
   1. Run `daml new quickstart` to create a new project.
   1. Switch to the new project: `cd quickstart`
   1. Run `daml start`.
   1. Open your browser at `http://localhost:7500`, verify that you
      can login as Alice and there is one template and one contract.
   1. Kill `daml start` with Ctrl-C
   1. Run `daml studio` and open `daml/Main.daml`.
   1. Verify that the scenario result appears within 30 seconds.
   1. Add `+` at the end of line 26 after `"Alice"` and verify that you get a red squiggly line.

1. If it passes, the release should be made public. This currently
   consists of three steps:

   1. Tag the release as `visible-external` on Bintray. This step can
      only be done by someone with permissions to set tags on Bintray.
      After this step the release will be picked up by `da
      upgrade`. Note that this step requires special privileges on
      Bintray. If you cannot change it yourself, ask in #team-daml.

   1. Publish the draft release on GitHub by going to [the releases
      page](https://github.com/digital-asset/daml/releases) and clicking the
      Edit button for the relevant release.
