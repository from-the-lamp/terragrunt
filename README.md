# [Oracle](https://cloud.oracle.com/)

Prepare
---

Get **API** keys:
- Go to Oracle Cloud -> My Profle
- API keys -> Add API key
```
mkdir ~/.oci
touch ~/.oci/config
chmod -R 0600 ~/.oci
```
- Put your **.pem** file to ~/.oci directory
- Put your profile data in ~/.oci/config (change path to **.pem** file)

Get **S3** keys:
- Go to Oracle Cloud -> My Profle
- Customer secret keys -> Generate secret key
- Copy **Secret key** and close window
- Now copy **Access key**
- Add aws_access_key_id and aws_secret_access_key to ~/.oci/config

Exapmle **~/.oci/config**:
```
[prod]
aws_access_key_id=
aws_secret_access_key=
user=
fingerprint=
tenancy=
region=eu-frankfurt-1
key_file=~/.oci/prod.pem
```

Create **.env** file for local usage:

- Just look at **.env.example**
  