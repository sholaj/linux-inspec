# Problem Statement: Centralized Secret Management for Database Compliance Scanning

-----

## Current Challenge

Our organization currently lacks a standardized approach to managing database credentials across affiliates. Different business units use disparate toolsets for secret management—some affiliates rely on Cloakware while others use USM (Universal Secret Manager)—resulting in fragmented credential storage, inconsistent security controls, and operational complexity. This inconsistency creates challenges for enterprise-wide initiatives that require uniform access to database credentials, particularly as we modernize our compliance scanning infrastructure.

## Business Need

We are implementing automated NIST compliance scanning using Ansible Automation Platform 2 (AAP2) with InSpec to assess security posture across our database estate. This initiative covers approximately **100 MSSQL databases** and **105 Sybase databases** across multiple affiliates. To execute these scans programmatically, AAP2 requires secure, centralized access to database service account credentials at runtime—credentials that are currently scattered across multiple secret management systems with no unified retrieval mechanism.

## Proposed Solution

CyberArk Central Credential Provider (CCP) offers a standardized, enterprise-grade solution for programmatic credential retrieval that can serve all affiliates regardless of their current tooling. By centralizing database credentials in CyberArk, AAP2 can dynamically retrieve secrets at scan execution time without storing passwords in playbooks, inventory files, or local filesystems. This approach supports automatic password rotation, provides comprehensive audit logging, and eliminates the need to coordinate across disparate secret management platforms.

## Expected Outcome

Implementing CyberArk as the central credential store for database compliance scanning will enable consistent security controls across all affiliates, reduce operational overhead from managing multiple secret systems, and provide a scalable foundation for future automation initiatives. This demand intake requests CyberArk integration to support the immediate compliance scanning requirement while establishing a standardized secret management pattern for the enterprise.

-----

**Scope Summary:**

|Platform  |Database Count    |
|----------|------------------|
|MSSQL     |~100 databases    |
|Sybase ASE|~105 databases    |
|**Total** |**~205 databases**|

-----