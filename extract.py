import sys
import json
import base64
from datetime import datetime


def extract(acme_path, extract_domain, out_prefix):
    with open(acme_path, "r") as f:
        acme = json.loads(f.read())
        for certificate in acme["Certificates"]:
            domain = certificate["Domain"]["Main"]
            cert = certificate["Certificate"]
            key = certificate["Key"]

            if extract_domain == domain:
                with open(f"{out_prefix}/cert.pem", "wb") as c:
                    c.write(base64.b64decode(cert))

                with open(f"{out_prefix}/key.pem", "wb") as k:
                    k.write(base64.b64decode(key))
                
                return True
            
        return False

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(f"Usage:\npython {sys.argv[0]} <acme-json-path> <domain-cert-to-extract> <output-prefix>")
        sys.exit(1)

    if not extract(*sys.argv[1:]):  # pylint: disable=no-value-for-parameter
        print(f"Domain {sys.argv[2]} not found in {sys.argv[1]}")

    print(f"[{datetime.now()}] Cert and Key for {sys.argv[2]} can be found found in {sys.argv[3]}.{{key,crt}}")