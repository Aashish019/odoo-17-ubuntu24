### module update
'''
./odoo-bin -c odoo.conf -d Reliant_Rentalz_test -u mcm_sale_purchase_custom --stop-after-init
'''
./odoo-bin -c odoo.conf -d Reliant_Rentalz_test -u all --stop-after-init

### zatca remove 
sudo -u postgres psql -d mdt_main_17-4 -c "UPDATE res_users SET password = '123' WHERE login = 'administrator'; UPDATE res_company SET l10n_sa_api_mode = 'sandbox';"
sudo -u postgres psql -d mdt_main_17-4 -c "UPDATE res_users SET password = '123' WHERE login = 'administrator'; UPDATE res_company SET l10n_sa_api_mode = 'preprod';"

### pg dump

pg_dump -U odoo17 -h localhost -p 5432 -Fc Reliant_Rentalz_test > test.dump

pg_dump -U $DB_USER -h localhost -F c -b -v -f "$BACKUP_NAME.sql" $DB_NAME

docker exec -it docker-db-1 pg_dump -U odoo -d boards.mcmillan.solutions -F p > odoo_backup.sql

On normal 
Switch to postgres
pg_dump -d mdt_logistics -F p > odoo_backup.sql


Copy sql
scp sahad@192.168.29.13:/home/sahad/deployment/odoo-17/config/docker/odoo_backup.sql ./

