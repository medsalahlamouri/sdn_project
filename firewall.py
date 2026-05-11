import requests
import json

URL = "http://localhost:8080/stats/flowentry/add"

rules = [
    {
        "dpid": 1,
        "priority": 50000,
        "match": {
            "eth_type": 2048,
            "ipv4_src": "10.0.0.1",
            "ipv4_dst": "10.0.0.2",
            "ip_proto": 1
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
            "ip_proto": 1
        },
        "actions": []
    }
]

for rule in rules:

    print(f"[INFO] Installing rule on DPID {rule['dpid']}")

    response = requests.post(
        URL,
        data=json.dumps(rule),
        headers={"Content-Type": "application/json"}
    )

    print("[INFO] Status:", response.status_code)
    print(response.text)