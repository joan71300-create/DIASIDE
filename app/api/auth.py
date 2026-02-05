from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from opik import track
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from app.core import security
from app.models import models, schemas
from app.models.database import get_db
from datetime import timedelta
import firebase_admin
from firebase_admin import auth as firebase_auth, credentials
import os

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# Initialisation de Firebase Admin (une seule fois)
# On cherche le fichier de config dans les variables d'env ou à la racine
cred_path = "serviceAccountKey.json"
if os.path.exists(cred_path) and not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

@router.post("/firebase-login", response_model=schemas.Token)
@track(name="api_firebase_login")
async def firebase_login(token_data: dict, db: Session = Depends(get_db)):
    """
    Ticket BE-014: Validation du Token Firebase et Sync Utilisateur.
    """
    id_token = token_data.get("id_token")
    if not id_token:
        raise HTTPException(status_code=400, detail="ID Token is required")

    try:
        # 1. Vérifier le token auprès de Google
        # clock_skew_seconds=60 permet d'éviter les erreurs "Token used too early" si l'horloge système n'est pas parfaitement synchro
        decoded_token = firebase_auth.verify_id_token(id_token, clock_skew_seconds=60)
        email = decoded_token.get("email")
        uid = decoded_token.get("uid")

        if not email:
            raise HTTPException(status_code=400, detail="Token does not contain email")

        # 2. Synchroniser avec notre base de données locale
        user = db.query(models.User).filter(models.User.email == email).first()
        
        if not user:
            # Créer l'utilisateur s'il n'existe pas encore
            # On laisse le password vide car l'auth est gérée par Firebase
            user = models.User(email=email, hashed_password="FIREBASE_AUTH")
            db.add(user)
            db.commit()
            db.refresh(user)
        
        # 3. Générer nos propres JWT pour la session interne (Optionnel si on veut rester homogène)
        access_token = security.create_access_token(data={"sub": user.email})
        refresh_token = security.create_refresh_token(data={"sub": user.email})
        
        return {
            "access_token": access_token, 
            "refresh_token": refresh_token, 
            "token_type": "bearer"
        }

    except Exception as e:
        print(f"❌ Firebase Auth Error: {e}")
        raise HTTPException(status_code=401, detail=f"Invalid Firebase Token: {str(e)}")

@router.post("/register", response_model=schemas.User)
@track(name="api_register")
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    try:
        db_user = db.query(models.User).filter(models.User.email == user.email).first()
        if db_user:
            raise HTTPException(status_code=400, detail="Email already registered")
        
        hashed_password = security.get_password_hash(user.password)
        print(f"Register: email={user.email}")
        db_user = models.User(email=user.email, hashed_password=hashed_password)
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user
    except Exception as e:
        print(f"❌ ERREUR CRITIQUE REGISTER: {e}")
        # On relance l'erreur pour que FastAPI renvoie une 500, mais on a le log
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")

@router.post("/login", response_model=schemas.Token)
@track(name="api_login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    print(f"Login attempt: username={form_data.username}")
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not user:
        print("User not found")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    # print(f"User found: {user.email}")
    verified = security.verify_password(form_data.password, user.hashed_password)
    # print(f"Password verified: {verified}")
    if not verified:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = security.create_access_token(data={"sub": user.email})
    refresh_token = security.create_refresh_token(data={"sub": user.email})
    return {
        "access_token": access_token, 
        "refresh_token": refresh_token, 
        "token_type": "bearer"
    }

@router.post("/refresh-token", response_model=schemas.Token)
@track(name="api_refresh_token")
def refresh_access_token(
    refresh_body: dict, # Expect {"refresh_token": "..."}
    db: Session = Depends(get_db)
):
    refresh_token = refresh_body.get("refresh_token")
    if not refresh_token:
         raise HTTPException(status_code=400, detail="Refresh token required")

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    payload = security.decode_access_token(refresh_token)
    email: str = payload.get("sub")
    token_type: str = payload.get("type")
    
    if email is None or token_type != "refresh":
        raise credentials_exception
        
    user = db.query(models.User).filter(models.User.email == email).first()
    if user is None:
        raise credentials_exception

    new_access_token = security.create_access_token(data={"sub": user.email})
    new_refresh_token = security.create_refresh_token(data={"sub": user.email})
    
    return {
        "access_token": new_access_token, 
        "refresh_token": new_refresh_token, 
        "token_type": "bearer"
    }

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = security.decode_access_token(token)
    email: str = payload.get("sub")
    token_type: str = payload.get("type")
    
    if email is None or token_type != "access":
        raise credentials_exception
        
    token_data = schemas.TokenData(email=email)
    
    user = db.query(models.User).filter(models.User.email == token_data.email).first()
    if user is None:
        raise credentials_exception
    return user
