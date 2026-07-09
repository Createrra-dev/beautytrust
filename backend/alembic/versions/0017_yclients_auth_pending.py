"""YClients 2FA pending auth fields

Revision ID: 0017_yclients_auth_pending
Revises: 0016_drop_yclients_form_id
Create Date: 2026-07-09
"""

from alembic import op
import sqlalchemy as sa

revision = "0017_yclients_auth_pending"
down_revision = "0016_drop_yclients_form_id"
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.add_column("masters", sa.Column("yclients_auth_uuid", sa.String(100), nullable=True))
	op.add_column("masters", sa.Column("yclients_auth_recipient", sa.String(120), nullable=True))


def downgrade() -> None:
	op.drop_column("masters", "yclients_auth_recipient")
	op.drop_column("masters", "yclients_auth_uuid")
