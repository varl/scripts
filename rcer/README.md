# RCer

Builds RC artifacts of the core webapps currently bundled with the DHIS2
software WAR-file.

## Deps

* Maven
* Git
* NodeJS
* Bash

## Rights

* Sonatype to org.hisp
* Git push rights to all DHIS2 apps

## Config

Change these two variables in `rcer.sh`:

```
dhis2ver="2.30"
rc="RC"
```

It will produce artifacts with the convention
`artifact-2.30-RC-SNAPSHOT`. It appends SNAPSHOT since it's not a real
release as far as Sonatype is concerned. They need to be signed and that
becomes a bit heavy for us.

## Nota bene

This method will become obsolete as soon as we stop bundling our
Javascript applications inside of a JAR-file, so we can use Maven for
dependency management when it comes to bundling the webapps in our DHIS2
WAR-file.

