# Home Assistant Add-on: Promtail

⚠ **Pre-Alpha Stage** - If you stumbled across this, it's in a very early stage.
Expect issues and things may change at any time.

⛔ **Known Issue** - This add-on is waiting on upcoming supervisor functionality
to function, specifically [this PR](https://github.com/home-assistant/supervisor/pull/2722).
Once that makes its way into the supervisor release I will update the add-on
to use the new `journald` config. Until then this add-on cannot scrape logs from
the system journal as promised. If you choose to use it before that you should set
`skip_default_scrape_config` to `true` and provide a file for `additional_scrape_configs`
as it will only be able to see log files created by add-ons.

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fmdegat01%2Fhassio-addons)
[![Open your Home Assistant instance and show the dashboard of a Supervisor add-on.](https://my.home-assistant.io/badges/supervisor_addon.svg)](https://my.home-assistant.io/redirect/supervisor_addon/?addon=39bd2704_promtail)

[Promtail](https://grafana.com/docs/loki/latest/clients/promtail/) is an agent
which ships the contents of local logs to a private [Loki](https://grafana.com/oss/loki)
instance or [Grafana Cloud](https://grafana.com/products/cloud/). It is usually
deployed to every machine that has applications needed to be monitored.

By default this addon version of Promtail will tail logs from the systemd
journal. This will include all logs from all addons, supervisor, home assistant,
docker, and the host system itself. In addition you can set it up to look for
local log files in `/share` or `/ssl` if you have a particular add-on that logs
to a file instead of to `stdout`.

To use simply use the links at the top to first add the repository then install
the add-on.

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

[![Open your Home Assistant instance and show the dashboard of a Supervisor add-on.](https://my.home-assistant.io/badges/supervisor_addon.svg)](https://my.home-assistant.io/redirect/supervisor_addon/?addon=39bd2704_loki)

Alternatively you can deploy Loki somewhere else. Take a look at the
[Loki documentation](https://grafana.com/docs/loki/latest/overview/) for info on
setting up a Loki deployment and connecting Promtail to it.

### Grafana

Once you have Loki and Promtail set up you will probably want to connect to it
from [Grafana](https://grafana.com/oss/grafana/). The easiest way to do that is
to use the [Grafana community add-on](https://github.com/hassio-addons/addon-grafana).
From there you can find Loki in the list of data sources and configure the
connection (see [Loki in Grafana](https://grafana.com/docs/loki/latest/getting-started/grafana/)).
If you did choose to use the Loki add-on you can find additional instructions in
[the add-on's documentation](https://github.com/mdegat01/hassio-addons/tree/main/loki#grafana).

[![Open your Home Assistant instance and show the dashboard of a Supervisor add-on.](https://my.home-assistant.io/badges/supervisor_addon.svg)](https://my.home-assistant.io/redirect/supervisor_addon/?addon=a0d7b954_grafana)

### Grafana Cloud

If you prefer, you can also use Grafana's cloud service,
[see here](https://grafana.com/products/cloud/) on how to get started. This
service takes the place of both Loki and Grafana in the PLG stack, you just
point Promtail at it and you're done. To do this, first
[create an account](https://grafana.com/signup/cloud/connect-account) then
[review this guide](https://grafana.com/docs/grafana-cloud/quickstart/logs_promtail_linuxnode/)
to see how to connect Promtail to your account. Essentially its just a different
URL since the credential information goes in the URL.
