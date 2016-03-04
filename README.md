# Think Mechanic Website

GitHub pages builds the default environment in `_config.yml`, so we have to do
some tricks in development.

Mainly, this:

```bash
$ jekyll serve --config _config.yml,_config_dev.yml
