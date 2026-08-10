# Changelog

All notable changes to this module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

### Added

- `azurerm_container_app_environment`: `internal_load_balancer_enabled` override (default `true`, unchanged behaviour) so `public_network_access = "Enabled"` can actually take effect when set to `false`.
- `lifecycle.precondition` on `azurerm_container_app.apps`: fails plan with a clear message instead of an opaque "Invalid index" error when a `container-app-environment` sets `registry_id` (existing registry) without also setting `registry_pull_umi`.
- `lifecycle.precondition` on `azurerm_container_app.apps`: fails plan when `ingress_exposed_port` is set without `ingress_transport = "tcp"`.
- `lifecycle.precondition` on `azurerm_container_app_environment.env`: fails plan when `public_network_access = "Enabled"` is set while `internal_load_balancer_enabled` is (still) `true`, since the setting would have no effect.
- `check "custom_domain_requires_certificate"`: warns when an app's `custom_domain_names` references a `container-app-environment` with no `cert_name` configured (previously silently skipped custom domain creation for that app).
- `tests/container_app.tftest.hcl`: `auto_created_registry_path` run (covers the `registry_id = null` / auto-created ACR path via the `containerRegistry` child module — previously untested), `existing_registry_without_pull_umi_fails` and `exposed_port_requires_tcp_transport_fails` regression runs for the new preconditions.
- GitHub Actions in all three workflows pinned to immutable commit SHAs (with version comment) instead of mutable tags.
- `.github/workflows/documentation.yml`: explicit `permissions: { contents: write }` and explicit `repository:` on checkout.

### Fixed

- `local.app_umi_id_map` (apps.tf): the fallback lookup into `module.containerRegistry[...]` is now wrapped in `try(..., null)` so a caller misconfiguration (existing `registry_id` without `registry_pull_umi`) surfaces as the new precondition's error message instead of a raw Terraform "Invalid index" crash.
- `azurerm_container_app_custom_domain.example` for_each: no longer crashes plan with an "Invalid index" error when an app's environment has no certificate configured; the domain is skipped and flagged by the new `check` block instead.

## v0.4.0 - 2026-08-10

### Added

- `providers.tf`: `required_version >= 1.9`, `azurerm ~> 5.0`, `azapi ~> 2.0` (previously unpinned — README showed "No requirements").
- `azurerm_container_app_environment`: `name` override, `infrastructure_resource_group_name` override, `zone_redundancy_enabled`, `mutual_tls_enabled`, `public_network_access`, `logs_destination`, `dapr_application_insights_connection_string`.
- `azurerm_user_assigned_identity` (environment UMI): `umi_name` override, `umi_isolation_scope`.
- `azurerm_container_app`: `name` override, `max_inactive_revisions`, `max_replicas`, `secret` block, `dapr` block, ingress `transport`, `allow_insecure_connections`, `exposed_port`, `ip_security_restriction`, `cors`.
- `tests/`: `container_app_environment.tftest.hcl`, `container_app.tftest.hcl`, `upgrade_compat.tftest.hcl` (11 runs, `mock_provider` coverage for every optional argument/block).
- `.gitignore`, `.gitattributes`, `.tflint.hcl`.
- `.github/workflows/terraform-ci.yml` (fmt, init, validate, test, tflint), `.github/workflows/release.yml` (release on merge, tag sourced from `ESLZ/containerapps.tf`'s `?ref=`).
- README: static title/description + "New arguments" section above the `terraform-docs` markers; requirements/providers tables now render correctly.

### Changed

- Bumped child module `terraform-azurerm-caf-container-registry` ref from `v1.0.1` to `v1.1.0` (required for azurerm 5.0.1 compatibility — see Known blockers below).
- All three module outputs (`environments`, `apps`, `registries`) marked `sensitive = true` (they expose full resource objects).
- `.github/workflows/documentation.yml`: bumped `actions/checkout` to `v7.0.1` and `terraform-docs/gh-actions` to `v1.4.1`.
- `ESLZ/containerapps.tf`: bumped module `ref` from `v0.3.2` to `v0.4.0`; added its own `terraform { required_version }` block for standalone `tflint`.
- `ESLZ/containerapps.tfvars`: documented every new optional argument as commented examples.

### Fixed

- `azurerm_container_app.apps`: `http_scale_rule.authentication` dynamic block referenced the wrong iterator (`http_scale_rule.authentication` instead of `http_scale_rule.value.authentication`), which would have failed to resolve the `authentication` block's `for_each` for any caller supplying `http_scale_rules[*].authentication`. Fixed and covered by `tests/container_app.tftest.hcl`'s `http_scale_rule_authentication` run.

### Known blockers (resolved)

- Originally, `terraform-azurerm-caf-container-registry` was pinned at `v1.0.1` (its only/latest release at the time) and was incompatible with azurerm 5.0.1 (`trust_policy_enabled` removed, `global_endpoint_routing_enabled` now required, `regional_endpoint_enabled` renamed on `azurerm_container_registry`). This blocked the auto-create-registry path (the existing-registry `registry_id` path was unaffected). Resolved once `terraform-azurerm-caf-container-registry v1.1.0` was published with azurerm 5.0.1 support; ref bumped accordingly.
