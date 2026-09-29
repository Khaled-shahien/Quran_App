# Architecture Boundaries

## Composition Root

`AppRoot` owns app-scoped `ChangeNotifier` instances and disposes them when the root is removed. Repositories and shared preferences are injected from GetIt and exposed as values to the provider tree.

## Feature Data Boundaries

- Feature repositories own local assets, HTTP data sources, and cache interaction.
- Feature providers own presentation state and call repository/domain contracts.
- Screens should not directly construct repositories or mutate shared persistence except for settings controls that already delegate to a provider.

## Cross-Cutting Services

- `NotificationSchedulingCoordinator` is the foreground scheduling boundary.
- `WorkManagerService` owns durable background registration and callback execution.
- `CachedApiService` owns cache age, invalidation, and parsed-cache rejection.
- `PreferenceSchema` owns persisted-preference version migration.
- `MonitoringService` owns optional analytics/crash-reporting configuration.

## Known Scope Boundaries

Some route-level media providers are intentionally created by GoRouter because their lifetime is limited to the route. They must remain route-scoped and should not be promoted to global state without a product need.

The remaining architecture work is primarily verification and incremental cleanup: add lifecycle tests around root disposal, keep repository contracts stable, and avoid introducing new direct service-locator access from feature widgets.
