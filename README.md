# [Oracle](https://cloud.oracle.com/)

Prepare
---

Get API keys:
- Go to **Oracle Cloud** -> **My Profle**
- **API keys** -> **Add API key**
```
mkdir ~/.oci
touch ~/.oci/config
chmod -R 0600 ~/.oci
```
- Put your **.pem** file to ~/.oci directory
- Put your profile data in ~/.oci/config (change path to **.pem** file)

Exapmle **~/.oci/config**:
```
[lamp-infra]
user=
fingerprint=
tenancy=
key_file=
compartment_ocid=
region=
```

Create **.env** file for local usage:

- Just look at **.env.example**

Run
---
Install [Taskfile](https://taskfile.dev)

```
DIR=infra/oracle/k3s task apply
etc...
```