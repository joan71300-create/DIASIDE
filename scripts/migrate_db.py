import os
import sys
from alembic.config import Config
from alembic import command

# Add project root to path
sys.path.append(os.getcwd())

def run_migrations():
    print("Running Alembic Migrations from Python...")
    alembic_cfg = Config("alembic.ini")
    
    # Generate Revision
    try:
        command.revision(alembic_cfg, message="Add_hba1c_offset", autogenerate=True)
        print("Revision generated.")
    except Exception as e:
        print(f"Revision error (maybe empty): {e}")

    # Upgrade Head
    try:
        command.upgrade(alembic_cfg, "head")
        print("Upgrade to head complete.")
    except Exception as e:
        print(f"Upgrade error: {e}")

if __name__ == "__main__":
    run_migrations()
