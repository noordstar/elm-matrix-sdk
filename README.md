# Matrix SDK in Elm

The Matrix SDK in Elm allows users to communicate with other instances using
the [Matrix](https://matrix.org) protocol.

The Elm SDK serves as a more consistent alternative to the
[matrix-js-sdk](https://github.com/matrix-org/matrix-js-sdk/), which is a
JavaScript implementation of the Matrix protocol with several downsides. In
contrast, the Elm SDK supports:

- ✅ **Matrix spec version adjustment** based on which spec version the
homeserver supports. The matrix-js-sdk spec uses endpoints from legacy versions
and exclusively supports the latest 4 spec versions, while this SDK listens to
the homeserver's supported spec versions and talks to the server accordingly.
See [docs/supported.md](docs/supported.md) to discover which interactions are
supported for which spec versions.

- ✅ **One way to do things** instead of having multiple functions that are
considered deprecated.

## Learn more

- Follow us on Mastodon: [@elm_matrix_sdk@social.noordstar.me](https://social.noordstar.me/@elm_matrix_sdk)
- Join the Matrix room: [#elm-sdk:matrix.org](https://matrix.to/#/#elm-sdk:matrix.org)
- Follow development at the [beta repository](https://github.com/noordstar/elm-matrix-sdk-beta).
