# Lettre Super Génial : template Listmonk

- `listmonk-template.html` : à coller dans Listmonk (Campagnes → Modèles → Nouveau, type « Campagne »). Fichier compilé, ne pas éditer à la main.
- `listmonk-template.mjml` : la source. Après modification : `bunx mjml newsletter/listmonk-template.mjml -o newsletter/listmonk-template.html --config.minify=true --config.validationLevel=strict`
- `exemple-contenu.html` : exemple de corps de campagne (éditeur « HTML brut » ou « Rich text »).

Dans le corps d'une campagne, ces éléments sont stylés par le template : `h1`, `h2`, `h3`, `p`, listes, liens, `blockquote` (citation en italique), `hr`, images, `<p class="kicker">` (sur-titre mauve) et `<a class="button">` (bouton mauve).

Variables Listmonk utilisées : `{{ template "content" . }}`, `{{ .Campaign.Subject }}`, `{{ MessageURL }}`, `{{ UnsubscribeURL }}`, `{{ ManageURL }}`, `{{ TrackView }}`. Prénom dans une campagne : `{{ .Subscriber.FirstName }}`.

Les images (avatar, portrait) sont servies depuis `https://www.supergenial.be/assets/email/`.
