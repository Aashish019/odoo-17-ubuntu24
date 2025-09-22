### Addon Path finder

```
find /opt/odoo17/extra-addons -type f -name '__manifest__.py' -exec dirname {} \; | xargs -n1 dirname | sort -u | paste -sd,
```
Find out which path to set in odoo.conf
