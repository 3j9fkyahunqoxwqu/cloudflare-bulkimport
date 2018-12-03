# cloudflare-bulkimport

This BASH script uses the Cloudflare API to import multiple DNS zones files into Cloudflare. It takes care of creating new clean zones in Cloudflare, remove existing NS records in the source zone file, and import of the DNS records into the newly created zones. It is also possible to create the same apex CNAME across all imported domains.

# Using

To import zones, do the following:

* Place BIND formatted zone files in `zones/` and name the files according to this template `domain.tld.txt`; e.g. `lego.com.txt`.
* Make sure the `$ACCOUNT_ID` variable is set to the organisation you want the zone(s) imported to.
* Make your API key and mail available in environment via the `$CF_API_KEY` and `$CF_API_EMAIL` variables.
* If you'd also like to set an apex CNAME record while importing, fill out the `APEX_CNAME` variable.
* Run `./import.sh`

# Prerequisistes

The script needs `curl`, `sed` and `jq`.

# Assumptions and error handling

The script does minimal error handling. It assumes zones does not already exist in Cloudflare. If they do, it is unable to get their IDs and upload will fail.