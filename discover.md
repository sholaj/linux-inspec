ROLE
Diagnose why VMs on three CUDN localnet networks are unreachable north-south on
this OpenShift 4.20 cluster, and classify each VLAN's fault as either OUR CUDN
misconfiguration (we fix) or a PLATFORM/FABRIC trunk gap (they fix). This is a
READ-ONLY investigation. Produce a report and a sanitised escalation draft.

SAFETY — non-negotiable
- Do NOT apply, patch, create, or delete any cluster object or file. No `oc apply`,
  `edit`, `delete`, `scale`, `label`, `annotate`. Investigation commands only
  (get, describe, logs, rsh/exec read commands, debug node read commands).
- If any step would mutate state, STOP and ask.
- If you encounter a bearer token, kubeconfig secret, or private key in any file
  or command output, do NOT echo or copy it. Flag it once: "credential found —
  rotate" and move on.
- Never write real FQDNs, IPs, VLAN IDs, base domains, or tokens into any file
  under version control, or into the report body. Real values live ONLY in
  ./.scratch/ (create it, confirm it is gitignored). Everything repo-facing uses
  placeholders (VLAN 100/101/102, 10.100-102.0.0/24, node-x, physnet).

CONTEXT
Load the repo instructions and docs/demos/multi-network-policy/ (the NAD/CUDN
model, FLOW.html, and copilot-instructions.md). Three ClusterUserDefinedNetworks,
topology Localnet, physicalNetworkName vlans. Known so far: MultiNetworkPolicy is
ruled out (baseline-allowed flows fail identically). One VLAN's VMs ARP their
gateway successfully; the other two fail ARP outbound. That working VLAN is the
CONTROL: same node, same physnet, same CUDN template — so a fault present on it
is systemic, and a fault absent on it is per-VLAN.

INPUTS (fill from the live environment; store in ./.scratch/env only)
  NODE            = <vm hosting node>
  UPLINK          = <bond/uplink iface on the node>
  CONTROL_VLAN    = <the VLAN whose VM ARPs fine>       # e.g. 204
  BROKEN_VLANS    = <the two that fail ARP>             # e.g. 203, 205
  For each VLAN:  id, subnet/mask, gateway, namespace, cudn-name, a VM name
  ACCESS          = ./access/ssh.sh <vm> -- '<cmd>'     # existing port-forward helper

METHOD — run in order, per VLAN, comparing every result against CONTROL_VLAN

Phase 0 — preflight
- Confirm the three CUDN objects exist and each rendered a NAD into its namespace:
  oc get clusteruserdefinednetwork; oc get net-attach-def -A | grep <cudn-names>.
  A missing rendered NAD is itself a finding.

Phase 1 — config truth (is it OURS?)
- For each VLAN: oc get clusteruserdefinednetwork <name> -o yaml and
  oc get net-attach-def -n <ns> <cudn-name> -o yaml. Extract subnets, the localnet
  vlan id, and physicalNetworkName. Compare EXACTLY to the fabric inputs.
- Any mismatch (wrong subnet, wrong mask, wrong vlan id, wrong physnet) →
  classify VLAN as CUDN CONFIG ERROR (ours) and note the one-line fix. Do not
  proceed to escalate that VLAN.

Phase 2 — VM L3 reality
- ACCESS <vm> 'ip -br a show eth1; ip route; ip neigh show dev eth1'.
- Confirm the VM's eth1 IP is inside the gateway's subnet at the correct mask. An
  off-subnet IP (e.g. /24 vs /25) is a CUDN CONFIG ERROR surfacing at the guest.

Phase 3 — L2 delivery (is it OURS or the TRUNK?)
- ACCESS <vm> 'ip neigh flush dev eth1; arping -c3 -I eth1 <gw>'.
- In parallel, capture on the node uplink (read-only, time-boxed):
  oc debug node/<NODE> -- chroot /host timeout 8 tcpdump -nne -i <UPLINK> vlan <id> and arp
- Classify:
    ARP leaves, correctly tagged, no reply  → TRUNK/FABRIC GAP (platform)
    ARP does not leave, or wrong/no tag      → node OVN/OVS (ours-adjacent) → Phase 4
    ARP leaves and IS answered               → L2 fine; if ping/TCP still fails, treat like CONTROL_VLAN (Phase 5)

Phase 4 — node OVN/OVS plumbing (only if Phase 3 says node-side)
- oc debug node/<NODE> -- chroot /host ovs-vsctl get Open_vSwitch . external_ids:ovn-bridge-mappings
    → is `vlans` mapped to a bridge?
- oc debug node/<NODE> -- chroot /host ovs-vsctl show
    → does that bridge have <UPLINK> as a physical port?
- oc debug node/<NODE> -- chroot /host ovs-vsctl list port <UPLINK>
    → is it a trunk (no access tag) carrying the VLAN?
- Best-effort OVN logical check via the ovnkube-node pod on this node
  (oc -n openshift-ovn-kubernetes get pods -o wide; rsh; ovn-nbctl show) to confirm
  the localnet LSP tag == vlan id and options:network_name == vlans. If RBAC denies,
  mark "requires platform" — do not guess.
- KEY COMPARISON: run these for CONTROL_VLAN too. If node-side config is identical
  across all three and only CONTROL works, the delta is upstream (trunk allowed-VLAN
  list), NOT the node → TRUNK/FABRIC GAP.

Phase 5 — CONTROL_VLAN / any "ARP-fine-but-no-ping" VLAN
- Do NOT trust ICMP as the test. From a same-VLAN pod: nc -vz <vm> 22 and nc -vz <vm> 8080.
    TCP passes → the ICMP failure is COSMETIC; downgrade severity, do not escalate an ICMP ACL.
    TCP fails  → not ICMP-specific; investigate return path / upstream, then escalate.
- Also ACCESS <vm> 'sudo firewall-cmd --list-all' — rule out guest firewalld dropping ICMP.

VERDICT — classify each VLAN into exactly one:
  A. CUDN CONFIG ERROR (ours)      — Phase 1/2 mismatch; state the exact fix.
  B. TRUNK/FABRIC GAP (platform)   — ARP leaves tagged + unanswered; node identical to control.
  C. ICMP-ONLY / COSMETIC          — ARP+TCP fine, only ping fails.
  D. NEEDS PLATFORM (RBAC-blocked) — could not read node/OVN; list what you need run.

REPORT
1. Per-VLAN table: symptom | Phase 1 config match? | Phase 3 L2 result | verdict | owner.
2. One explicit line: "CUDN config proven clean" OR "CUDN config error found on <vlan>: <fix>".
3. Evidence appendix, sanitised (placeholders only), including the tagged-ARP capture summary.
4. A sanitised escalation draft, SPLIT BY OWNER:
     - Network team: trunk allowed-VLAN list on the port-channel to node-x — confirm all three ids; attach the tagged-ARP captures.
     - Platform: ovn-bridge-mappings / ovs-vsctl show / localnet LSP tags for all three.
   Do not bundle the broken VLANs and the cosmetic one into a single "VLAN plane broken" ask.

DO NOT
- Escalate the ICMP-only VLAN before Phase 5 TCP + firewalld are done.
- Merge distinct faults into one ticket.
- Emit any real hostname, IP, VLAN id, domain, or token in the report or any tracked file.
