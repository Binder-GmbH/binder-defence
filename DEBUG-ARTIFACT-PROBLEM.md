# ARTIFACT PROBLEM - DEBUG NOTES

## Problem
Der GitHub Actions Artifact enthält NICHT den vollständigen `vendor/` Ordner, obwohl `composer install` erfolgreich läuft.

## Beweis (Screenshots)
Der heruntergeladene Artifact zeigt:
- `vendor/` Ordner existiert
- Aber `vendor/` enthält NUR leere Unterordner (bacon/, bin/, christian-riesen/, etc.)
- KEINE actual PHP files in vendor/
- Total nur 34 MB statt erwartet 100+ MB

## Workflow aktuell:

### Compile Job (Zeile 13-40):
```yaml
- name: Checkout code
  uses: actions/checkout@v4

- name: Install Composer dependencies
  run: |
    cd source
    composer install --no-dev --optimize-autoloader --no-progress --no-interaction --ignore-platform-reqs

- name: Upload compiled source
  uses: actions/upload-artifact@v4
  with:
    name: compiled-source
    path: |
      source/
      !source/var
      !source/public/fileadmin
      !source/public/typo3temp
    retention-days: 1
```

## Hypothesen:

### Hypothese 1: Upload-Pfad ist falsch
- `cd source` macht working directory = source/
- Aber Upload `path: source/` sucht nach `source/source/`
- **Test:** Upload-Pfad auf `.` ändern wenn in source/ directory

### Hypothese 2: .gitignore excludiert vendor/
- GitHub Actions respektiert möglicherweise .gitignore beim Artifact-Upload
- **Test:** Checke ob `source/.gitignore` vendor/ excludiert

### Hypothese 3: Composer installiert nicht richtig
- Composer schreibt in falsches Verzeichnis
- **Test:** Füge `ls -la source/vendor/` nach composer install hinzu

## Nächste Schritte:

1. **ERST:** Debug Output NACH composer install hinzufügen:
   ```yaml
   - name: Debug after composer install
     run: |
       echo "=== PWD ==="
       pwd
       echo "=== source/ contents ==="
       ls -la source/
       echo "=== source/vendor/ size ==="
       du -sh source/vendor/
       echo "=== source/vendor/ first 20 items ==="
       ls -la source/vendor/ | head -20
   ```

2. **DANN:** Je nach Output, Upload-Pfad anpassen

3. **ZULETZT:** Build Job kann bleiben wie er ist (mit path: .)

## Status: ROOT CAUSE GEFUNDEN UND GEFIXT!

### Root Cause
`.dockerignore` enthielt `source/vendor`, was bedeutet dass `COPY ./source /app/source` im Dockerfile den vendor/ Ordner NICHT kopiert hat!

### Lösung
`source/vendor` aus `.dockerignore` entfernt.

### Warum war das Problem so verwirrend?
- Artifact Upload/Download hat PERFEKT funktioniert (121M, alle Files)
- Das Problem war beim Docker Build: `COPY ./source /app/source` hat vendor/ ignoriert wegen .dockerignore
- Deshalb war im fertigen Image kein vendor/ vorhanden

### Fix 1: .dockerignore
Entfernt `source/vendor` aus `.dockerignore` damit der vendor/ Ordner im Production-Image landen KÖNNTE.

### ABER WAIT: ZWEITER ROOT CAUSE!

Nach dem Fix war vendor/ IMMER NOCH nicht im Artifact! Warum?

**Root Cause 2**: `upload-artifact@v4` respektiert standardmäßig `.gitignore`!
Und `.gitignore` enthält `source/vendor/`.

### Fix 2 (fehlgeschlagen): include-hidden-files
Versuch: `include-hidden-files: true` hinzugefügt.
Resultat: HAT NICHT FUNKTIONIERT! Artifact immer noch nur 33.3MB.
`upload-artifact@v4` respektiert `.gitignore` TROTZDEM.

### DRITTER ROOT CAUSE & FINALE LÖSUNG!

**Root Cause 3**: Es gibt KEINEN einfachen Weg, `upload-artifact@v4` zu zwingen, `.gitignore` zu ignorieren.

**Finale Lösung**: Vendor/ als SEPARATES Artifact uploaden!
- Artifact 1: "source-code" mit `!source/vendor` exclude
- Artifact 2: "vendor" mit path: `source/vendor/`
- Im Build Job: Beide artifacts downloaden und zusammenfügen

Da vendor/ explizit als PATH angegeben wird (nicht in einem parent directory das .gitignore hat), wird es NICHT von .gitignore Regeln betroffen!

### FIX 3 FEHLGESCHLAGEN! Root Cause 4!

Auch mit separatem Artifact war vendor/ NUR 28.8 MB statt 121 MB!
Warum? Weil `upload-artifact@v4` checkt .gitignore relativ zum REPO ROOT!

Wenn ich `path: source/vendor/` angebe, prüft GitHub Actions:
1. Ist `source/vendor/` in `.gitignore`? → JA!
2. → Skip upload!

**FINALE LÖSUNG (wirklich diesmal)**: TAR-Archive verwenden!
- Erstelle TAR von vendor/: `tar -czf /tmp/vendor.tar.gz -C source vendor/`
- Upload das TAR (liegt in /tmp/, nicht in source/)
- Download TAR
- Extract TAR: `tar -xzf /tmp/vendor.tar.gz -C source/`

TAR liegt außerhalb vom repo → .gitignore greift NICHT!
