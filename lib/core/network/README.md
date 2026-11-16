# API integration

The app currently has no configured backend URL or API endpoints. Supply the
real environment URL when constructing a client with `createApiClient` from
`dio_factory.dart`; do not commit secrets or environment-specific credentials.

Keep HTTP request/response mapping in the relevant feature's `data` layer and
map transport DTOs into feature `domain/models`. Repositories should depend on
the configured `Dio` instance rather than constructing clients in screens.
