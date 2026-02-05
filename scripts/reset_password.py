import sys
import os

# Add the project root to the python path
sys.path.append(os.getcwd())

from app.models.database import SessionLocal, engine
from app.models import models
from app.core import security

def reset_password():
    db = SessionLocal()
    email = "patient@diaside.com"
    new_password = "password123"
    
    try:
        user = db.query(models.User).filter(models.User.email == email).first()
        if not user:
            print(f"❌ User {email} not found!")
            return

        print(f"Found user: {user.email}")
        print(f"Old hash: {user.hashed_password}")
        
        # Force update password
        hashed = security.get_password_hash(new_password)
        user.hashed_password = hashed
        db.commit()
        db.refresh(user)
        
        print(f"Password reset for {email} to '{new_password}'")
        print(f"New hash: {user.hashed_password}")
        
        # Verify immediately
        if security.verify_password(new_password, user.hashed_password):
            print("Verification successful: Password matches hash.")
        else:
            print("Verification failed!")

    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    reset_password()
