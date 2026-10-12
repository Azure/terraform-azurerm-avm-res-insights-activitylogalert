# Activity Log Alert

This module deploys a resource-group-scoped Azure Activity Log Alert using
AzAPI. The alert evaluates activity events for the supplied scopes and sends
matching events to configured Action Groups.

Supply an existing resource group's ID through `parent_id`. The module does
not create the resource group or Action Groups. `location` is the Azure region
used for telemetry; `resource_location` independently defaults to `global`.

Conditions support `equals` and `contains_any` leaves, with optional `any_of`
groups inside `condition.all_of`. Locks and role assignments apply to the alert.
