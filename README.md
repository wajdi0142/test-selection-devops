# Test DevOps — Stack Odoo conteneurisée

Déploiement Odoo 17 + PostgreSQL 15 derrière un reverse proxy Nginx, avec sauvegarde et restauration automatisées.

## Prérequis

- Ubuntu 20.04+ / WSL2
- Docker Engine v24+
- Docker Compose v2+
- Git v2+
- 4 Go RAM / 5 Go disque libres

## Démarrage rapide (5 commandes)

```bash
git clone https://github.com/wajdi0142/test-selection-devops.git
cd test-selection-devops/apps
cp .env.example .env        # éditer POSTGRES_PASSWORD avec un vrai mot de passe
echo "127.0.0.1 erp.local" | sudo tee -a /etc/hosts
docker compose up -d
```

Accès :
- Odoo via reverse proxy : http://erp.local
- Odoo direct : http://localhost:8069

Identifiants par défaut après création de base : `admin` / mot de passe défini à la création.

## Arborescence
apps/
├── docker-compose.yml
├── .env.example
├── backup.sh
└── nginx/odoo.conf
docs/
├── restauration.md
└── journal-ia.md
README.md
.gitignore
## Sauvegarde

```bash
cd apps
sudo ./backup.sh
```

Crée une archive `backup_YYYYMMDD_HHMMSS.tar.gz` dans `/backup/` (dump PostgreSQL + filestore Odoo), sans arrêter les conteneurs. Logs dans `/var/log/backup.log`.

Planification automatique (chaque nuit à 02h00) :
```bash
crontab -e
# ajouter :
0 2 * * * /chemin/absolu/vers/apps/backup.sh >> /var/log/backup.log 2>&1
```

## Restauration après perte totale

```bash
docker compose down -v   # supprime conteneurs ET volumes
```

Procédure complète détaillée dans [docs/restauration.md](docs/restauration.md) :
1. Extraire l'archive de backup
2. Recréer la stack (`db` uniquement)
3. Restaurer le dump PostgreSQL via `psql`
4. Restaurer le filestore Odoo via un conteneur `alpine` temporaire
5. Démarrer le reste de la stack (`docker compose up -d`)
6. Vérifier qu'Odoo fonctionne et que les données sont intactes

## Sécurité

- Aucun secret commité : `.env` est dans `.gitignore`, seul `.env.example` est versionné.
- PostgreSQL n'est joignable que depuis le réseau Docker interne (`backend`, `internal: true`), aucun port publié sur l'hôte.

## Documentation

- [docs/restauration.md](docs/restauration.md) — runbook de restauration (PRA)
- [docs/journal-ia.md](docs/journal-ia.md) — journal d'utilisation de l'IA
