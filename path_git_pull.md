### For git Pull on the given path

```
find /opt/odoo17/extra-addons -type d -name ".git" -exec dirname {} \; | xargs -I{} git -C {} pull
```
### Note:
change the path to your choice
