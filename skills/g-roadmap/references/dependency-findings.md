# g-roadmap Step 0 — handling dependency-auditor findings

Load when the dependency-auditor dispatched in Step 0 returns findings.

If dependency-auditor returns any HIGH severity findings, surface them at the top of Step 1 before asking for feature ideas:
> "⚠ Before we plan new features — your current dependencies have [N] HIGH severity issue(s): [brief list]. These should be a milestone in the roadmap, likely early. I'll flag this during sequencing."

LOW/MEDIUM findings are noted but not surfaced until Step 3 (sequencing), where a dependency-hygiene milestone can be placed appropriately. Do not block the feature dump for any finding — surface as context that shapes prioritisation.
