#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Home Assistant Add-on: Promtail
# This file makes the config file from inputs
# ==============================================================================
config_file=/etc/promtail/config.yaml
def_scrape_configs=/etc/promtail/default-scrape-config.yaml
scrape_configs="${def_scrape_configs}"

bashio::log.info 'Setting base config for promtail...'
cp /etc/promtail/base_config.yaml $config_file

# Set up client section
if bashio::config.exists 'client.username'; then
    bashio::log.info 'Adding basic auth to client config...'
    bashio::config.require 'client.password' "'client.username' is specified"
    {
        echo "    basic_auth:"
        echo "      username: $(bashio::config 'client.username')"
        echo "      password: $(bashio::config 'client.password')"
    } >> "${config_file}"
fi

if ! bashio::config.is_empty 'client.cafile'; then
    bashio::log.info "Adding TLS to client config..."
    cafile=$(bashio::config 'cafile')

    # Absolute path support deprecated 4/21 for release 1.5.0.
    # Wait until at least 5/21 to remove
    if [[ $cafile =~ ^\/ ]]; then
        bashio::log.warning "Providing an absolute path for 'client.cafile' is deprecated."
        bashio::log.warning "Support for absolute paths will be removed in a future release."
        bashio::log.warning "Please put your CA file in /ssl and provide a relative path."
    else
        cafile="/ssl/${cafile}"
    fi

    if ! bashio::fs.file_exists "${cafile}"; then
        bashio::log.fatal
        bashio::log.fatal "The file specified for 'cafile' does not exist!"
        bashio::log.fatal "Ensure the CA certificate file exists and full path is provided"
        bashio::log.fatal
        bashio::exit.nok
    fi
    {
        echo "    tls_config:"
        echo "      ca_file: ${cafile}"
    } >> "${config_file}"

    if bashio::config.exists 'client.servername'; then
        echo "      server_name: $(bashio::config 'client.servername')" >> "${config_file}"
    fi

    if bashio::config.exists 'client.certfile'; then
        bashio::log.info "Adding mTLS to client config..."
        bashio::config.require 'client.keyfile' "'client.certfile' is specified"
        if ! bashio::fs.file_exists "$(bashio::config 'client.certfile')"; then
            bashio::log.fatal
            bashio::log.fatal "The file specified for 'certfile' does not exist!"
            bashio::log.fatal "Ensure the certificate file exists and full path is provided"
            bashio::log.fatal
            bashio::exit.nok
        fi
        if ! bashio::fs.file_exists "$(bashio::config 'client.keyfile')"; then
            bashio::log.fatal
            bashio::log.fatal "The file specified for 'keyfile' does not exist!"
            bashio::log.fatal "Ensure the key file exists and full path is provided"
            bashio::log.fatal
            bashio::exit.nok
        fi
        {
            echo "      cert_file: $(bashio::config 'client.certfile')"
            echo "      key_file: $(bashio::config 'client.keyfile')"
        } >> "${config_file}"
    fi
fi

# Add in scrape configs
{
    echo
    echo "scrape_configs:"
} >> "${config_file}"
if bashio::config.true 'skip_default_scrape_config'; then
    bashio::log.info 'Skipping default journald scrape config...'
    if bashio::config.exists 'additional_pipeline_stages'; then
        bashio::log.warning
        bashio::log.warning "'additional_pipeline_stages' ignored since 'skip_default_scrape_config' is true!"
        bashio::log.warning 'See documentation for more information.'
        bashio::log.warning
    fi
    bashio::config.require 'additional_scrape_configs' "'skip_default_scrape_config' is true"

elif bashio::config.exists 'additional_pipeline_stages'; then
    bashio::log.info "Adding additional pipeline stages to default journal scrape config..."
    add_stages="$(bashio::config 'additional_pipeline_stages')"
    scrape_configs=/etc/promtail/journal-scrape-configs.yaml
    if ! bashio::fs.file_exists "${add_stages}"; then
        bashio::log.fatal
        bashio::log.fatal "The file specified for 'additional_pipeline_stages' does not exist!"
        bashio::log.fatal "Ensure the file exists at the path specified"
        bashio::log.fatal
        bashio::exit.nok
    fi

    yq -NP eval-all \
        'select(fi == 0) + [{"add_pipeline_stages": select(fi == 1)}]' \
        $def_scrape_configs "${add_stages}" \
    | yq -NP e \
        '[(.[0] * .[1]) | {"job_name": .job_name, "journal": .journal, "relabel_configs": .relabel_configs, "pipeline_stages": .pipeline_stages + .add_pipeline_stages}]' \
        - > "${scrape_configs}"
fi

if bashio::config.exists 'additional_scrape_configs'; then
    bashio::log.info "Adding custom scrape configs..."
    add_scrape_configs="$(bashio::config 'additional_scrape_configs')"
    if ! bashio::fs.file_exists "${add_scrape_configs}"; then
        bashio::log.fatal
        bashio::log.fatal "The file specified for 'additional_scrape_configs' does not exist!"
        bashio::log.fatal "Ensure the file exists at the path specified"
        bashio::log.fatal
        bashio::exit.nok
    fi

    if bashio::config.true 'skip_default_scrape_config'; then
        yq -NP e '[] + .' "${add_scrape_configs}" >> "${config_file}"
    else
        yq -NP eval-all 'select(fi == 0) + select(fi == 1)' \
            "${scrape_configs}" "${add_scrape_configs}" >> "${config_file}"
    fi
else
    yq -NP e '[] + .' "${scrape_configs}" >> "${config_file}"
fi
