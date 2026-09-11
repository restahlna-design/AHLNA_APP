import subprocess
import re
import sys

def get_distribution_cert_ids():
    try:
        output = subprocess.check_output(["app-store-connect", "certificates", "list"]).decode("utf-8", errors="replace")
        blocks = output.split("-- Signing Certificate --")
        dist_ids = []
        for b in blocks:
            if "Type: DISTRIBUTION" in b:
                m = re.search(r"Id:\s*([A-Z0-9]+)", b)
                if m:
                    dist_ids.append(m.group(1))
        return dist_ids
    except Exception as e:
        print("Error listing certificates:", e)
        return []

def delete_cert(cert_id):
    print(f"Deleting certificate {cert_id}...")
    try:
        subprocess.run(["app-store-connect", "certificates", "delete", cert_id], check=False)
    except Exception as e:
        print(f"Notice deleting {cert_id}: {e}")

def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "clean"
    
    # Clean known old certificates first
    for stale in ["CN623NV4PC", "DLTG6D2A58", "L4TY8GS75D"]:
        delete_cert(stale)

    dist_ids = get_distribution_cert_ids()
    print("Found active distribution certificate IDs:", dist_ids)
    
    if mode == "emergency":
        if dist_ids:
            delete_cert(dist_ids[0])
    else:
        if len(dist_ids) >= 2:
            for cid in dist_ids[:-1]:
                delete_cert(cid)

if __name__ == "__main__":
    main()
