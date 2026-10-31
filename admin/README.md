# Admin Super Génial

Gestion interne : clients et contacts, projets, heures prestées en régie, packs d'heures, contrats récurrents
(maintenance, hébergement, noms de domaine, refacturations), frais fixes et factures. Remplace la Google Sheet
« M&V / Abonnements ». Les factures restent émises dans OkiOki : l'admin dit quoi facturer et quand, et garde
le n° OkiOki.

Rails 8.1, SQLite (+ Solid Cache/Queue/Cable), Hotwire, propshaft, sans build JS.

## En local

```
cd admin
bin/setup --skip-server
bin/rails users:create EMAIL=toi@exemple.be PASSWORD=…
bin/dev
```

## Reprendre la Google Sheet

Le repo est public : aucune donnée client n'y est versionnée, l'import les lit à l'exécution.

- Sheet partagée « tous les utilisateurs disposant du lien » : `bin/rails import:sheet SHEET_ID=14z7…`
- Sinon, exporter chaque onglet en CSV (`Prestations.csv`, `Revenus.csv`, `Outils M&V.csv`, `Noms de domaine.csv`,
  `Refacturations.csv`) dans un dossier : `bin/rails import:sheet DIR=chemin/du/dossier`

L'import est idempotent (le relancer met à jour sans dupliquer) et affiche ce qu'il faut vérifier : clients déduits
d'un libellé, montants sans statut, packs sans taux. Les factures importées sont datées au 1er janvier, sans n° OkiOki.

## Déploiement (Coolify, VPS Semisto)

Nouvelle application dans Coolify, à côté du site statique :

- Source : ce repo, branche `main`, **Base directory `/admin`**, build pack Dockerfile
- Domaine : `https://admin.supergenial.be` (port 80 du conteneur)
- Volume persistant : `/rails/storage` (les bases SQLite ; c'est le seul dossier à sauvegarder)
- Variables : `SECRET_KEY_BASE` (générer avec `bin/rails secret`), optionnellement `ANNUAL_TARGET` (défaut 30000)
- Health check : `/up`

La base est créée et migrée au démarrage du conteneur. Créer ensuite le compte depuis le terminal Coolify :
`bin/rails users:create EMAIL=… PASSWORD=…`, puis lancer l'import.

### Accès et sécurité

- Double authentification (TOTP) obligatoire : configurée à la première connexion. Téléphone perdu :
  `bin/rails users:reset_two_factor EMAIL=…` dans le terminal Coolify.
- Rôles : `admin` (tout) et `accountant` (lit tout, commente, valide les catégories de dépenses, confirme les paramètres fiscaux, clôture la TVA). Les comptes se gèrent
  dans « Comptes », ou `bin/rails users:create EMAIL=… PASSWORD=… ROLE=accountant NAME=…`.
- Sessions valables 30 jours. Chaque modification est écrite dans le journal (`AuditEvent`), avec son auteur.
- Les secrets 2FA sont chiffrés (Active Record encryption, clés dérivées de `SECRET_KEY_BASE`, ou
  `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `…_DETERMINISTIC_KEY`, `…_KEY_DERIVATION_SALT` si définies). Changer
  `SECRET_KEY_BASE` oblige à réinitialiser la 2FA de chaque compte.

### Facturation et Peppol (Recommand)

Les factures et notes de crédit sont créées en brouillon (depuis les heures, un contrat ou « + Facture »), puis
**émises** : numéro de la série annuelle `AAAA-NNN` (partagée avec les notes de crédit, suite du dernier numéro OkiOki
saisi dans « Société »), communication structurée, plus aucune modification possible. L'envoi passe par l'API
Recommand : Peppol si le client y est joignable, e-mail sinon, jamais d'e-mail pour une entreprise belge.
L'UBL renvoyé par Recommand est archivé avec la facture ; le PDF (polices Liberation Sans, `vendor/fonts`) est joint
au document Peppol. Variables **runtime** : `RECOMMAND_API_KEY`, `RECOMMAND_API_SECRET`, `RECOMMAND_COMPANY_ID`
(clés de l'équipe « playground » pour tester), `RECOMMAND_BASE_URL` (optionnelle).

### Reprise de l'historique (OkiOki, Harvest)

Page « Comptes » → « Reprise de l'historique » (admins). OkiOki : envoyer de préférence l'archive ZIP complète
(`OkiokiArchiveImport`, en arrière-plan, le ZIP reste joint à l'import) : ventes UBL par numéro, avec leur PDF et
leur UBL ; achats UBL par identifiant OkiOki (source « Reprise OkiOki »), avec PDF, fournisseurs créés au besoin,
date de paiement et taux de change tirés des `transactions.xlsx` mensuels (taux moyen du mois si aucun paiement
n'est lié). Les achats datés d'avant « TVA suivie depuis » arrivent comptabilisés (déjà passés par la comptable, la
catégorie n'est pas exigée), les suivants « à vérifier ». Les extraits de compte rangés comme documents
(`<IBAN>_<date>_<n°>`) et les PDF sans UBL sont ignorés. Relancé, l'import garde les corrections faites sur les
achats. Le CSV de la liste des factures reste accepté (colonnes reconnues par leur en-tête). Dans les deux cas, les
références sans numéro reprises de la Google Sheet sont remplacées, et le dernier numéro de l'année devient le point
de départ de la numérotation. Harvest : variables **runtime** `HARVEST_ACCESS_TOKEN` et
`HARVEST_ACCOUNT_ID` ; clients, factures et, jusqu'à une date choisie, les heures (les heures jamais facturées
passent en « offert »). Chaque import peut d'abord tourner en simulation ; relancé, il met à jour sans dupliquer.

### Achats (Peppol, boîte e-mail, Claude)

Toutes les 30 minutes (ou « Relever Peppol et e-mails » dans « Achats »), `PurchaseInboxJob` relève :

- les documents reçus sur Peppol dans Recommand (mêmes variables que la facturation) : UBL archivé (l'original
  légal), PDF joint, fournisseur créé s'il est nouveau, puis marqués comme lus ;
- les PDF joints aux e-mails de la boîte achats, par l'API Gmail (scope `gmail.modify`) : variables **runtime**
  `GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET`, `GMAIL_REFRESH_TOKEN`, `GMAIL_USER` (défaut `sg-invoices@semisto.org`).
  Les messages traités reçoivent le libellé `admin-importee`.

Chaque PDF (e-mail ou ajout manuel) est lu par Claude Haiku (`claude-haiku-5-5`, variable **runtime**
`ANTHROPIC_API_KEY`) : fournisseur, numéro, dates, montants, autoliquidation. Les champs ne font que préremplir
l'achat : il reste « à vérifier » jusqu'à ce qu'on le comptabilise. Un fournisseur belge qui envoie encore par
e-mail apparaît dans « Exiger Peppol ». Les documents sont servis par l'admin, derrière la connexion (pas d'URL
publique Active Storage). « Dépendances » montre les achats par zone (pays du groupe) et la part des États-Unis
par trimestre ; le tableau de bord signale les factures mensuelles attendues d'un frais fixe et pas reçues.

### Banque (CODA Belfius)

« Banque » → « Extraits et import CODA » : envoyer le fichier CODA téléchargé de Belfius Web. Chaque extrait est
contrôlé (solde initial + mouvements = solde final), gardé avec son fichier d'origine pour la comptable, et ses
mouvements sont rapprochés automatiquement quand c'est sûr : communication structurée d'une facture de vente, ou
montant exact avec le numéro de facture (ou l'IBAN du fournisseur) pour un achat. Le reste se rapproche à la main
parmi les pièces non payées les plus proches, ou se classe « sans pièce » (rémunération, impôts, TVA, frais
bancaires, transfert…). Rapprocher une pièce la marque payée à la date du mouvement.

### TVA trimestrielle et pack comptable

« TVA » calcule chaque trimestre depuis la date « TVA suivie depuis » (« Société ») : grilles de la déclaration
périodique (ventes 00-03, 44, 47, 48/49, 54, 64 ; achats 81-83, 84-88, 55/56, 59, 63 ; solde 71/72), listing
intracommunautaire et contrôles (achats à vérifier et client intracom sans n° de TVA bloquent la clôture).
Téléchargements : XML Intervat (`VATConsignment`), listing (`IntraConsignment`) et un zip pour la comptable (UBL et
PDF des ventes et achats, fichiers CODA, grilles et achats en CSV). La comptable dépose la déclaration dans Intervat
puis **clôture** le trimestre (son seul droit d'écriture) : les pièces déclarées ne changent plus, une pièce
arrivée en retard tombe dans le trimestre ouvert suivant. Les trimestres se clôturent dans l'ordre et ne se
rouvrent pas.

### Pilotage fiscal

« Pilotage » estime, pour l'année, le bénéfice imposable (factures, contrats et heures à venir, achats pour leur part
déductible, frais fixes jusqu'au 31 décembre, rémunération versée et prévue, cotisations sociales, PLCI), l'impôt des
sociétés (taux réduit si la rémunération du gérant atteint 45 000 € ou le bénéfice), les versements anticipés
conseillés et ceux déjà payés (mouvements bancaires classés « Impôts »). Dès novembre, le tableau de bord signale la
rémunération à verser avant le 31 décembre pour garder le taux réduit. Les taux et plafonds sont des
« Paramètres fiscaux » datés et sourcés, que la comptable confirme ; les valeurs de départ (2026) sont à vérifier.
C'est une estimation à discuter avec la comptable, pas une déclaration.

### Sauvegardes hors site

Chaque nuit à 3 h (Solid Queue dans Puma : `SOLID_QUEUE_IN_PUMA=true`), `BackupJob` envoie la base et les fichiers,
chiffrés (AES-256-GCM), vers un bucket S3 compatible (Infomaniak Swiss Backup). Variables **runtime** :
`BACKUP_S3_ENDPOINT`, `BACKUP_S3_BUCKET`, `BACKUP_S3_ACCESS_KEY_ID`, `BACKUP_S3_SECRET_ACCESS_KEY`, `BACKUP_S3_REGION`
(optionnelle), `BACKUP_ENCRYPTION_KEY` (phrase secrète, à garder aussi hors du VPS), `BACKUP_RETENTION_DAYS` (défaut 90).
Sans ces variables, la sauvegarde est sautée (avertissement dans les logs). Lancer à la main : `bin/rails backups:run` ;
restaurer : télécharger le fichier, `bin/rails backups:decrypt FILE=… BACKUP_ENCRYPTION_KEY=…`, puis `tar xzf`.

## Modèle

| Modèle | Rôle |
| --- | --- |
| `Client` | Organisation ou particulier, taux horaire par défaut (80 €) |
| `Contact` | Personnes d'un client, un contact principal |
| `Project` | Forfait, régie ou pack ; taux horaire propre possible |
| `TimeEntry` | Heures prestées : à facturer, facturé, imputé au pack, offert |
| `Pack` | Heures prépayées, solde calculé |
| `Contract` | Récurrent : prix, coût, périodicité, prochaine échéance ; « Facturé » crée la facture et avance l'échéance |
| `FixedCost` | Frais de Super Génial, actuel et prévisionnel (vide = inchangé, 0 = supprimé) |
| `Invoice` | Facture ou note de crédit : brouillon puis émise (immuable), lignes, TVA, envoi Peppol ; ou référence d'un document OkiOki / Harvest |
| `InvoiceLine` | Ligne : quantité, unité, prix HTVA, taux de TVA, période |
| `CompanyProfile` | Le vendeur (Marco & Vespucci SRL) : identité, compte, délai de paiement, dernier n° OkiOki |
| `Dashboard` | Les totaux de l'ancien onglet « Revenus » |
| `Supplier` | Fournisseur : pays de facturation et pays du groupe (zone BE / UE / US / autres), Peppol attendu |
| `PurchaseInvoice` | Facture ou note de crédit d'achat : Peppol, e-mail ou manuel, régime de TVA (autoliquidation, grilles), à vérifier puis comptabilisée |
| `SupplierDependence` | Achats par zone et part des États-Unis |
| `BankStatement` | Extrait bancaire importé d'un fichier CODA, avec ses soldes et le fichier d'origine |
| `BankTransaction` | Mouvement bancaire, rapproché d'une facture de vente ou d'achat, ou classé sans pièce |
| `VatReturn` | Déclaration TVA d'un trimestre : grilles, listing intracom, contrôles, clôture |
| `VatPeriod` | Trimestre clôturé : grilles déclarées figées, pièces rattachées |
| `TaxProjection` | Estimation du bénéfice, de l'ISOC, des versements anticipés et de la rémunération à verser |
| `TaxParameter` | Taux ou plafond fiscal daté et sourcé, confirmé par la comptable |
| `FiscalPlan` | Rémunération mensuelle, versement de fin d'année et PLCI prévus pour une année |
| `ExpenseCategory` | Catégorie d'achat et traitement comptable proposé (compte PCMN, TVA, déductibilité ISOC), validé par la comptable |
| `User` | Compte : rôle admin ou comptable, 2FA |
| `Comment` | Commentaire sur une fiche (client, contrat, fournisseur…), surtout pour la comptable |
| `AuditEvent` | Journal append-only de chaque création, modification et suppression |
