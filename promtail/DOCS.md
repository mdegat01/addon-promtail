# Home Assistant Add-on: Promtail

## Install

First add the repository to the add-on store (`https://github.com/mdegat01/hassio-addons`):

[![Open your Home Assistant instance and show the add add-on repository dialog
with a specific repository URL pre-filled.][add-repo-shield]][add-repo]

Then find Promtail in the store and click install:

[![Open your Home Assistant instance and show the dashboard of a Supervisor add-on.][add-addon-shield]][add-addon]

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
([see here for more info][grafana-cloud-docs-promtail]).

### Option: `client.username`

The username to use if you require basic auth to connect to your Loki deployment.

### Option: `client.password`

The password for the username you choose if you require basic auth to connect to
your Loki deployment. **Note**: This field is required if `client.username` is
provided.

### Option: `client.cafile`

The CA certificate used to sign Loki's certificate if Loki is using a self-signed
certificate for SSL.

**Note**: _The file MUST be stored in `/ssl/`, which is the default_

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

### Option: `additional_pipeline_stages`

The absolute path to a YAML file with a list of additional pipeline stages to
apply to the [default journal scrape config][addon-default-config]. The primary
use of this is to apply additional processing to logs from particular add-ons
you use if they are noisy or difficult to read.

This file must contain only a YAML list of pipeline stages. They will be added
to the end of the ones already listed. If you don't like the ones listed, use
`skip_default_scrape_config` and `additional_scrape_configs` to write your own
instead. Here's an example of the contents of this file:

```yaml
- match:
    selector: '{container_name="addon_cebe7a76_hassio_google_drive_backup"}'
    stages:
      - multiline:
          firstline: '^\x{001b}'
```

This particular example applies to the [google drive backup addon][addon-google-drive-backup].
It uses the same log format as Home Assistant and outputs the escape character
at the start of each log line for color-coding in terminals. Looking for that
in a multiline stage makes it so tracebacks are included in the same log entry
as the error that caused them for easier readability.

See the [promtail documenation][promtail-doc-stages] for more information on how
to configure pipeline stages.

### Option: `skip_default_scrape_config`

Promtail will scrape the `systemd journal` using a pre-defined config you can
find [here][addon-default-config]. If you only want it to look at specific log
files you specify or you don't like the default config and want to adjust it, set
this to `true`. Then the only scrape configs used will be the ones you specify
in the `additional_scrape_configs` file.

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

This particular example would cause Promtail to scrape up the logs MQTT that the
[Zigbee2MQTT add-on][addon-z2m] makes by default.

Promtail provides a lot of options for configuring scrape configs. See the
documentation on [scrape_configs][promtail-doc-scrape-configs] for more info on
the options available and how to configure them. The documentation also provides
[other examples][promtail-doc-examples] you can use.

I would also recommend reading the [Loki best practices][loki-doc-best-practices]
guide before making custom scrape configs. Pipelines are pretty powerful but
avoid making too many labels, it does more harm then good. Instead look into
what you can do with [LogQL][logql] can do at the other end.

### Port: `9080/tcp`

Promtail expose an [API][api] on this port. This is primarily used for healthchecks
by the supervisor watchdog which does not require exposing it on the host. Most
users should leave this option disabled unless you have an external application
doing healthchecks.

For advanced users creating custom scrape configs the other purpose of this API
is to expose metrics created by the [metrics][promtail-doc-metrics] pipeline
stage. Exposing this port would then allow you to read those metrics from another
system on your network.

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

## PLG Stack (Promtail, Loki and Grafana)

Promtail isn't a standalone application, it's job is to find logs, process them
and ship them to Loki. Most likely you want the full PLG stack:

- Promtail to process and ship logs
- Loki to aggregate and index them
- Grafana to visualize and monitor them

### Loki

The easiest way to get started is to also install the Loki add-on in this same
repository. By default this add-on is set up to collect all logs from the system
journal and ship them over to that add-on. If that's what you want there is no
additional configuration required for either.

[![Open your Home Assistant instance and show the dashboard of a Supervisor add-on.][add-addon-shield]][add-addon-loki]

Alternatively you can deploy Loki somewhere else. Take a look at the
[Loki documentation][loki-doc] for info on setting up a Loki deployment and
connecting Promtail to it.

### Grafana

Once you have Loki and Promtail set up you will probably want to connect to it
from [Grafana][grafana]. The easiest way to do that is to use the
[Grafana community add-on][addon-grafana]. From there you can find Loki in the
list of data sources and configure the connection (see [Loki in Grafana][loki-in-grafana]).
If you did choose to use the Loki add-on you can find additional instructions in
[the add-on's documentation][addon-loki-doc].

[![Open your Home Assistant instance and show the dashboard of a Supervisor add-on.][add-addon-shield]][add-addon-grafana]

### Grafana Cloud

If you prefer, you can also use Grafana's cloud service,
[see here](https://grafana.com/products/cloud/) on how to get started. This
service takes the place of both Loki and Grafana in the PLG stack, you just
point Promtail at it and you're done. To do this, first create an account then
[review this guide][grafana-cloud-docs-promtail] to see how to connect Promtail
to your account. Essentially its just a different URL since the credential information
goes in the URL.

## Changelog & Releases

This repository keeps a change log using [GitHub's releases][releases]
functionality.

Releases are based on [Semantic Versioning][semver], and use the format
of `MAJOR.MINOR.PATCH`. In a nutshell, the version will be incremented
based on the following:

- `MAJOR`: Incompatible or major changes.
- `MINOR`: Backwards-compatible new features and enhancements.
- `PATCH`: Backwards-compatible bugfixes and package updates.

## Support

Got questions?

You have several ways to get them answered:

- The Home Assistant [Community Forum][forum]. I am
  [CentralCommand][forum-centralcommand] there.
- The Home Assistant [Discord Chat Server][discord-ha]. Use the #add-ons channel,
  I am CentralCommand#0913 there.

You could also [open an issue here][issue] on GitHub.

## Authors & contributors

The original setup of this repository is by [Mike Degatano][mdegat01].

For a full list of all authors and contributors,
check [the contributor's page][contributors].

## License

MIT License

Copyright (c) 2021-2022 Mike Degatano

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

[add-addon-shield]: https://my.home-assistant.io/badges/supervisor_addon.svg
[add-addon]: https://my.home-assistant.io/redirect/supervisor_addon/?addon=39bd2704_promtail
[add-addon-grafana]: https://my.home-assistant.io/redirect/supervisor_addon/?addon=a0d7b954_grafana
[add-addon-loki]: https://my.home-assistant.io/redirect/supervisor_addon/?addon=39bd2704_loki
[add-repo-shield]: https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg
[add-repo]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fmdegat01%2Fhassio-addons
[addon-default-config]: https://github.com/mdegat01/addon-promtail/blob/main/promtail/rootfs/etc/promtail/default-scrape-config.yaml
[addon-grafana]: https://github.com/hassio-addons/addon-grafana
[addon-google-drive-backup]: https://github.com/sabeechen/hassio-google-drive-backup
[addon-loki-doc]: https://github.com/mdegat01/addon-loki/blob/main/loki/DOCS.md#grafana
[addon-z2m]: https://github.com/zigbee2mqtt/hassio-zigbee2mqtt
[api]: https://grafana.com/docs/loki/latest/clients/promtail/#api
[contributors]: https://github.com/mdegat01/addon-promtail/graphs/contributors
[discord-ha]: https://discord.gg/c5DvZ4e
[forum-centralcommand]: https://community.home-assistant.io/u/CentralCommand/?u=CentralCommand
[forum]: https://community.home-assistant.io/t/home-assistant-add-on-promtail/293732?u=CentralCommand
[grafana]: https://grafana.com/oss/grafana/
[grafana-cloud]: https://grafana.com/products/cloud/
[grafana-cloud-docs-promtail]: https://grafana.com/docs/grafana-cloud/quickstart/logs_promtail_linuxnode/
[issue]: https://github.com/mdegat01/addon-promtail/issues
[logql]: https://grafana.com/docs/loki/latest/logql/
[loki-doc]: https://grafana.com/docs/loki/latest/overview/
[loki-doc-best-practices]: https://grafana.com/docs/loki/latest/best-practices/
[loki-in-grafana]: https://grafana.com/docs/loki/latest/getting-started/grafana/
[mdegat01]: https://github.com/mdegat01
[promtail-doc-examples]: https://grafana.com/docs/loki/latest/clients/promtail/configuration/#example-static-config
[promtil-doc-metrics]: https://grafana.com/docs/loki/latest/clients/promtail/configuration/#metrics
[promtail-doc-scrape-configs]: https://grafana.com/docs/loki/latest/clients/promtail/configuration/#scrape_configs
[promtail-doc-stages]: https://grafana.com/docs/loki/latest/clients/promtail/stages/
[releases]: https://github.com/mdegat01/addon-promtail/releases
[semver]: http://semver.org/spec/v2.0.0
