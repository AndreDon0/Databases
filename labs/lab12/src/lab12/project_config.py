from pathlib import Path
from urllib.parse import quote_plus

import yaml

from lab12.paths import PROJECT_ROOT

_CONFIG_PATH = PROJECT_ROOT / "config.yaml"


class ProjectConfig:
    """Read and load config.yaml"""

    def __init__(self) -> None:
        with _CONFIG_PATH.open() as f:
            config = yaml.safe_load(f)
            self.dbname = str(config["dbname"])
            self.user = str(config["user"])
            self.password = str(config["password"])
            self.host = str(config["host"])
            self.port = int(config.get("port", 5432))
            self.dbtableprefix = str(config["dbtableprefix"])

    @property
    def sqlalchemy_url(self) -> str:
        user = quote_plus(self.user)
        password = quote_plus(self.password)
        return (
            f"postgresql+psycopg2://{user}:{password}@{self.host}:{self.port}/{self.dbname}"
        )


if __name__ == "__main__":
    x = ProjectConfig()
    print(x.sqlalchemy_url)
