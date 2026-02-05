import os
# Hackathon Fix: Suppression préventive de la clé système conflictuelle
if "GOOGLE_API_KEY" in os.environ:
    print("⚠️ [MAIN] Suppression de GOOGLE_API_KEY du système pour éviter les conflits.")
    del os.environ["GOOGLE_API_KEY"]

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from opik import track
from app.core.config import settings
from app.api import auth, endpoints
from app.models.database import engine, Base
from app.core.logger import request_id_context, logger
import uuid
import time

# Création des tables (Géré par Alembic maintenant)
# Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

@app.get("/health")
@track(name="api_health")
def health_check():
    """
    S1-T03: Health Check Endpoint.
    """
    return {"status": "ok", "version": settings.VERSION}

@app.middleware("http")
async def correlation_middleware(request: Request, call_next):
    """
    Middleware de corrélation qui gère le X-Request-ID.
    """
    request_id = request.headers.get("X-Request-ID")
    if not request_id:
        request_id = str(uuid.uuid4())
    
    # Injection dans le contexte
    token = request_id_context.set(request_id)
    
    start_time = time.time()
    logger.info(f"Début requête: {request.method} {request.url}")
    
    try:
        response = await call_next(request)
        # Injection dans les headers de réponse
        response.headers["X-Request-ID"] = request_id
        
        process_time = time.time() - start_time
        logger.info(f"Fin requête: status={response.status_code} duration={process_time:.4f}s")
        
        return response
    except Exception as e:
        logger.error(f"Erreur non gérée: {e}")
        raise
    finally:
        request_id_context.reset(token)

# Configuration CORS pour Flutter
origins = [
    "*"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inclusion des routes
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(endpoints.router, prefix="/api", tags=["Diabetes"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
