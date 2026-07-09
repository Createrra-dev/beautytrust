"""Drop unused yclients_form_id column

Revision ID: 0016_drop_yclients_form_id
Revises: 0015_yclients
Create Date: 2026-07-09
"""

from alembic import op
import sqlalchemy as sa

revision = "0016_drop_yclients_form_id"
down_revision = "0015_yclients"
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.drop_column("masters", "yclients_form_id")


def downgrade() -> None:
	op.add_column("masters", sa.Column("yclients_form_id", sa.String(20), nullable=True))
