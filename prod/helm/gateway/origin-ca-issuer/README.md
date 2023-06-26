[origin-ca-issuer](https://github.com/cloudflare/origin-ca-issuer)

```
kubectl create secret generic \
    --dry-run \
    -n default service-key \
    --from-literal key=v1.0-FFFFFFF-FFFFFFFF -oyaml
```
