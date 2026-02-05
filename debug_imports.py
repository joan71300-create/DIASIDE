
import sys
import traceback

print("--- DIAGNOSTIC START ---")
try:
    print("Attempting to import opik...")
    import opik
    print("OK: opik imported successfully.")
except Exception:
    print("FAIL: Failed to import opik.")
    traceback.print_exc()

try:
    print("\nAttempting to import litellm...")
    import litellm
    print("OK: litellm imported successfully.")
except Exception:
    print("FAIL: Failed to import litellm.")
    traceback.print_exc()

print("--- DIAGNOSTIC END ---")

