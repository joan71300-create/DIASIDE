import logging
import json
import sys
from contextvars import ContextVar
from typing import Optional

# ContextVar pour stocker le request_id (thread-safe et async-safe)
request_id_context: ContextVar[Optional[str]] = ContextVar("request_id", default=None)

class JsonFormatter(logging.Formatter):
    """
    Formateur de logs qui sort du JSON incluant le request_id.
    """
    def format(self, record):
        log_record = {
            "level": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
            "timestamp": self.formatTime(record, self.datefmt),
            "request_id": request_id_context.get()
        }
        
        if record.exc_info:
            log_record["exception"] = self.formatException(record.exc_info)
            
        return json.dumps(log_record)

def setup_logger():
    """
    Configure le logger racine pour utiliser le JsonFormatter.
    """
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    
    # Supprimer les anciens handlers pour éviter les doublons
    logger.handlers = [handler]
    
    # Réduire le bruit de certaines librairies
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)

    return logger

logger = setup_logger()
