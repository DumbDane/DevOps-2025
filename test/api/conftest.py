from pathlib import Path
from contextlib import closing
import base64

import sqlite3
import pytest

BASE_URL = 'http://127.0.0.1:5000'
DATABASE = f"{Path('.').cwd()}/artifacts/test.db"
SCHEMA = f"{Path('.').cwd()}/artifacts/schema.sql"
USERNAME = 'simulator'
PWD = 'super_safe!'
CREDENTIALS = ':'.join([USERNAME, PWD]).encode('ascii')
ENCODED_CREDENTIALS = base64.b64encode(CREDENTIALS).decode()
HEADERS = {'Connection': 'close',
           'Content-Type': 'application/json',
           'Authorization': f'Basic {ENCODED_CREDENTIALS}'}


@pytest.fixture(scope="session", autouse=True)
def setup():
    def init_db():
        """Creates the database tables."""
        with closing(sqlite3.connect(DATABASE)) as db:
            with open(SCHEMA) as fp:
                db.cursor().executescript(fp.read())
            db.commit()

# Empty the database and initialize the schema again
    Path(DATABASE).unlink()
    init_db()
