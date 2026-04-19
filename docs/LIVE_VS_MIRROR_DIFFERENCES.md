# Live AAP vs Public Mirror — Intentional Differences

This repo is the **public mirror** of the database compliance scanning
project. The **live AAP env** runs the same code with a small set of
deliberate differences. This doc is the single place to track them so
they don't drift unnoticed.

> **Last reconciled:** 2026-04-19, after PRs #10–#13 and the
> `inspec_cis_database`/`oar_tower_inventories` restructures.

## TL;DR

| Concern | Public mirror | Live AAP env |
|---|---|---|
| BU directory names | NATO-phonetic placeholders (`ALPHA`, `BRAVO`, …) | Real BU acronyms |
| Inventory file extension | none (e.g. `ALPHA_DEVTEST_NA_Inv_InSpec_Database`) | `.yml` (e.g. `CORP_DEVTEST_NA_Inv_InSpec_Database.yml`) |
| Inventory tooling location | `oar_tower_inventories/tools/` (separate repo) | `roles/inventory_converter/` inside the project repo |
| Branch model | single `main` in all three repos | feature branches (e.g. `feature/mssql_scan`) during testing |
| Delegate host placement | `delegate_hosts` group (Model B) | inside the BU group (Model A) |
| Host-id pattern | `<server>_<port>` (or `_<db>_<port>`) | same + optional `_<MODE_SUFFIX>` (e.g. `_direct`, `_winrm`, `_EE`, `_DELEGATE_CONNECTION`) |
| Inventory plugin noise | silenced by `enable_plugins = yaml,ini,auto` in `ansible.cfg` | sometimes still visible if EE/global config overrides project config |

Each row is unpacked below.

---

## BU directory names

**Why different.** CLAUDE.md's data-sensitivity rules forbid real
business-unit identifiers in the public mirror. The live env keeps the
real names because internal users need them.

**Mapping** (placeholder → real BU is intentionally **not** stored in
this repo).

| Public mirror | Live env  |
|---------------|-----------|
| `ALPHA`       | (real BU) |
| `BRAVO`       | (real BU) |
| `CHARLIE`     | (real BU) |
| `DELTA`       | (real BU) |
| `ECHO`        | (real BU) |

**Where it shows up:** `oar_tower_inventories/<BU>/` directory names,
`db_<bu>` group names, `ssc_sn_bu` group var values, `aap2-config/`
sample inventories and job-template survey choices.

**Drift risk:** low. If a new BU is added in live, add a new
phonetic placeholder here in the same shape.

---

## Inventory file extension

**Why different.** AAP's Inventory-Source UI lists files matching its
"file" filter; `.yml` is the conventional one for "Sourced from a
Project". The mirror dropped the extension because the file naming
convention `{BU}_{ENV}_{REGION}_Inv_InSpec_Database` is itself
unique enough and doesn't need it for parsing (the Ansible YAML plugin
inspects content, not just extension).

**Where it shows up:** filename pattern. Both ansible-inventory and the
yaml plugin happily parse either form, so this is cosmetic — but if
someone copies a sample file into the live env, they'll need to add
`.yml` for AAP to surface it.

---

## Inventory tooling location

**Why different.** Per the 3-repo split codified in CLAUDE.md, the
mirror keeps inventory generation in the inventory repo
(`oar_tower_inventories/tools/`). The live env still has those tools
under `roles/inventory_converter/` inside the linux-inspec project
because the AAP Project + Inventory Source pair was set up before the
split and hasn't been reconfigured yet.

**Drift risk:** medium. The two copies will drift unless changes flow
through both. Long-term fix: point a separate AAP Project at
`oar_tower_inventories` and create the Inventory Source from that
project. See the recent investigation in PR #10.

---

## Branching

**Mirror:** single `main` in all three repos
(`linux-inspec`, `inspec_cis_database`, `oar_tower_inventories`). The
old `NA_DEVTEST` and `NA_PROD` branches were retired (commit
`01c0aa6`) — env+region are encoded in inventory filenames and
`ssc_sn_*` group vars instead.

**Live:** still uses feature branches such as `feature/mssql_scan`
during active testing. These get merged into `main` when ready.

**Drift risk:** low while testing; should converge once live env
stabilises.

---

## Delegate host placement (Model A vs Model B)

The InSpec runner can sit in two valid places.

### Model A — delegate as a member of the BU group (live env)

```yaml
all:
  children:
    db_corp:
      vars:
        ssc_sn_bu: corp
        ansible_connection: local        # default for DB host_ids
      hosts:
        inspec-runner:                   # the real SSH target
          ansible_host: <runner-fqdn>
          ansible_user: ansible_svc
          ansible_connection: ssh        # overrides the group default
        DBHOST_PORT:
          database_platform: mssql
          ...
```

- ✅ `delegate_to: inspec-runner` resolves naturally.
- ⚠️ `hosts: db_corp` plays iterate the runner too — role logic must
  short-circuit on it (`when: database_platform is defined`).

### Model B — delegate in a separate top-level group (mirror)

```yaml
all:
  children:
    delegate_hosts:
      hosts:
        inspec-runner:
          ansible_host: <runner-fqdn>
          ansible_user: ansible_svc
          ansible_connection: ssh

    db_alpha:
      vars:
        ssc_sn_bu: alpha
        ansible_connection: local
        inspec_delegate_host: "inspec-runner"   # name string only
      hosts:
        DBHOST_PORT:
          database_platform: mssql
          ...
```

- ✅ Clean separation — `hosts: db_alpha` iterates DB labels only.
- ⚠️ `inspec_delegate_host` must point at an inventory hostname that
  exists somewhere (in `delegate_hosts` or elsewhere) for
  `delegate_to: "{{ inspec_delegate_host }}"` to work.

**Either model is correct.** The role's own `delegate_to` lookup
(`{{ inspec_delegate_host }}`) is the same in both — what differs is
where in the inventory tree the runner is defined.

**Common SSH-error symptom** (was a real failure in live, 2026-04-19):
if you forget `ansible_connection: local` on the BU group, Ansible
treats the DB `host_id` as a real hostname and tries to SSH to it,
failing with `Could not resolve hostname …`. Fix: add the line.

---

## Host-id pattern (MODE_SUFFIX)

The mirror's flat-file converter produces host_ids like:

```
<server-shortname>_<port>            # MSSQL
<server-shortname>_<db>_<port>       # Oracle / Sybase / Postgres
```

The live env uses an extended pattern with a connection-mode suffix:

```
<server>_<port>_<MODE>               # e.g. GDCTWVC0007_1733_direct
<server>_<port>_<MODE>               #      GDCTWVC0007_1733_winrm
                                     #      O02DIL0_1528_EE
                                     #      O02DIL0_1528_DELEGATE_CONNECTION
```

The suffix lets the same `(server, port)` appear in inventory more than
once with distinct host_ids — useful when validating multiple scan
configurations against the same physical database.

**Converter support:** the flat-file converter accepts an optional 8th
column `MODE_SUFFIX` (free text). When present, it's appended to the
host_id with an underscore. When absent, host_id is unchanged. See
`oar_tower_inventories/tools/README.md` for the input format and an
example.

**Note on semantics:** the suffix is purely a label. It does **not**
auto-toggle `use_winrm`, `inspec_delegate_host`, or any other
behaviour-affecting variable. The team's convention seems to be:
- `_direct` / `_winrm` → typically paired with `use_winrm: false/true`
- `_EE` / `_DELEGATE_CONNECTION` → typically paired with
  `inspec_delegate_host` empty vs set

But the converter doesn't enforce that pairing — set the relevant
behaviour vars yourself in the input or via `group_vars/host_vars`.

---

## Inventory plugin noise

**Mirror:** `linux-inspec/ansible.cfg` has
`[inventory] enable_plugins = yaml, ini, auto` so the
`host_list` and `script` plugins never get a chance to print
`declined parsing … did not pass its verify_file()` warnings.

**Live:** the same lines sometimes still appear in AAP project-update
logs because:
- AAP project syncs may not always honour project-local `ansible.cfg`
  (depends on EE config and where ansible-inventory is invoked from)
- The lines are harmless — they print at `-vvv` and the yaml plugin
  still parses successfully

**Verification path:** lower the AAP Inventory Source verbosity from
`2 (Debug)` to `0/1` to silence the noise without touching config.

---

## Adding a new live-vs-mirror difference

When a new intentional difference appears, add a row to the TL;DR table
above and a section below following the same shape:

1. **Why different** (the underlying constraint or decision)
2. **Where it shows up** (which files / fields / commands)
3. **Drift risk** (low / medium / high) and the convergence plan, if any

Avoid documenting **accidental** drift in this file — fix it instead.
