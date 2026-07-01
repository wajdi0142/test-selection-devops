# Journal IA

## Prompt 1 — Génération du docker-compose.yml initial
**Prompt :** "Génère un docker-compose.yml pour Odoo 17 + PostgreSQL 15, avec PostgreSQL isolé dans un réseau privé non exposé, secrets dans .env, et Nginx en reverse proxy."

**Ce que l'IA a généré :** un compose avec 3 services (db, odoo, nginx), deux réseaux (backend en `internal: true`, frontend), volumes nommés `postgres-data` et `odoo-filestore`, healthcheck sur `db`.

**Ce que j'ai modifié :** rien sur la structure du compose, mais j'ai dû corriger le fichier `nginx/odoo.conf` généré initialement — il contenait un bloc `/longpolling` pointant vers `odoo:8072`, ce qui provoquait une erreur Nginx (`upstream "odoo" may not have port 8072`, un upstream ne peut avoir qu'un seul port fixe). J'ai supprimé ce bloc, non nécessaire pour ce test.

**Pourquoi :** sans cette correction, le conteneur `odoo-nginx` redémarrait en boucle (`Restarting`) et empêchait l'accès à `http://erp.local`.

## Prompt 2 — Script de sauvegarde Bash
**Prompt :** "Écris un script Bash de sauvegarde Odoo : pg_dump via docker exec sans arrêter les conteneurs, archive tar.gz horodatée du filestore, logs dans /var/log/backup.log."

**Ce que l'IA a généré :** un script combinant `pg_dump` avec `docker exec`, un conteneur `alpine` temporaire pour archiver le volume `odoo-filestore` (car un volume Docker n'est pas accessible directement depuis l'hôte), et une fonction `log()` avec horodatage.

**Ce que j'ai modifié :** rien sur la logique du script — testé tel quel et fonctionnel du premier coup (`bash -n` valide, archive de 7.6 Mo générée avec `db.sql` + `filestore.tar.gz` dedans). J'ai juste dû créer manuellement `/backup` et `/var/log/backup.log` avec les bonnes permissions (`sudo chown`) avant la première exécution.

**Pourquoi :** ces chemins système n'existaient pas par défaut sous WSL2 et nécessitaient une préparation en amont.

## Prompt 3 — Débogage de l'environnement WSL2/Docker Desktop
**Prompt :** "Docker fonctionne dans Windows mais pas dans WSL2, erreur 'permission denied while trying to connect to the docker API'."

**Ce que l'IA a proposé :** vérifier l'intégration WSL dans Docker Desktop (Settings → Resources → WSL Integration), ajouter l'utilisateur au groupe `docker`, puis en cas d'échec persistant (erreur `E_UNEXPECTED` sur `~/.docker/config.json`), faire un `wsl --shutdown` suivi d'un redémarrage complet de Windows.

**Ce que j'ai fait :** suivi la procédure pas à pas — le simple redémarrage de l'intégration WSL n'a pas suffi, il a fallu un reboot Windows complet pour que Docker Desktop réinitialise proprement sa configuration.

**Pourquoi :** l'environnement de test exigeait Ubuntu/WSL2 + Docker Compose v2, alors que ma machine tournait initialement en PowerShell/cmd.exe classique — la mise en place de l'environnement a pris plus de temps que prévu (~30-45 min), d'où l'importance du conseil de préparer l'environnement la veille.

## Apprentissage du jour
La restauration d'un volume Docker après un `docker compose down -v` nécessite un conteneur intermédiaire (ex. `alpine`) pour lire/écrire dans le volume, car il n'est pas monté directement sur le filesystem hôte. J'ai aussi appris que relancer un script de restauration SQL sur une base déjà peuplée produit de nombreuses erreurs "already exists" — normales et sans gravité, mais qu'il faut savoir distinguer d'une vraie erreur de restauration.
