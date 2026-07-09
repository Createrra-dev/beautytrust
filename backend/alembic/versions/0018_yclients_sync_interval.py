"""YClients sync interval setting

Revision ID: 0018_yclients_sync_interval
Revises: 0017_yclients_auth_pending
Create Date: 2026-07-09
"""

from alembic import op
import sqlalchemy as sa

revision = "0018_yclients_sync_interval"
down_revision = "0017_yclients_auth_pending"
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.add_column(
		"masters",
		sa.Column("yclients_sync_interval_minutes", sa.Integer(), nullable=False, server_default="15"),
	)
	op.alter_column("masters", "yclients_sync_interval_minutes", server_default=None)


def downgrade() -> None:
	op.drop_column("masters", "yclients_sync_interval_minutes")
