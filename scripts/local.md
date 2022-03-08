# Local run

When running this guide from local environemnt

- create variables.yml in root folder and fill it as described in README.md
- add global CA files to scripts/globla-ca
- setup tooling or local tooling correctly exposed to PATH
- setup $HOME (for maven and ADS jars to work correctly)

Run whole install sequence
```bash
ansible-playbook main.yml -e global_action=install
```

Run particular role install
```bash
ansible localhost -m import_role \
-a "name=catalog-source" \
-e "@variables.yml" \
-e "@internal-variables.yml" \
-e global_action=install
```

Run whole remove sequnce
```bash
ansible-playbook main.yml -e global_action=remove
```

Run particular role remove
```bash
ansible localhost -m import_role \
-a "name=catalog-source" \
-e "@variables.yml" \
-e "@internal-variables.yml" \
-e global_action=remove
```                  
