import requests
import json
import sys

URL = "http://localhost:8080/stats/flowentry/add"

rules = [
    {
        "dpid": 1,
        "priority": 50000,
        "match": {
            "eth_type": 2048,
            "ipv4_src": "10.0.0.1",
            "ipv4_dst": "10.0.0.2",
            "ip_proto": 1,
            "icmpv4_type": 8,
            "icmpv4_code": 0
        },
        "actions": []
    },
    {
        "dpid": 2,
        "priority": 50000,
        "match": {
            "eth_type": 2048,
            "ipv4_src": "10.0.0.1",
            "ipv4_dst": "10.0.0.2",
            "ip_proto": 1,
            "icmpv4_type": 8,
            "icmpv4_code": 0
        },
        "actions": []
    }
]

for rule in rules:
    print(f"[INFO] Installing rule on DPID {rule['dpid']}")
    try:
        response = requests.post(
            URL,
            data=json.dumps(rule),
            headers={"Content-Type": "application/json"},
            timeout=5
        )
        print("[INFO] Status:", response.status_code)
        if response.status_code not in [200, 201]:
            print("[ERROR] Unexpected status code")
            print(response.text)
            sys.exit(1)
    except requests.exceptions.ConnectionError:
        print(f"[ERROR] Cannot connect to Ryu on {URL}")
        sys.exit(1)
    except Exception as e:
        print(f"[ERROR] {str(e)}")
        sys.exit(1)