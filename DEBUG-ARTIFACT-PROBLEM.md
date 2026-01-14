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

## Status: WARTEN AUF DEBUG OUTPUT VOM NÄCHSTEN RUN
