# autonomous-security-intelligence

Self-improvement system for an autonomous Web3 security researcher and bug
bounty hunter. The goal is not to collect many tools — it is to find real,
hard-to-find vulnerabilities that other researchers miss, with verified
impact and professional reports.

## Structure

- `/skills/` — new capabilities, each with name, description, function,
  references, usage, implementation example, test case, test results,
  limitations, version + update date.
- `/research/` — research results and skill-discovery reports.
- `/tools/` — tools that were studied and developed.
- `/methodologies/` — security analysis methods.
- `/vulnerability-patterns/` — vulnerability patterns.
- `/test-lab/` — experiments and testing.
- `/knowledge-base/` — knowledge documentation.
- `/benchmarks/` — capability test results (Ethernaut, Damn Vulnerable
  DeFi, Capture The Ether, vulnerable-contract datasets).
- `/changelog/` — skill development history.

## Learning cycle

IDENTIFY → SEARCH → STUDY → PRACTICE → TEST → EVALUATE → IMPROVE →
DOCUMENT → INTEGRATE. A skill is only claimed as mastered after it has
been practiced and tested — never from reading documentation alone.

## Vetting policy

Every skill or tool adopted here must be safe and free (open license,
MIT/Apache), with no secret exfiltration, no destructive commands, no
paid dependencies that cannot be ported, and no hidden scripts. Source
scripts are never adopted — methodology only. Each adoption is verified
before it is declared in use.

## Focus

Logic and business-logic vulnerabilities in DeFi protocols: protocol
architecture mapping, attack surface identification, threat modeling,
novel attack vectors, chained vulnerabilities, economic exploits, oracle
manipulation, accounting and rounding errors — tested with local-EVM PoCs
only, always within program scope and rules.
