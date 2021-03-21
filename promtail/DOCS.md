# Home Assistant Add-on: Promtail

[Promtail](https://grafana.com/docs/loki/latest/clients/promtail/) is an agent
which ships the contents of local logs to a private [Loki](https://grafana.com/oss/loki)
instance or [Grafana Cloud](https://grafana.com/products/cloud/). It is usually
deployed to every machine that has applications needed to be monitored.

## Install

First add the repository to the add-on store (`https://github.com/mdegat01/hassio-addons`):

[![Open your Home Assistant instance and show the add add-on repository dialog
with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fmdegat01%2Fhassio-addons)

Then find the add-on in the store and click install:

[![Open your Home Assistant instance and show the dashboard of a Supervisor add-on.](https://my.home-assistant.io/badges/supervisor_addon.svg)](https://my.home-assistant.io/redirect/supervisor_addon/?addon=39bd2704_promtail)

## Default Setup

By default this addon version of Promtail will tail logs from the systemd
journal. This will include all logs from all addons, supervisor, home assistant,
docker, and the host system itself. It will then ship them to the Loki add-on in
this same repository if you have it installed. No additional configuration is
required if this is the setup you want.

If you adjusted the configuration of the Loki add-on, have a separate Loki
add-on or have other log files you want Promtail to monitor then see below for
the configuration options.

## Configuration

**Note**: _Remember to restart the add-on when the configuration is changed._

Example add-on configuration:

```yaml
client:
  url: http://39bd2704-loki:3100
  username: loki
  password: secret
  cafile: /ssl/ca.pem
additional_scrape_configs: /share/promtail/scrape_configs.yaml
log_level: info
```

**Note**: _This is just an example, don't copy and paste it! Create your own!_

### Option: `client.url` (required)

The URL of the Loki deployment Promtail should ship logs to.

If you use the Loki add-on, this will be `http://39bd2704-loki:3100` (unless you
enabled `ssl`, then change it to `https`). If you use Grafana Cloud then the URL
will look like this: `https://<User>:<Your Grafana.com API Key>@logs-prod-us-central1.grafana.net/api/prom/push`
([see here for more info](https://grafana.com/docs/grafana-cloud/quickstart/logs_promtail_linuxnode/)).

### Option: `client.username`

The username to use if you require basic auth to connect to your Loki deployment.

### Option: `client.password`

The password for the username you choose if you require basic auth to connect to
your Loki deployment. **Note**: This field is required if `client.username` is
provided.

### Option: `client.cafile`

The absolute path to the CA certificate used to sign Loki's certificate if Loki
is using a self-signed certificate for SSL.

### Option: `client.servername`

The servername listed on the certificate Loki is using if using SSL to connect
by a different URL then what's on Loki's certificate (usually if the certificate
lists a public URL and you're connecting locally).

### Option: `client.certfile`

The absolute path to a certificate for client-authentication if Loki is using
mTLS to authenticate clients.

### Option: `client.keyfile`

The absolute path to the key for the client-authentication certificate if Loki
is using mTLS to authenticate clients. **Note**: This field is required if
`client.certfile` is provided

### Option: `skip_default_scrape_config`

Promtail will scrape the `systemd journal` using a pre-defined config you can
find [here](https://github.com/mdegat01/hassio-addons/blob/main/promtail/rootfs/etc/promtail/default-scrape-config.yaml).
If you only want it to look at specific log files you specify or you don't
like the default config and want to adjust it, set this to `true`. Then the
only scrape configs used will be the ones you specify in the
`additional_scrape_configs` file.

### Option: `additional_scrape_configs`

The absolute path to a YAML file with a list of additional scrape configs for
Promtail to use. The primary use of this is to point Promtail at additional log
files created by add-ons which don't use `stdout` for all logging. You an also
change the system journal is scraped by using this in conjunction with
`skip_default_scrape_config`. **Note**: If `skip_default_scrape_config` is `true`
then this field becomes required (otherwise there would be no scrape configs)

The file must contain only a YAML list of scrape configs. Here's an example of
the contents of this file:

```yaml
- job_name: zigbee2mqtt_messages
  pipeline_stages:
  static_configs:
    - targets:
        - localhost
      labels:
        job: zigbee2mqtt_messages
        __path__: /share/zigbee2mqtt/log/**.txt
```

This particular example would cause Promtail to scrape up the log of published
MQTT messages that the [Zigbee2MQTT add-on](https://github.com/zigbee2mqtt/hassio-zigbee2mqtt)
creates in addition to the normal journal logs.

Promtail provides a lot of options for configuring scrape configs. See the
documentation on [scrape_configs](https://grafana.com/docs/loki/latest/clients/promtail/configuration/#scrape_configs)
for more info on the options available and how to configure them. The
documentation also provides [other examples](https://grafana.com/docs/loki/latest/clients/promtail/configuration/#example-static-config)
you can use.

### Port: `9080/tcp`

Promtail exposes an HTTP server on this port. There's not a lot of documentation
on what this is used for. From what is there I believe it is primarily used in
larger scale Kubernetes deployments for things like healthchecks or where you
potentially have multiple Promtail instances communicating. Most likely you
should just leave this option disabled but if you know what you're doing you
can expose this HTTP server on the host.

### Option: `log_level`

The `log_level` option controls the level of log output by the addon and can
be changed to be more or less verbose, which might be useful when you are
dealing with an unknown issue. Possible values are:

- `debug`: Shows detailed debug information.
- `info`: Normal (usually) interesting events.
- `warning`: Exceptional occurrences that are not errors.
- `error`: Runtime errors that do not require immediate action.

Please note that each level automatically includes log messages from a
more severe level, e.g., `debug` also shows `info` messages. By default,
the `log_level` is set to `info`, which is the recommended setting unless
you are troubleshooting.
