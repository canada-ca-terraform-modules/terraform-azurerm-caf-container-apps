# Changelog

All notable changes to this module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
