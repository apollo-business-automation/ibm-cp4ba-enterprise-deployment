# Local run

When running this guide from local environment

- create variables.yml in root folder and fill it as described in README.md
- add global CA files to scripts/global-ca
- setup tooling or local tooling correctly exposed to PATH
- setup $HOME (for maven and ADS jars to work correctly)

Run whole installation sequence
```bash
ansible-playbook main.yml -e global_action=install
```

Debug particular role
```bash
ansible-playbook debug.yml -e global_action=install -e role_name=cp4ba
```

Run whole remove sequence
```bash
ansible-playbook main.yml -e global_action=remove
```
