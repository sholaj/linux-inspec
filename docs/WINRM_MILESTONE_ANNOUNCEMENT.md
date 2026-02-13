# Database Compliance Scanning - WinRM Integration Complete

**Date:** 2026-02-13
**Status:** ✅ Complete

---

Team,

Excited to share that we've achieved a key milestone: **both WinRM and direct connection modes are now fully working** for MSSQL InSpec compliance scanning.

## What This Means

- Windows SQL Servers can now be scanned using AD/Windows Authentication via WinRM
- Linux SQL Servers continue to work with direct TDS connection
- Single `trusted.rb` profile handles both modes automatically

## Key Advantage - Simplified Credential Management

| Before (Direct Mode) | After (WinRM Mode) |
|---------------------|-------------------|
| SQL credentials per database | One AD service account per environment |
| Manage passwords on each server | Single credential in AAP2 |
| Complex onboarding | Simplified access via AD groups |

**Benefits:**
- **One AD service account per environment** can scan ALL Windows SQL Servers in that environment
- No need to create/manage individual SQL login credentials on each database server
- Reduces credential sprawl and simplifies onboarding
- Service account just needs SQL Server login permissions via Windows Auth

## Technical Details

**Username format:** UPN required (e.g., `svc_inspec@corp.example.com`)

**Command pattern:**
```bash
inspec exec <profile> -t winrm://<server> --user '<user@domain.com>' --password '<pass>'
```

**Profile auto-detection:** The `trusted.rb` profile automatically detects auth mode:
- Credentials provided → SQL Server Authentication
- No credentials → Windows Authentication (via WinRM identity)

## Next Steps

- [ ] Testing across additional SQL Server targets
- [ ] Documentation updates complete
- [ ] Ready for broader rollout planning

---

This unblocks our path to enterprise-wide MSSQL compliance scanning via AAP2.
