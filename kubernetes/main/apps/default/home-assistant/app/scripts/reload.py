#!/usr/bin/env python

import time
import os
import requests
import json
import sys
import re

SLEEP_TIME_SIDECAR = 5 if os.getenv("SLEEP_TIME_SIDECAR") is None else int(re.sub('[A-z]', "", os.getenv("SLEEP_TIME_SIDECAR")))

def reload_configuration(hass_url, hass_token):
    time.sleep(SLEEP_TIME_SIDECAR)
    url = f"{hass_url}/api/services/homeassistant/reload_core_config"
    headers = {
        "Authorization": f"Bearer {hass_token}",
        "Content-Type": "application/json",
    }
    try:
        response = requests.post(url, headers=headers)
    except requests.exceptions.RequestException as e:
        print(f"Error reloading configuration: {e}")
        sys.exit(1)
    if response.status_code not in (200, 202):
        print(f"Error reloading configuration: {response.text}")
        sys.exit(1)
    print("Configuration reloaded successfully.")

def get_token():
    token = os.getenv("HASS_TOKEN", None)
    if not token:
        print("Error: missing environment variables HASS_TOKEN")
        sys.exit(1)
    return token

def main():
    hass_url = os.getenv("HASS_URL", "http://localhost:8123")
    token = get_token()
    reload_configuration(hass_url, token)

if __name__ == "__main__":
    main()
