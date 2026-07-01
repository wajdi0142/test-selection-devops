# Procédure de restauration — Stack Odoo

## Prérequis
- Une archive `backup_YYYYMMDD_HHMMSS.tar.gz` disponible dans `/backup/`.
- Fichier `.env` présent dans `apps/`.

## Étapes

### 1. Sauvegarder avant le crash (si pas déjà fait)
```bash
cd apps
sudo ./backup.sh
```

### 2. Simuler la perte totale (conteneurs + volumes)
```bash
docker compose down -v
docker volume ls
```
Les volumes `postgres-data` et `odoo-filestore` doivent avoir disparu de la liste.

### 3. Extraire l'archive de sauvegarde
```bash
mkdir -p /tmp/restore
tar xzf /backup/backup_YYYYMMDD_HHMMSS.tar.gz -C /tmp/restore
# Produit : /tmp/restore/db.sql et /tmp/restore/filestore.tar.gz
```

### 4. Recréer la stack (service db uniquement, volume vide)
```bash
docker compose up -d db
docker compose ps
```
Attendre que `odoo-db` soit `healthy`.

### 5. Restaurer la base PostgreSQL
```bash
set -a
source .env
set +a
docker exec -i odoo-db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < /tmp/restore/db.sql
```

Vérifier que la restauration a fonctionné :
```bash
docker exec -i odoo-db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT name, state FROM ir_module_module WHERE name='sale';"
```
Le `state` doit afficher `installed`.

### 6. Restaurer le filestore Odoo
```bash
docker run --rm \
  -v odoo-filestore:/data \
  -v /tmp/restore:/backup_tmp \
  alpine \
  sh -c "tar xzf /backup_tmp/filestore.tar.gz -C /data"
```

### 7. Démarrer le reste de la stack
```bash
docker compose up -d
docker compose ps
```
Les 3 services (`odoo-db`, `odoo-app`, `odoo-nginx`) doivent être `Up`.

### 8. Vérification finale
- Ouvrir `http://erp.local` (ou `http://localhost:8069`).
- Se connecter à Odoo (`admin` / mot de passe défini à la création).
- Vérifier que le module **Ventes** est toujours installé et que les données sont intactes.

## Nettoyage
```bash
rm -rf /tmp/restore
```

## Scénario de validation (crash test) — réalisé le 01/07/2026
1. `./apps/backup.sh` → archive `backup_20260701_045045.tar.gz` créée (7.6 Mo)
2. `docker compose down -v` → conteneurs et volumes supprimés, confirmé par `docker volume ls`
3. Suivi des étapes 3 à 7 ci-dessus
4. Odoo opérationnel via `http://erp.local`, module Ventes toujours "Installed", 7 utilisateurs restaurés dans `res_users`
