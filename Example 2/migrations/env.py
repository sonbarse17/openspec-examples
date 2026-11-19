from alembic import context

from app.db import get_engine

with get_engine().connect() as conn:
    context.configure(connection=conn, target_metadata=None)
    with context.begin_transaction():
        context.run_migrations()
