"""
Konfiguracija aplikacije
Ucitava postavke iz .env datoteke
"""

from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """
    Postavke aplikacije - SVE VRIJEDNOSTI SE UCITAVAJU IZ .env DATOTEKE
    """
    
    # Database - OBAVEZNO postaviti u .env
    database_host: str
    database_port: int
    database_name: str
    database_user: str
    database_password: str
    
    # JWT - OBAVEZNO postaviti u .env
    # Generiraj secret_key: python -c "import secrets; print(secrets.token_hex(32))"
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    @property
    def database_url(self) -> str:
        """Generira PostgreSQL connection string"""
        return f"postgresql://{self.database_user}:{self.database_password}@{self.database_host}:{self.database_port}/{self.database_name}"
    
    class Config:
        env_file = ".env"
        extra = "allow"


@lru_cache()
def get_settings() -> Settings:
    """Singleton za postavke - cached"""
    return Settings()
